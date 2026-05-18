// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMembersViewModel.h"
#import "TeamConstant.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKitOC/NSObject+NECommon.h>
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NEALog.h>

@implementation TeamMembersViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _datas = [NSMutableArray array];
    _searchDatas = [NSMutableArray array];
    _teamRepo = [TeamRepo shared];
    _onLineEventDic = [NSMutableDictionary dictionary];
    [_teamRepo addTeamListener:self];
    [[NETeamUserManager shared] addListener:self];
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
    if (time2 > time1) return NSOrderedAscending;
    if (time2 < time1) return NSOrderedDescending;
    return NSOrderedSame;
  }];
  [normalMembers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time2 > time1) return NSOrderedAscending;
    if (time2 < time1) return NSOrderedDescending;
    return NSOrderedSame;
  }];
  [self.datas addObjectsFromArray:managers];
  [self.datas addObjectsFromArray:normalMembers];

  if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)removeModel:(NSArray<NSString *> *)rmUids {
  NSIndexSet *indexes = [self.datas indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
    NSString *uid = obj.nimUser.user.accountId ?: @"";
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
  if (team && teamMembers) {
    NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
    model.team = team;
    [model.users addObjectsFromArray:teamMembers];
    [weakSelf setShowDatas:model.users];
    weakSelf.currentMember = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
    if (completion) {
      completion(model, nil);
    }
    return;
  }

  if (self.isRequest) {
    return;
  }
  self.isRequest = YES;

  [[NETeamUserManager shared] getAllTeamMembers:teamId
                                      queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                     completion:^(__unused NSArray<NEUserWithFriend *> *users) {
    weakSelf.isRequest = NO;
    V2NIMTeam *currentTeam = [[NETeamUserManager shared] getTeamInfo];
    NSArray<NETeamMemberInfoModel *> *members = [[NETeamUserManager shared] getAllTeamMemberModels];
    if (members) {
      NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
      model.team = currentTeam;
      [model.users addObjectsFromArray:members];
      [weakSelf setShowDatas:model.users];
      weakSelf.currentMember = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
      if (completion) {
        completion(model, nil);
      }
    } else if (completion) {
      completion(nil, nil);
    }
  }];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self changeMembers:teamMembers];
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

@end
