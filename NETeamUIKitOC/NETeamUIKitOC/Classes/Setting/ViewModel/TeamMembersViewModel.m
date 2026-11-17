// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMembersViewModel.h"
#import "TeamConstant.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>

@interface TeamMembersViewModel ()
@property (nonatomic, copy) NSString *currentSearchKeyword;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NETeamMemberSearchResult *> *searchResults;
@end

@implementation TeamMembersViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _datas = [NSMutableArray array];
    _searchDatas = [NSMutableArray array];
    _teamRepo = [TeamRepo shared];
    _onLineEventDic = [NSMutableDictionary dictionary];
    _searchResults = [NSMutableDictionary dictionary];
    _currentSearchKeyword = @"";
    [_teamRepo addTeamListener:self];
    [[NETeamUserManager shared] addListener:self];
    [[NEAIUserManager shared] addAIUserChangeListener:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didTapHeader:)
                                                 name:NENotificationDidTapHeader
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
  [[NETeamUserManager shared] removeListener:self];
  [[NEAIUserManager shared] removeAIUserChangeListener:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didTapHeader:(NSNotification *)noti {
  if (![noti.object isKindOfClass:[NEUserWithFriend class]]) {
    return;
  }
  NEUserWithFriend *user = (NEUserWithFriend *)noti.object;
  NSString *accid = user.user.accountId ?: @"";
  if (accid.length == 0 || ![[NETeamUserManager shared] isCurrentMember:accid]) {
    return;
  }

  BOOL didFind = NO;
  NSArray<NETeamMemberInfoModel *> *dataSnapshot = [self.datas copy];
  for (NETeamMemberInfoModel *model in dataSnapshot) {
    if ([model.nimUser.user.accountId isEqualToString:accid]) {
      model.nimUser = user;
      didFind = YES;
    }
  }
  NSArray<NETeamMemberInfoModel *> *searchSnapshot = [self.searchDatas copy];
  for (NETeamMemberInfoModel *model in searchSnapshot) {
    if ([model.nimUser.user.accountId isEqualToString:accid]) {
      model.nimUser = user;
      didFind = YES;
    }
  }
  if (didFind && [self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)getMemberInfo:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion {
  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamMember:teamId
                      teamType:V2NIM_TEAM_TYPE_NORMAL
                         accId:[[IMKitClient instance] account]
                    completion:^(V2NIMTeamMember * _Nullable member, NSError * _Nullable error) {
    weakSelf.currentMember = member;
    if (completion) {
      completion(error);
    }
  }];
}

- (void)subcribeMembers:(NSArray<NETeamMemberInfoModel *> *)members
             completion:(void (^)(NSError * _Nullable error))completion {
  NSMutableArray<NSString *> *accounts = [NSMutableArray array];
  for (NETeamMemberInfoModel *model in members) {
    NSString *accountId = model.teamMember.accountId;
    if (accountId.length == 0 || [[NEAIUserManager shared] isAIUser:accountId]) continue;
    V2NIMUserStatus *event = [[NESubscribeManager shared] getSubscribeStatus:accountId];
    if (event) {
      self.onLineEventDic[accountId] = @([NESubscribeManager isOnline:event]);
    } else {
      [accounts addObject:accountId];
    }
  }
  [[NESubscribeManager shared] subscribeUsersOnlineState:accounts completion:completion ?: ^(NSError *error) {}];
}

- (void)unSubcribeMembers:(NSArray<NETeamMemberInfoModel *> *)members
                completion:(void (^)(NSError * _Nullable error))completion {
  NSMutableArray<NSString *> *accounts = [NSMutableArray array];
  for (NETeamMemberInfoModel *model in members) {
    if (model.teamMember.accountId.length > 0) [accounts addObject:model.teamMember.accountId];
  }
  [[NESubscribeManager shared] unSubscribeUsersOnlineState:accounts completion:completion ?: ^(NSError *error) {}];
}

- (void)onUserStatusChanged:(NSArray<V2NIMUserStatus *> *)data {
  for (V2NIMUserStatus *status in data) {
    if (status.accountId.length > 0) {
      self.onLineEventDic[status.accountId] = @([NESubscribeManager isOnline:status]);
    }
  }
  if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)removeTeamMember:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion {
  [self.teamRepo removeTeamMembers:teamId
                          teamType:V2NIM_TEAM_TYPE_NORMAL
                           members:uids
                        completion:^(NSError * _Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

- (void)setShowDatas:(NSArray<NETeamMemberInfoModel *> *)memberDatas {
  NETeamMemberInfoModel *owner = nil;
  NSMutableArray<NETeamMemberInfoModel *> *managers = [NSMutableArray array];
  NSMutableArray<NETeamMemberInfoModel *> *normalMembers = [NSMutableArray array];

  NSArray<NETeamMemberInfoModel *> *memberSnapshot = [memberDatas copy];
  for (NETeamMemberInfoModel *model in memberSnapshot) {
    if (model.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_OWNER) {
      owner = model;
    } else if (model.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [managers addObject:model];
    } else {
      [normalMembers addObject:model];
    }
  }

  [self.datas removeAllObjects];
  if (owner) {
    [self.datas addObject:owner];
  }
  [managers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time1 < time2) return NSOrderedAscending;
    if (time1 > time2) return NSOrderedDescending;
    return [obj1.teamMember.accountId compare:obj2.teamMember.accountId];
  }];
  [normalMembers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time1 < time2) return NSOrderedAscending;
    if (time1 > time2) return NSOrderedDescending;
    return [obj1.teamMember.accountId compare:obj2.teamMember.accountId];
  }];
  [self.datas addObjectsFromArray:managers];
  [self.datas addObjectsFromArray:normalMembers];
  [self searchData:self.currentSearchKeyword];

  if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)removeModel:(NSArray<NSString *> *)rmUids {
  NSIndexSet *indexes = [self.datas indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
    NSString *uid = obj.teamMember.accountId ?: obj.nimUser.user.accountId ?: @"";
    return [rmUids containsObject:uid];
  }];
  [self.datas removeObjectsAtIndexes:indexes];
  if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)removeSearchData:(NSArray<V2NIMTeamMember *> *)teamMembers {
  if (self.searchDatas.count <= 0) {
    return;
  }

  NSMutableSet<NSString *> *memberSet = [NSMutableSet set];
  for (V2NIMTeamMember *member in teamMembers) {
    if ([self.teamId isEqualToString:member.teamId]) {
      [memberSet addObject:member.accountId ?: @""];
    }
  }
  if (memberSet.count <= 0) {
    return;
  }

  NSIndexSet *indexes = [self.searchDatas indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
    NSString *accid = obj.teamMember.accountId ?: @"";
    return [memberSet containsObject:accid];
  }];
  [self.searchDatas removeObjectsAtIndexes:indexes];
  if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)changeMembers:(NSArray<V2NIMTeamMember *> *)teamMembers {
  if (self.teamId.length == 0) {
    return;
  }

  BOOL needRefresh = NO;
  NSArray<V2NIMTeamMember *> *memberSnapshot = [teamMembers copy];
  for (V2NIMTeamMember *member in memberSnapshot) {
    if ([member.teamId isEqualToString:self.teamId]) {
      needRefresh = YES;
      break;
    }
  }
  if (!needRefresh) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self getTeamInfo:self.teamId completion:^(__unused NETeamInfoModel * _Nullable model, NSError * _Nullable error) {
    if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
      [weakSelf.delegate didNeedRefreshUI];
    }
  }];
}

- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(NETeamInfoModel * _Nullable model, NSError * _Nullable error))completion {
  __weak typeof(self) weakSelf = self;
  V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
  NSArray<NETeamMemberInfoModel *> *teamMembers = [[NETeamUserManager shared] getAllTeamMemberModels];
  if ([team.teamId isEqualToString:teamId] && teamMembers) {
    NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
    model.team = team;
    model.users = [teamMembers copy];
    [weakSelf setShowDatas:model.users];
    weakSelf.currentMember = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
    weakSelf.isLoadingMembers = NO;
    weakSelf.memberLoadError = nil;
    if (completion) {
      completion(model, nil);
    }
    return;
  }

  if (self.isRequest) {
    return;
  }
  self.isRequest = YES;
  self.isLoadingMembers = YES;
  self.memberLoadError = nil;

  [[NETeamUserManager shared] getAllTeamMembers:teamId
                                      queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                       progress:^(NETeamMemberLoadProgress *progress) {
    if (![progress.teamId isEqualToString:teamId]) {
      return;
    }
    weakSelf.isLoadingMembers = progress.phase == NETeamMemberLoadPhaseLoading;
    weakSelf.memberLoadError = progress.error;
    if (progress.phase == NETeamMemberLoadPhaseLoading || progress.phase == NETeamMemberLoadPhaseFinished) {
      [weakSelf setShowDatas:progress.members];
    }
    if (progress.phase == NETeamMemberLoadPhaseFailed && [weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
      [weakSelf.delegate didNeedRefreshUI];
    }
  }
                                     completion:^(__unused NSArray<NEUserWithFriend *> *users) {
    weakSelf.isRequest = NO;
    V2NIMTeam *currentTeam = [[NETeamUserManager shared] getTeamInfo];
    NSArray<NETeamMemberInfoModel *> *members = [[NETeamUserManager shared] getAllTeamMemberModels];
    if ([currentTeam.teamId isEqualToString:teamId] && members) {
      NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
      model.team = currentTeam;
      model.users = [members copy];
      [weakSelf setShowDatas:model.users];
      weakSelf.currentMember = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
      if (completion) {
        completion(model, nil);
      }
    } else {
      weakSelf.isLoadingMembers = NO;
      if (completion) {
        completion(nil, weakSelf.memberLoadError);
      }
    }
  }];
}

- (NSArray<NETeamMemberInfoModel *> *)searchData:(NSString *)keyword {
  self.currentSearchKeyword = keyword ?: @"";
  [self.searchResults removeAllObjects];
  NSString *normalized = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [self.searchDatas removeAllObjects];
  if (normalized.length == 0) {
    return @[];
  }
  for (NETeamMemberInfoModel *model in [self.datas copy]) {
    NETeamMemberSearchResult *result = [NETeamMemberSearchMatcher resultWithKeyword:normalized
                                                                              teamNick:model.teamMember.teamNick
                                                                            friendAlias:model.nimUser.friend.alias
                                                                         userNickname:model.nimUser.user.name
                                                                            accountId:model.teamMember.accountId ?: model.nimUser.user.accountId];
    if (result) {
      [self.searchDatas addObject:model];
      NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
      if (accountId.length > 0) {
        self.searchResults[accountId] = result;
      }
    }
  }
  return [self.searchDatas copy];
}

- (NETeamMemberSearchResult *)searchResultForModel:(NETeamMemberInfoModel *)model {
  NSString *accountId = model.teamMember.accountId;
  if (accountId.length == 0) {
    accountId = model.nimUser.user.accountId;
  }
  if (accountId.length == 0) {
    return nil;
  }
  return self.searchResults[accountId];
}

- (NETeamMemberSearchResult *)searchResultForModel:(NETeamMemberInfoModel *)model keyword:(NSString *)keyword {
  if (keyword.length == 0 || [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
    return [self searchResultForModel:model];
  }
  return [NETeamMemberSearchMatcher resultWithKeyword:keyword
                                              teamNick:model.teamMember.teamNick
                                            friendAlias:model.nimUser.friend.alias
                                         userNickname:model.nimUser.user.name
                                            accountId:model.teamMember.accountId ?: model.nimUser.user.accountId];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  // Swift intentionally leaves this callback empty. Member leave/kick and the
  // explicit cache-update callback own the visible refresh path.
}

- (void)getTeamMembers:(NETeamInfoModel *)teamInfo
             queryType:(V2NIMTeamMemberRoleQueryType)queryType
            completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion {
  (void)queryType;
  NSString *teamId = teamInfo.team.teamId ?: @"";
  [NEALog infoLog:[self className]
             desc:[NSString stringWithFormat:@"%@ teamid:%@", NSStringFromSelector(_cmd), teamId]];
  NSArray<NETeamMemberInfoModel *> *members = [[NETeamUserManager shared] getAllTeamMemberModels];
  if (members && teamInfo.team && teamInfo.team.memberCount == members.count) {
    teamInfo.users = members;
    if (completion) {
      completion(nil, teamInfo);
    }
    [NEALog infoLog:[self className] desc:@"load team member from cache success."];
  }
}

- (void)onTeamMemberLeft:(NSArray<V2NIMTeamMember *> *)teamMembers {
  BOOL isCurrentTeam = NO;
  NSArray<V2NIMTeamMember *> *memberSnapshot = [teamMembers copy];
  for (V2NIMTeamMember *member in memberSnapshot) {
    if ([self.teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
      break;
    }
  }

  if (isCurrentTeam) {
    [self removeSearchData:teamMembers];
    NSMutableArray<NSString *> *uids = [NSMutableArray array];
    for (V2NIMTeamMember *member in memberSnapshot) {
      if (member.accountId.length > 0) {
        [uids addObject:member.accountId];
      }
    }
    [self removeModel:uids];
  }
}

- (void)onTeamMemberJoined:(NSArray<V2NIMTeamMember *> *)teamMembers {
}

- (void)onTeamMemberKicked:(NSString *)operatorAccountId teamMembers:(NSArray<V2NIMTeamMember *> *)teamMembers {
  (void)operatorAccountId;
  BOOL isCurrentTeam = NO;
  NSArray<V2NIMTeamMember *> *memberSnapshot = [teamMembers copy];
  for (V2NIMTeamMember *member in memberSnapshot) {
    if ([self.teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
      break;
    }
  }

  if (isCurrentTeam) {
    [self removeSearchData:teamMembers];
    NSMutableArray<NSString *> *uids = [NSMutableArray array];
    for (V2NIMTeamMember *member in memberSnapshot) {
      if (member.accountId.length > 0) {
        [uids addObject:member.accountId];
      }
    }
    [self removeModel:uids];
  }
}

- (void)onTeamMemberUpdate:(NSString *)accountId {
  [NEALog infoLog:[self className] desc:[NSString stringWithFormat:@"%@ memberCacheDidChange", NSStringFromSelector(_cmd)]];
  NSString *tid = self.teamId ?: @"";
  if (tid.length == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  NSArray<NETeamMemberInfoModel *> *members = [[NETeamUserManager shared] getAllTeamMemberModels];
  if (members) {
    [self getMemberInfo:tid completion:^(NSError * _Nullable error) {
      if (!error) {
        [weakSelf setShowDatas:members];
        if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [weakSelf.delegate didNeedRefreshUI];
        }
      } else {
        [NEALog infoLog:[TeamMembersViewModel className]
                   desc:[NSString stringWithFormat:@"%@ getMemberInfo error:%@", NSStringFromSelector(_cmd), error.localizedDescription ?: @""]];
      }
    }];
  } else {
    [self getTeamInfo:tid completion:^(__unused NETeamInfoModel * _Nullable teamInfo, __unused NSError * _Nullable error) {
      if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
        [weakSelf.delegate didNeedRefreshUI];
      }
    }];
  }
}

- (void)onAIUserChanged:(NSArray<V2NIMAIUser *> *)aiUsers {
  NSMutableDictionary<NSString *, NEUserWithFriend *> *usersById = [NSMutableDictionary dictionary];
  for (V2NIMAIUser *user in aiUsers) {
    if (user.accountId.length > 0) {
      usersById[user.accountId] = [[NEUserWithFriend alloc] initWithUser:user friend:nil];
    }
  }
  BOOL didUpdate = NO;
  for (NETeamMemberInfoModel *model in [self.datas copy]) {
    NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
    NEUserWithFriend *user = usersById[accountId];
    if (user) {
      model.nimUser = user;
      didUpdate = YES;
    }
  }
  for (NETeamMemberInfoModel *model in [self.searchDatas copy]) {
    NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
    NEUserWithFriend *user = usersById[accountId];
    if (user) {
      model.nimUser = user;
      didUpdate = YES;
    }
  }
  if (didUpdate) {
    [self searchData:self.currentSearchKeyword];
    if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
      [self.delegate didNeedRefreshUI];
    }
  }
}

@end
