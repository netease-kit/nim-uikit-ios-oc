// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamUserManager.h"
#import "NEP2PChatUserCache.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

@interface NETeamUserManager () <NEContactListener, NETeamListener, NEIMKitClientListener>

@property (nonatomic, strong) NSHashTable<id<NETeamChatUserCacheListener>> *listeners;
@property (nonatomic, copy, nullable) NSString *tid;
@property (nonatomic, strong, nullable) V2NIMTeam *currentTeam;
@property (nonatomic, strong) NSMutableDictionary<NSString *, V2NIMTeamMember *> *teamMemberCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NEUserWithFriend *> *userInfoCache;
@property (nonatomic, assign) BOOL haveLoadAllMembers;

@end

@implementation NETeamUserManager

+ (NETeamUserManager *)shared {
  static NETeamUserManager *_shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shared = [[NETeamUserManager alloc] initPrivate];
  });
  return _shared;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _listeners = [NSHashTable weakObjectsHashTable];
    _teamMemberCache = [NSMutableDictionary dictionary];
    _userInfoCache = [NSMutableDictionary dictionary];
    _haveLoadAllMembers = NO;
    [[IMKitClient instance] addLoginListener:self];
    [[TeamRepo shared] addTeamListener:self];
    [[ContactRepo shared] addContactListener:self];
  }
  return self;
}

- (void)dealloc {
  [[IMKitClient instance] removeLoginListener:self];
  [[TeamRepo shared] removeTeamListener:self];
  [[ContactRepo shared] removeContactListener:self];
}

#pragma mark - Listener Management

- (void)addListener:(id<NETeamChatUserCacheListener>)listener {
  if (listener) {
    [self.listeners addObject:listener];
  }
}

- (void)removeListener:(id<NETeamChatUserCacheListener>)listener {
  if (listener) {
    [self.listeners removeObject:listener];
  }
}

- (void)notifyTeamInfoUpdate:(NSString *)teamId {
  NSArray<id<NETeamChatUserCacheListener>> *listenerSnapshot = self.listeners.allObjects;
  for (id<NETeamChatUserCacheListener> delegate in listenerSnapshot) {
    if ([delegate respondsToSelector:@selector(onTeamInfoUpdate:)]) {
      [delegate onTeamInfoUpdate:teamId];
    }
  }
}

- (void)notifyTeamMemberUpdate:(NSString *)accountId {
  NSArray<id<NETeamChatUserCacheListener>> *listenerSnapshot = self.listeners.allObjects;
  for (id<NETeamChatUserCacheListener> delegate in listenerSnapshot) {
    if ([delegate respondsToSelector:@selector(onTeamMemberUpdate:)]) {
      [delegate onTeamMemberUpdate:accountId];
    }
  }
}

#pragma mark - Public

- (void)loadData:(NSString *)teamId {
  [self removeAllTeamInfo];
  self.tid = teamId;

  // Get team info
  __weak typeof(self) weakSelf = self;
  [[TeamRepo shared] getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    [weakSelf updateTeamInfo:team];
  }];

  // Get own team member info
  [[TeamRepo shared] getTeamMember:teamId teamType:V2NIM_TEAM_TYPE_NORMAL accId:[[IMKitClient instance] account] completion:^(V2NIMTeamMember * _Nullable teamMember, NSError * _Nullable error) {
    [weakSelf updateTeamMemberInfo:teamMember notify:YES];
  }];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [weakSelf getAllTeamMembers:teamId queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL completion:^(NSArray<NEUserWithFriend *> *users) {
      // loaded
    }];
  });
}

- (void)refreshTeamInfoAndSelfMember:(NSString *)teamId completion:(void (^)(void))completion {
  if (teamId.length <= 0) {
    if (completion) completion();
    return;
  }

  dispatch_group_t group = dispatch_group_create();
  __weak typeof(self) weakSelf = self;

  dispatch_group_enter(group);
  [[TeamRepo shared] getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (!error && team) {
      [weakSelf updateTeamInfo:team];
    }
    dispatch_group_leave(group);
  }];

  NSString *accountId = [[IMKitClient instance] account];
  if (accountId.length > 0) {
    dispatch_group_enter(group);
    [[TeamRepo shared] getTeamMember:teamId teamType:V2NIM_TEAM_TYPE_NORMAL accId:accountId completion:^(V2NIMTeamMember * _Nullable teamMember, NSError * _Nullable error) {
      if (!error && teamMember) {
        [weakSelf updateTeamMemberInfo:teamMember notify:YES];
      }
      dispatch_group_leave(group);
    }];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    if (completion) completion();
  });
}

- (void)updateTeamInfo:(V2NIMTeam *)team {
  NSString *teamId = team.teamId;
  if (!teamId || ![teamId isEqualToString:self.tid]) return;
  self.currentTeam = team;
  [self notifyTeamInfoUpdate:teamId];
}

- (void)updateTeamMemberInfo:(V2NIMTeamMember *)teamMember {
  [self updateTeamMemberInfo:teamMember notify:YES];
}

- (void)updateTeamMemberInfo:(V2NIMTeamMember *)teamMember notify:(BOOL)notify {
  if (!teamMember || ![teamMember.teamId isEqualToString:self.tid]) return;
  NSString *accid = teamMember.accountId;
  self.teamMemberCache[accid] = teamMember;
  if (notify) {
    [self notifyTeamMemberUpdate:accid];
  }
}

- (void)updateUserInfoWithUser:(V2NIMUser *)user {
  NSString *accid = user.accountId;
  if (!accid) return;
  NEUserWithFriend *existing = self.userInfoCache[accid];
  if (existing) {
    existing.user = user;
  }
  [self notifyTeamMemberUpdate:accid];
}

- (void)updateUserInfoWithFriend:(NEUserWithFriend *)userWithFriend {
  NSString *accid = userWithFriend.user.accountId;
  if (!accid) return;
  self.userInfoCache[accid] = userWithFriend;
  [self notifyTeamMemberUpdate:accid];
}

- (V2NIMTeam *)getTeamInfo {
  return self.currentTeam;
}

- (V2NIMTeamMember *)getTeamMemberInfo:(NSString *)accountId {
  return self.teamMemberCache[accountId];
}

- (BOOL)isCurrentMember:(NSString *)accountId {
  return self.teamMemberCache[accountId] != nil;
}

- (BOOL)isOwner:(NSString *)accountId {
  return [self.currentTeam.ownerAccountId isEqualToString:accountId];
}

- (NSArray<V2NIMTeamMember *> *)getAllTeamMembers {
  if (self.haveLoadAllMembers) {
    return self.teamMemberCache.allValues;
  }
  return nil;
}

- (NSArray<NETeamMemberInfoModel *> *)getAllTeamMemberModels {
  if (!self.haveLoadAllMembers) return nil;

  NSDictionary<NSString *, NEUserWithFriend *> *friendCache = [[NEFriendUserCache shared] getFriendList] ?: @{};
  NSMutableArray<NETeamMemberInfoModel *> *models = [NSMutableArray array];

  NSDictionary<NSString *, V2NIMTeamMember *> *memberCacheSnapshot = [self.teamMemberCache copy];
  NSDictionary<NSString *, NEUserWithFriend *> *userInfoCacheSnapshot = [self.userInfoCache copy];
  for (NSString *accid in memberCacheSnapshot) {
    V2NIMTeamMember *member = memberCacheSnapshot[accid];
    NETeamMemberInfoModel *model = [[NETeamMemberInfoModel alloc] init];
    model.teamMember = member;
    NEUserWithFriend *userInfo = friendCache[accid];
    if (!userInfo) {
      userInfo = userInfoCacheSnapshot[accid];
    }
    if (!userInfo) {
      userInfo = [[NEAIUserManager shared] getNEUserById:accid];
    }
    model.nimUser = userInfo;
    [models addObject:model];
  }

  return models.count > 0 ? [models copy] : nil;
}

- (NEUserWithFriend *)getUserInfo:(NSString *)accountId {
  return self.userInfoCache[accountId];
}

- (void)removeTeamMemberInfo:(NSString *)accountId {
  if (self.teamMemberCache[accountId]) {
    [self.teamMemberCache removeObjectForKey:accountId];
  }
}

- (void)removeAllTeamInfo {
  self.tid = nil;
  self.currentTeam = nil;
  [self.userInfoCache removeAllObjects];
  [self.teamMemberCache removeAllObjects];
  self.haveLoadAllMembers = NO;
}

- (NSString *)getShowName:(NSString *)accountId {
  return [self getShowName:accountId showAlias:YES];
}

- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias {
  // AI user returns directly
  NEUserWithFriend *aiUser = [[NEAIUserManager shared] getNEUserById:accountId];
  if (aiUser) {
    return [aiUser showName:YES] ?: accountId;
  }

  // Non-friend cache
  NSString *fullName = [self.userInfoCache[accountId] showName:YES] ?: [[NEP2PChatUserCache shared] getShowName:accountId];

  // Friend cache
  if ([[NEFriendUserCache shared] isFriend:accountId]) {
    fullName = [[NEFriendUserCache shared] getShowName:accountId showAlias:showAlias];
  }

  // Team member cache
  V2NIMTeamMember *teamMember = self.teamMemberCache[accountId];
  if (teamMember && [teamMember.accountId isEqualToString:accountId]) {
    NSString *teamNick = teamMember.teamNick;
    if (teamNick.length > 0) {
      fullName = teamNick;
    }
    if (showAlias) {
      NEUserWithFriend *friendInfo = [[NEFriendUserCache shared] getFriendInfo:accountId];
      NSString *alias = friendInfo.friend.alias;
      if (alias.length > 0) {
        fullName = alias;
      }
    }
    return fullName;
  }
  return fullName;
}

#pragma mark - Get Team Members

- (void)getTeamMembers:(NSArray<NSString *> *)accountIds
                notify:(BOOL)notify
            completion:(void (^)(void))completion {
  NSMutableSet<NSString *> *loadUserIds = [NSMutableSet set];
  NSMutableSet<NSString *> *loadMemberIds = [NSMutableSet set];
  dispatch_group_t group = dispatch_group_create();

  for (NSString *userId in accountIds) {
    if (![[NEAIUserManager shared] isAIUser:userId] &&
        ![[NEFriendUserCache shared] isFriend:userId] &&
        !self.userInfoCache[userId]) {
      [loadUserIds addObject:userId];
    }
    if (!self.teamMemberCache[userId] && ![[NEAIUserManager shared] isAIUser:userId]) {
      [loadMemberIds addObject:userId];
    }
  }

  // Fetch user info (strangers)
  if (loadUserIds.count > 0) {
    NSArray *allIds = loadUserIds.allObjects;
    NSArray<NSArray<NSString *> *> *chunks = [self chunkArray:allIds chunkSize:150];
    __weak typeof(self) weakSelf = self;
    for (NSArray<NSString *> *chunk in chunks) {
      dispatch_group_enter(group);
      [[ContactRepo shared] getUserListFromCloud:chunk completion:^(NSArray<NEUserWithFriend *> * _Nullable users, NSError * _Nullable error) {
        for (NEUserWithFriend *u in users) {
          [weakSelf updateUserInfoWithFriend:u];
        }
        dispatch_group_leave(group);
      }];
    }
  }

  if (!self.tid) {
    completion();
    return;
  }

  // Fetch team member info
  if (loadMemberIds.count > 0) {
    dispatch_group_enter(group);
    __weak typeof(self) weakSelf = self;
    [[TeamRepo shared] getTeamMemberListByIds:self.tid teamType:V2NIM_TEAM_TYPE_NORMAL accIds:loadMemberIds.allObjects completion:^(NSArray<V2NIMTeamMember *> * _Nullable teamMembers, NSError * _Nullable error) {
      for (V2NIMTeamMember *tm in teamMembers) {
        if (tm.inTeam) {
          [weakSelf updateTeamMemberInfo:tm notify:notify];
        }
      }
      dispatch_group_leave(group);
    }];
  }

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    completion();
  });
}

- (void)getAllTeamMembers:(NSString *)teamId
               queryType:(V2NIMTeamMemberRoleQueryType)queryType
              completion:(void (^)(NSArray<NEUserWithFriend *> *))completion {
  NSMutableArray<V2NIMTeamMember *> *memberLists = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  [self getAllTeamMemberWithMaxLimit:teamId nextToken:nil memberList:memberLists queryType:queryType completion:^(NSArray<V2NIMTeamMember *> *members, NSError *error) {
    if (error) {
      NSLog(@"getAllTeamMembers error: %@", error.localizedDescription);
    } else if (members) {
      NSMutableArray<NSString *> *notFriendMembers = [NSMutableArray array];
      for (V2NIMTeamMember *member in members) {
        weakSelf.teamMemberCache[member.accountId] = member;
        if (![[NEFriendUserCache shared] isFriend:member.accountId]) {
          [notFriendMembers addObject:member.accountId];
        }
      }
      [weakSelf splitMembers:notFriendMembers maxSizeByPage:150 completion:completion];
    }
  }];
}

- (void)getAllTeamMemberWithMaxLimit:(NSString *)teamId
                           nextToken:(nullable NSString *)nextToken
                          memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                           queryType:(V2NIMTeamMemberRoleQueryType)queryType
                          completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable, NSError * _Nullable))completion {
  V2NIMTeamMemberQueryOption *option = [[V2NIMTeamMemberQueryOption alloc] init];
  option.direction = V2NIM_QUERY_DIRECTION_ASC;
  option.limit = 2000;
  option.onlyChatBanned = NO;
  option.roleQueryType = queryType;
  option.nextToken = nextToken ?: @"";

  __weak typeof(self) weakSelf = self;
  [[TeamRepo shared] getTeamMemberList:teamId teamType:V2NIM_TEAM_TYPE_NORMAL queryOption:option completion:^(V2NIMTeamMemberListResult * _Nullable result, NSError * _Nullable error) {
    if (error) {
      completion(nil, error);
    } else {
      if (result.memberList) {
        [memberList addObjectsFromArray:result.memberList];
      }
      if (result.finished) {
        completion(memberList, nil);
      } else {
        [weakSelf getAllTeamMemberWithMaxLimit:teamId nextToken:result.nextToken memberList:memberList queryType:queryType completion:completion];
      }
    }
  }];
}

- (void)splitMembers:(NSArray<NSString *> *)members
       maxSizeByPage:(NSInteger)maxSizeByPage
          completion:(void (^)(NSArray<NEUserWithFriend *> *))completion {
  NSArray<NSArray<NSString *> *> *chunks = [self chunkArray:members chunkSize:maxSizeByPage];
  NSMutableArray<NEUserWithFriend *> *memberUsers = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [weakSelf fetchTeamMemberUserInfos:[chunks mutableCopy] memberUsers:memberUsers completion:completion];
  });
}

- (void)fetchTeamMemberUserInfos:(NSMutableArray<NSArray<NSString *> *> *)remainUserIds
                      memberUsers:(NSMutableArray<NEUserWithFriend *> *)memberUsers
                       completion:(void (^)(NSArray<NEUserWithFriend *> *))completion {
  if (remainUserIds.count == 0) {
    self.haveLoadAllMembers = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      completion([memberUsers copy]);
    });
    return;
  }

  NSArray<NSString *> *first = remainUserIds.firstObject;
  __weak typeof(self) weakSelf = self;
  [[ContactRepo shared] getUserListFromCloud:first completion:^(NSArray<NEUserWithFriend *> * _Nullable users, NSError * _Nullable error) {
    if (error) {
      NSLog(@"fetchTeamMemberUserInfos error: %@", error.localizedDescription);
    } else if (users) {
      for (NEUserWithFriend *user in users) {
        NSString *accid = user.user.accountId;
        if (accid) {
          weakSelf.userInfoCache[accid] = user;
          [memberUsers addObject:user];
        }
      }
      [remainUserIds removeObjectAtIndex:0];
      [weakSelf fetchTeamMemberUserInfos:remainUserIds memberUsers:memberUsers completion:completion];
    }
  }];
}

#pragma mark - NEContactListener

- (void)onContactChange:(NEContactChangeType)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
  for (NEUserWithFriend *contact in contacts) {
    NSString *accid = contact.user.accountId;
    if (!accid) continue;

    // Friend deleted, move info to userInfoCache
    if (changeType == NEContactChangeTypeDeleteFriend && self.teamMemberCache[accid]) {
      contact.friend = nil;
      [self updateUserInfoWithFriend:contact];
      continue;
    }

    if (self.userInfoCache[accid]) {
      [self updateUserInfoWithUser:contact.user];
    } else if (self.teamMemberCache[accid] && [[NEFriendUserCache shared] isFriend:accid]) {
      [self notifyTeamMemberUpdate:accid];
    }
  }
}

#pragma mark - NETeamListener

- (void)onTeamInfoUpdated:(V2NIMTeam *)team {
  if ([team.teamId isEqualToString:self.tid]) {
    [self updateTeamInfo:team];
  }
}

- (void)onTeamMemberJoined:(NSArray<V2NIMTeamMember *> *)teamMembers {
  NSMutableArray<NSString *> *notFriendMembers = [NSMutableArray array];
  for (V2NIMTeamMember *member in teamMembers) {
    if ([member.teamId isEqualToString:self.tid]) {
      [self updateTeamMemberInfo:member notify:YES];
      if (![[NEFriendUserCache shared] isFriend:member.accountId]) {
        [notFriendMembers addObject:member.accountId];
      }
    }
  }

  __weak typeof(self) weakSelf = self;
  [self splitMembers:notFriendMembers maxSizeByPage:150 completion:^(NSArray<NEUserWithFriend *> *users) {
    for (NEUserWithFriend *u in users) {
      [weakSelf updateUserInfoWithFriend:u];
    }
  }];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  for (V2NIMTeamMember *member in teamMembers) {
    if ([member.teamId isEqualToString:self.tid]) {
      [self updateTeamMemberInfo:member notify:YES];
    }
  }
}

- (void)onTeamMemberLeft:(NSArray<V2NIMTeamMember *> *)teamMembers {
  for (V2NIMTeamMember *member in teamMembers) {
    if ([member.teamId isEqualToString:self.tid]) {
      [self removeTeamMemberInfo:member.accountId];
    }
  }
}

- (void)onTeamMemberKicked:(NSString *)operatorAccountId teamMembers:(NSArray<V2NIMTeamMember *> *)teamMembers {
  for (V2NIMTeamMember *member in teamMembers) {
    if ([member.teamId isEqualToString:self.tid]) {
      [self removeTeamMemberInfo:member.accountId];
    }
  }
}

#pragma mark - NEIMKitClientListener

- (void)onDataSync:(NSInteger)type state:(NSInteger)state error:(nullable V2NIMError *)error {
  if (!self.tid) return;

  if (type == V2NIM_DATA_SYNC_TYPE_TEAM_MEMBER && state == V2NIM_DATA_SYNC_STATE_COMPLETED) {
    __weak typeof(self) weakSelf = self;
    [[TeamRepo shared] getTeamInfo:self.tid teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable err) {
      [weakSelf updateTeamInfo:team];
    }];

    [[TeamRepo shared] getTeamMember:self.tid teamType:V2NIM_TEAM_TYPE_NORMAL accId:[[IMKitClient instance] account] completion:^(V2NIMTeamMember * _Nullable teamMember, NSError * _Nullable err) {
      [weakSelf updateTeamMemberInfo:teamMember notify:YES];
    }];
  }
}

#pragma mark - Helpers

- (NSArray<NSArray<NSString *> *> *)chunkArray:(NSArray<NSString *> *)array chunkSize:(NSInteger)chunkSize {
  NSMutableArray<NSArray<NSString *> *> *chunks = [NSMutableArray array];
  NSInteger count = array.count;
  for (NSInteger i = 0; i < count; i += chunkSize) {
    NSInteger length = MIN(chunkSize, count - i);
    NSArray *chunk = [array subarrayWithRange:NSMakeRange(i, length)];
    [chunks addObject:chunk];
  }
  return [chunks copy];
}

@end
