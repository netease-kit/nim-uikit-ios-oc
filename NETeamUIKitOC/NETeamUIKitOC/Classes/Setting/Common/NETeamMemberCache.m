// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamMemberCache.h"
#import "TeamConstant.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/NEALog.h>
#import <UIKit/UIKit.h>

@interface NETeamMemberCache ()
@property (nonatomic, strong) NSHashTable<id<NETeamMemberCacheListener>> *listeners;
@property (nonatomic, strong) dispatch_queue_t listenerQueue;
@end

@implementation NETeamMemberCache

+ (NETeamMemberCache *)shared {
  static NETeamMemberCache *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[NETeamMemberCache alloc] initPrivate];
  });
  return shared;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _currentTeamId = @"";
    _teamRepo = [TeamRepo shared];
    _contactRepo = [ContactRepo shared];
    _client = [IMKitClient instance];
    _cacheDic = [NSMutableDictionary dictionary];
    _listeners = [NSHashTable weakObjectsHashTable];
    _listenerQueue = dispatch_queue_create("com.netease.team.member.cache.listener", DISPATCH_QUEUE_CONCURRENT);
    [_teamRepo addTeamListener:self];
    [_client addLoginListener:self];
    [_contactRepo addContactListener:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didTapHeader:)
                                                 name:NENotificationDidTapHeader
                                               object:nil];
  }
  return self;
}

- (instancetype)init {
  NSAssert(NO, @"Use +shared instead.");
  return nil;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
  [self.client removeLoginListener:self];
  [self.contactRepo removeContactListener:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addTeamCacheListener:(id<NETeamMemberCacheListener>)listener {
  if (!listener) {
    return;
  }
  dispatch_barrier_async(self.listenerQueue, ^{
    [self.listeners addObject:listener];
  });
}

- (void)removeTeamCacheListener:(id<NETeamMemberCacheListener>)listener {
  if (!listener) {
    return;
  }
  dispatch_barrier_async(self.listenerQueue, ^{
    [self.listeners removeObject:listener];
  });
}

- (void)appDidEnterBackground {
  [self clearCache];
}

- (void)appWillResignActive {
  [self clearCache];
}

- (void)didTapHeader:(NSNotification *)notification {
  if (![notification.object isKindOfClass:[NEUserWithFriend class]]) {
    return;
  }
  NEUserWithFriend *user = (NEUserWithFriend *)notification.object;
  NSString *accid = user.user.accountId ?: @"";
  if (accid.length <= 0) {
    return;
  }
  self.cacheDic[accid].nimUser = user;
  [self updateFinish];
}

- (void)setCacheMembers:(NSString *)teamId members:(NSArray<NETeamMemberInfoModel *> *)members {
  [self.cacheDic removeAllObjects];
  self.currentTeamId = teamId ?: @"";
  [self endTimer];
  for (NETeamMemberInfoModel *model in members) {
    NSString *accountId = model.teamMember.accountId ?: @"";
    if (accountId.length > 0) {
      self.cacheDic[accountId] = model;
    }
  }
}

- (void)setCacheMembers:(NSString *)teamId :(NSArray<NETeamMemberInfoModel *> *)members {
  [self setCacheMembers:teamId members:members];
}

- (NSArray<NETeamMemberInfoModel *> *)getTeamMemberCache:(NSString *)teamId {
  if (![self.currentTeamId isEqualToString:teamId]) {
    return nil;
  }
  NSMutableArray<NETeamMemberInfoModel *> *allCacheMembers = [self.cacheDic.allValues mutableCopy];
  [allCacheMembers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time2 > time1) return NSOrderedAscending;
    if (time2 < time1) return NSOrderedDescending;
    return NSOrderedSame;
  }];
  return allCacheMembers.count > 0 ? allCacheMembers.copy : nil;
}

- (BOOL)isCurrentMember:(NSString *)accountId {
  return self.cacheDic[accountId] != nil;
}

- (void)onFriendInfoChanged:(V2NIMFriend *)friendInfo {
  NSString *accountId = friendInfo.accountId ?: @"";
  NETeamMemberInfoModel *model = self.cacheDic[accountId];
  if (!model) {
    return;
  }
  model.nimUser = [[NEUserWithFriend alloc] initWithUser:nil friend:friendInfo];
  [self updateFinish];
}

- (void)onUserProfileChanged:(NSArray<V2NIMUser *> *)users {
  [NEALog infoLog:[self className]
             desc:[NSString stringWithFormat:@"%@ onUserProfileChanged count : %lu", NSStringFromSelector(_cmd), (unsigned long)users.count]];
  BOOL needUpdate = NO;
  for (V2NIMUser *user in users) {
    NSString *accountId = user.accountId ?: @"";
    NETeamMemberInfoModel *model = self.cacheDic[accountId];
    if (model) {
      model.nimUser = [[NEUserWithFriend alloc] initWithUser:user friend:nil];
      needUpdate = YES;
    }
  }
  if (needUpdate) {
    [self updateFinish];
  }
}

- (void)onFriendDeleted:(NSString *)accountId deletionType:(V2NIMFriendDeletionType)deletionType {
  (void)deletionType;
  NETeamMemberInfoModel *model = self.cacheDic[accountId];
  if (model) {
    model.nimUser.friend = nil;
  }
}

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    [self clearCache];
  }
}

- (void)onTeamJoined:(V2NIMTeam *)team {
  if ([team.teamId isEqualToString:self.currentTeamId]) {
    [self clearCache];
    [self updateFinish];
  }
}

- (void)onTeamMemberLeft:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onMemberDidRemove:teamMembers];
}

- (void)onTeamMemberKicked:(NSString *)operatorAccountId teamMembers:(NSArray<V2NIMTeamMember *> *)teamMembers {
  (void)operatorAccountId;
  [self onMemberDidRemove:teamMembers];
}

- (void)onTeamMemberJoined:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onMemberDidAdd:teamMembers];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onMemberDidChanged:teamMembers];
}

- (void)onTeamDismissed:(V2NIMTeam *)team {
  if ([team.teamId isEqualToString:self.currentTeamId]) {
    [self clearCache];
  }
}

- (void)onMemberDidChanged:(NSArray<V2NIMTeamMember *> *)members {
  for (V2NIMTeamMember *member in members) {
    if (![self.currentTeamId isEqualToString:member.teamId]) {
      continue;
    }
    NETeamMemberInfoModel *model = self.cacheDic[member.accountId ?: @""];
    if (model) {
      model.teamMember = member;
    }
  }
  [self updateFinish];
}

- (void)onMemberDidRemove:(NSArray<V2NIMTeamMember *> *)members {
  for (V2NIMTeamMember *member in members) {
    if (![self.currentTeamId isEqualToString:member.teamId]) {
      continue;
    }
    [self.cacheDic removeObjectForKey:member.accountId ?: @""];
    [self updateFinish];
  }
}

- (void)onMemberDidAdd:(NSArray<V2NIMTeamMember *> *)members {
  NSMutableArray<V2NIMTeamMember *> *allMembers = [NSMutableArray array];
  for (V2NIMTeamMember *member in members) {
    if (![self.currentTeamId isEqualToString:member.teamId]) {
      continue;
    }
    [NEALog infoLog:[self className]
               desc:[NSString stringWithFormat:@"team cache did add member %@", member.teamNick ?: @""]];
    NETeamMemberInfoModel *model = [[NETeamMemberInfoModel alloc] init];
    model.teamMember = member;
    self.cacheDic[member.accountId ?: @""] = model;
    [allMembers addObject:member];
  }

  if (allMembers.count <= 0) {
    return;
  }

  NSMutableArray<NSString *> *accids = [NSMutableArray array];
  for (V2NIMTeamMember *member in allMembers) {
    if (member.accountId.length > 0) {
      [accids addObject:member.accountId];
    }
  }

  __weak typeof(self) weakSelf = self;
  [self.contactRepo getUserWithFriend:accids completion:^(NSArray<NEUserWithFriend *> * _Nullable users, __unused NSError * _Nullable error) {
    for (NEUserWithFriend *user in users) {
      NSString *accountId = user.user.accountId ?: @"";
      if (accountId.length > 0) {
        weakSelf.cacheDic[accountId].nimUser = user;
      }
    }
    [weakSelf updateFinish];
  }];
}

- (void)clearCache {
  self.currentTeamId = @"";
  [self.cacheDic removeAllObjects];
  [self endTimer];
}

- (void)triggerClearCache {
  [NEALog infoLog:[self className] desc:@"triggerClearCache"];
  [self clearCache];
}

- (void)trigerTimer {
  self.timer = [NSTimer scheduledTimerWithTimeInterval:300.0
                                                target:self
                                              selector:@selector(triggerClearCache)
                                              userInfo:nil
                                               repeats:NO];
}

- (void)endTimer {
  [self.timer invalidate];
  self.timer = nil;
}

- (void)updateFinish {
  dispatch_sync(self.listenerQueue, ^{
    for (id<NETeamMemberCacheListener> delegate in self.listeners.allObjects) {
      if ([delegate respondsToSelector:@selector(memberCacheDidChange)]) {
        [delegate memberCacheDidChange];
      }
    }
  });
}

- (void)getAllTeamMemberInfos:(NSString *)teamId
                    queryType:(V2NIMTeamMemberRoleQueryType)queryType
                   completion:(void (^)(NSError * _Nullable, NETeamInfoModel * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamid:%@", NSStringFromSelector(_cmd), teamId]];
  NSMutableArray<V2NIMTeamMember *> *memberLists = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  [self getAllTeamMemberWithMaxLimit:teamId
                           nextToken:nil
                          memberList:memberLists
                           queryType:queryType
                          completion:^(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(error, nil);
      }
      return;
    }
    NETeamInfoModel *teamInfo = [[NETeamInfoModel alloc] init];
    [weakSelf splitMembers:members ?: @[]
                     model:teamInfo
             maxSizeByPage:150
                completion:completion];
  }];
}

- (void)getAllTeamMemberInfos:(NSString *)teamId
                             :(V2NIMTeamMemberRoleQueryType)queryType
                             :(void (^)(NSError * _Nullable, NETeamInfoModel * _Nullable))completion {
  [self getAllTeamMemberInfos:teamId queryType:queryType completion:completion];
}

- (void)getAllTeamMemberWithMaxLimit:(NSString *)teamId
                           nextToken:(NSString *)nextToken
                          memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                           queryType:(V2NIMTeamMemberRoleQueryType)queryType
                          completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[self className]
             desc:[NSString stringWithFormat:@"%@ teamId : %@", NSStringFromSelector(_cmd), teamId]];
  V2NIMTeamMemberQueryOption *option = [[V2NIMTeamMemberQueryOption alloc] init];
  option.direction = V2NIM_QUERY_DIRECTION_ASC;
  option.limit = 1000;
  option.onlyChatBanned = NO;
  option.roleQueryType = queryType;
  option.nextToken = nextToken ?: @"";

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamMemberList:teamId
                          teamType:V2NIM_TEAM_TYPE_NORMAL
                       queryOption:option
                        completion:^(V2NIMTeamMemberListResult * _Nullable result, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(nil, error);
      }
      return;
    }
    if (result.memberList.count > 0) {
      [memberList addObjectsFromArray:result.memberList];
    }
    if (result.finished) {
      if (completion) {
        completion(memberList.copy, nil);
      }
    } else {
      [weakSelf getAllTeamMemberWithMaxLimit:teamId
                                   nextToken:result.nextToken
                                  memberList:memberList
                                   queryType:queryType
                                  completion:completion];
    }
  }];
}

- (void)splitMembers:(NSArray<V2NIMTeamMember *> *)members
               model:(NETeamInfoModel *)model
       maxSizeByPage:(NSInteger)maxSizeByPage
          completion:(void (^)(NSError * _Nullable, NETeamInfoModel * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, members.count:%lu", NSStringFromSelector(_cmd), (unsigned long)members.count]];
  NSMutableArray<NSArray<V2NIMTeamMember *> *> *remain = [NSMutableArray array];
  NSInteger index = 0;
  while (index < members.count) {
    NSInteger size = MIN(maxSizeByPage, members.count - index);
    [remain addObject:[members subarrayWithRange:NSMakeRange(index, size)]];
    index += size;
  }
  [self fetchTeamMemberUserInfos:remain model:model completion:completion];
}

- (void)splitMembers:(NSArray<V2NIMTeamMember *> *)members
                    :(NETeamInfoModel *)model
                    :(NSInteger)maxSizeByPage
                    :(void (^)(NSError * _Nullable, NETeamInfoModel * _Nullable))completion {
  [self splitMembers:members model:model maxSizeByPage:maxSizeByPage completion:completion];
}

- (void)fetchTeamMemberUserInfos:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                           model:(NETeamInfoModel *)model
                      completion:(void (^)(NSError * _Nullable, NETeamInfoModel * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, remainUserIds.count:%lu", NSStringFromSelector(_cmd), (unsigned long)remainUserIds.count]];
  NSArray<V2NIMTeamMember *> *members = remainUserIds.firstObject;
  if (!members) {
    if (completion) {
      completion(nil, model);
    }
    return;
  }

  NSMutableArray<NSString *> *accids = [NSMutableArray array];
  for (V2NIMTeamMember *member in members) {
    if (member.accountId.length > 0) {
      [accids addObject:member.accountId];
    }
  }

  __weak typeof(self) weakSelf = self;
  [self.contactRepo getUserWithFriend:accids completion:^(NSArray<NEUserWithFriend *> * _Nullable infos, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(error, model);
      }
      return;
    }

    NSMutableArray<NETeamMemberInfoModel *> *mutableUsers = [model.users mutableCopy] ?: [NSMutableArray array];
    for (NSUInteger index = 0; index < members.count; index++) {
      NETeamMemberInfoModel *memberInfoModel = [[NETeamMemberInfoModel alloc] init];
      memberInfoModel.teamMember = members[index];
      if (infos.count > index) {
        memberInfoModel.nimUser = infos[index];
      }
      [mutableUsers addObject:memberInfoModel];
    }
    model.users = mutableUsers.copy;
    [remainUserIds removeObjectAtIndex:0];
    [weakSelf fetchTeamMemberUserInfos:remainUserIds model:model completion:completion];
  }];
}

- (void)onTeamSyncFinished {
  [NEALog infoLog:[self className]
             desc:[NSString stringWithFormat:@"%@ onTeamSyncFinished call back happen", NSStringFromSelector(_cmd)]];
  [self clearCache];
  [self updateFinish];
}

@end
