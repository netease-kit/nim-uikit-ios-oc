// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamManagerListViewModel.h"
#import "TeamConstant.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/NSObject+NECommon.h>

@implementation TeamManagerListViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _managers = [NSMutableArray array];
    [_teamRepo addTeamListener:self];
    [[ContactRepo shared] addContactListener:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didTapHeader:)
                                                 name:NENotificationDidTapHeader
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
  [[ContactRepo shared] removeContactListener:self];
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
  NSArray<NETeamMemberInfoModel *> *managerSnapshot = [self.managers copy];
  for (NETeamMemberInfoModel *model in managerSnapshot) {
    if ([model.nimUser.user.accountId isEqualToString:accid]) {
      model.nimUser = user;
      didFind = YES;
    }
  }
  if (didFind && [self.delegate respondsToSelector:@selector(didNeedReloadData)]) {
    [self.delegate didNeedReloadData];
  }
}

- (void)getManagerDatas:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion {
  __weak typeof(self) weakSelf = self;
  [self getTeamInfo:teamId completion:^(NETeamInfoModel * _Nullable model, NSError * _Nullable error) {
    if (!error) {
      [weakSelf.managers removeAllObjects];
      NSArray<NETeamMemberInfoModel *> *memberSnapshot = [model.users copy];
      for (NETeamMemberInfoModel *memberModel in memberSnapshot) {
        if (memberModel.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
          [weakSelf.managers addObject:memberModel];
        }
      }
      if (completion) {
        completion(nil);
      }
    } else if (completion) {
      completion(error);
    }
  }];
}

- (void)getCurrentUserTeamMember:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion {
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

- (void)addTeamManager:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion {
  [self.teamRepo addManagers:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                     members:uids
                  completion:completion];
}

- (void)removeTeamManager:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion {
  [self.teamRepo removeManagers:teamId
                       teamType:V2NIM_TEAM_TYPE_NORMAL
                        members:uids
                     completion:completion];
}

- (void)getCurrentMember:(NSString *)teamId {
  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamMember:teamId
                      teamType:V2NIM_TEAM_TYPE_NORMAL
                         accId:[[IMKitClient instance] account]
                    completion:^(V2NIMTeamMember * _Nullable member, __unused NSError * _Nullable error) {
    weakSelf.currentMember = member;
  }];
}

- (void)refreshData {
  NSString *tid = self.teamId ?: @"";
  if (tid.length == 0) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self getManagerDatas:tid completion:^(NSError * _Nullable error) {
    if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedReloadData)]) {
      [weakSelf.delegate didNeedReloadData];
    }
  }];
}

- (void)onTeamMemberLeft:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamMemberKicked:(NSString *)operatorAccountId teamMembers:(NSArray<V2NIMTeamMember *> *)teamMembers {
  (void)operatorAccountId;
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamMemberJoined:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked {
  (void)team;
  (void)isKicked;
}

- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members {
  BOOL isCurrentTeam = NO;
  NSArray<V2NIMTeamMember *> *memberSnapshot = [members copy];
  for (V2NIMTeamMember *member in memberSnapshot) {
    if ([self.teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
      break;
    }
  }
  if (!isCurrentTeam) {
    return;
  }

  NSString *tid = self.teamId ?: @"";
  if (tid.length == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self getManagerDatas:tid completion:^(NSError * _Nullable error) {
    if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedReloadData)]) {
      [weakSelf.delegate didNeedReloadData];
    }
  }];
}

- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(NETeamInfoModel * _Nullable model, NSError * _Nullable error))completion {
  if (self.isRequest) {
    return;
  }
  self.isRequest = YES;

  __weak typeof(self) weakSelf = self;
  [self getCurrentUserTeamMember:teamId completion:^(NSError * _Nullable error) {
    if (error) {
      weakSelf.isRequest = NO;
      if (completion) {
        completion(nil, error);
      }
      return;
    }

    [weakSelf.teamRepo getTeamInfo:teamId
                          teamType:V2NIM_TEAM_TYPE_NORMAL
                        completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable teamError) {
      if (teamError) {
        weakSelf.isRequest = NO;
        if (completion) {
          completion(nil, teamError);
        }
        return;
      }

      NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
      model.team = team;
      [weakSelf getTeamManagers:model
                      queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_MANAGER
                     completion:^(NSError * _Nullable managerError, NETeamInfoModel * _Nullable teamInfo) {
        weakSelf.isRequest = NO;
        if (managerError) {
          if (completion) {
            completion(nil, managerError);
          }
          return;
        }

        if (teamInfo.users.count > 0) {
          [weakSelf.managers removeAllObjects];
          [weakSelf.managers addObjectsFromArray:teamInfo.users];
          [weakSelf.managers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
            int64_t time1 = obj1.teamMember.joinTime;
            int64_t time2 = obj2.teamMember.joinTime;
            if (time2 > time1) return NSOrderedAscending;
            if (time2 < time1) return NSOrderedDescending;
            return NSOrderedSame;
          }];
        }
        if (completion) {
          completion(teamInfo, nil);
        }
      }];
    }];
  }];
}

- (void)getTeamManagers:(NETeamInfoModel *)teamInfo
              queryType:(V2NIMTeamMemberRoleQueryType)queryType
             completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamid:%@", NSStringFromSelector(_cmd), teamInfo.team.teamId ?: @""]];
  NSString *teamId = teamInfo.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  NSMutableArray<V2NIMTeamMember *> *memberLists = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  [self getAllTeamManagerInfos:teamId
                     nextToken:nil
                    memberList:memberLists
                     queryType:queryType
                    completion:^(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error) {
    if (error) {
      [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [TeamManagerListViewModel className]]
                 desc:[NSString stringWithFormat:@"CALLBACK fetchTeamMember %@", error]];
      if (completion) {
        completion(error, nil);
      }
      return;
    }

    if (members.count > 0) {
      [weakSelf splitTeamManagers:members model:teamInfo maxSizeByPage:150 completion:completion];
    } else if (completion) {
      completion(nil, teamInfo);
    }
  }];
}

- (void)splitTeamManagers:(NSArray<V2NIMTeamMember *> *)members
                    model:(NETeamInfoModel *)model
            maxSizeByPage:(NSInteger)maxSizeByPage
               completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, members.count:%lu", NSStringFromSelector(_cmd), (unsigned long)members.count]];
  NSMutableArray<NSArray<V2NIMTeamMember *> *> *remain = [NSMutableArray array];
  NSInteger index = 0;
  while (index < members.count) {
    NSInteger size = MIN(maxSizeByPage, members.count - index);
    [remain addObject:[members subarrayWithRange:NSMakeRange(index, size)]];
    index += size;
  }
  [self fetchManagersInfo:remain model:model completion:completion];
}

- (void)fetchManagersInfo:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                    model:(NETeamInfoModel *)model
               completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion {
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
  [[ContactRepo shared] getUserWithFriend:accids completion:^(NSArray<NEUserWithFriend *> * _Nullable infos, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(error, model);
      }
      return;
    }

    if (infos) {
      for (NSUInteger index = 0; index < members.count; index++) {
        NETeamMemberInfoModel *memberInfoModel = [[NETeamMemberInfoModel alloc] init];
        memberInfoModel.teamMember = members[index];
        if (infos.count > index) {
          memberInfoModel.nimUser = infos[index];
        }
        [model.users addObject:memberInfoModel];
      }
    }
    [remainUserIds removeObjectAtIndex:0];
    [weakSelf fetchManagersInfo:remainUserIds model:model completion:completion];
  }];
}

- (void)getAllTeamManagerInfos:(NSString *)teamId
                     nextToken:(NSString *)nextToken
                    memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                     queryType:(V2NIMTeamMemberRoleQueryType)queryType
                    completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion {
  V2NIMTeamMemberQueryOption *option = [[V2NIMTeamMemberQueryOption alloc] init];
  option.limit = 100;
  option.direction = V2NIM_QUERY_DIRECTION_ASC;
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
      [weakSelf getAllTeamManagerInfos:teamId
                             nextToken:result.nextToken
                            memberList:memberList
                             queryType:queryType
                            completion:completion];
    }
  }];
}

- (void)onContactChange:(NEContactChangeType)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
  (void)changeType;
  NSArray<NEUserWithFriend *> *contactSnapshot = [contacts copy];
  BOOL didChange = NO;
  for (NEUserWithFriend *contact in contactSnapshot) {
    NSArray<NETeamMemberInfoModel *> *managerSnapshot = [self.managers copy];
    for (NETeamMemberInfoModel *memberInfo in managerSnapshot) {
      if ([memberInfo.teamMember.accountId isEqualToString:contact.user.accountId]) {
        memberInfo.nimUser = contact;
        didChange = YES;
      }
    }
  }
  if (didChange && [self.delegate respondsToSelector:@selector(didNeedReloadData)]) {
    [self.delegate didNeedReloadData];
  }
}

@end
