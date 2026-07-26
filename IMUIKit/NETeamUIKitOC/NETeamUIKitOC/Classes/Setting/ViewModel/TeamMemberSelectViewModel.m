// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberSelectViewModel.h"
#import "TeamConstant.h"
#import "NESelectTeamMember.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>

@implementation TeamMemberSelectViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _datas = [NSMutableArray array];
    _showDatas = [NSMutableArray array];
    _selectDic = [NSMutableDictionary dictionary];
    _managerSet = [NSMutableSet set];
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
  NSArray<NESelectTeamMember *> *showSnapshot = [self.showDatas copy];
  for (NESelectTeamMember *model in showSnapshot) {
    if ([model.member.nimUser.user.accountId isEqualToString:accid]) {
      model.member.nimUser = user;
      didFind = YES;
    }
  }
  if (didFind && [self.delegate respondsToSelector:@selector(didNeedRefresh)]) {
    [self.delegate didNeedRefresh];
  }
}

- (void)getTeamInfo:(NSString *)teamId
     showAllMembers:(BOOL)showAllMembers
         completion:(void (^)(NSError * _Nullable error))completion {
  if (self.isRequest) {
    return;
  }
  self.isRequest = YES;
  self.showAllMembers = showAllMembers;

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                  completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (error) {
      weakSelf.isRequest = NO;
      if (completion) {
        completion(error);
      }
      return;
    }

    NETeamInfoModel *teamInfo = [[NETeamInfoModel alloc] init];
    teamInfo.team = team;
    NSArray<NETeamMemberInfoModel *> *cachedMembers = [[NETeamUserManager shared] getAllTeamMemberModels];
    if (cachedMembers.count > 0 && team.memberCount == cachedMembers.count) {
      NSMutableArray<NETeamMemberInfoModel *> *members = [cachedMembers mutableCopy];
      if (!showAllMembers) {
        NSIndexSet *indexes = [members indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
          NSString *account = obj.nimUser.user.accountId ?: @"";
          return [[NEAIUserManager shared] isAIUser:account];
        }];
        [members removeObjectsAtIndexes:indexes];
      }
      teamInfo.users = [members copy];
      weakSelf.teamInfoModel = teamInfo;
      [weakSelf.datas removeAllObjects];
      [weakSelf.showDatas removeAllObjects];
      [weakSelf getData:showAllMembers];
      weakSelf.isRequest = NO;
      if (completion) {
        completion(nil);
      }
      return;
    }

    NSMutableArray<V2NIMTeamMember *> *memberLists = [NSMutableArray array];
    [weakSelf getSelectMemberInfos:teamId
                         nextToken:nil
                        memberList:memberLists
                         queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                        completion:^(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable infoError) {
      if (infoError) {
        [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [TeamMemberSelectViewModel className]]
                   desc:[NSString stringWithFormat:@"CALLBACK fetchTeamMember %@", infoError]];
        weakSelf.isRequest = NO;
        if (completion) {
          completion(nil);
        }
        return;
      }

      if (members.count > 0) {
        [weakSelf splitSelectMembers:members
                               model:teamInfo
                       maxSizeByPage:150
                          completion:^(NSError * _Nullable splitError, NETeamInfoModel * _Nullable model) {
          if (model.users.count > 0) {
            NSMutableArray<NETeamMemberInfoModel *> *filteredUsers = [model.users mutableCopy] ?: [NSMutableArray array];
            NSIndexSet *indexes = [filteredUsers indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
              NSString *account = obj.nimUser.user.accountId ?: @"";
              return [[NEAIUserManager shared] isAIUser:account];
            }];
            [filteredUsers removeObjectsAtIndexes:indexes];
            model.users = [filteredUsers copy];
          }
          weakSelf.teamInfoModel = model;
          weakSelf.isRequest = NO;
          [weakSelf getData:showAllMembers];
          if (completion) {
            completion(splitError);
          }
        }];
      } else {
        weakSelf.isRequest = NO;
        if (completion) {
          completion(infoError);
        }
      }
    }];
  }];
}

- (void)getData:(BOOL)showAllMembers {
  NSMutableSet<NSString *> *filters = [NSMutableSet set];
  [filters addObjectsFromArray:self.selectDic.allKeys];
  [self.managerSet removeAllObjects];

  NSArray<NETeamMemberInfoModel *> *userSnapshot = [self.teamInfoModel.users copy];
  for (NETeamMemberInfoModel *userModel in userSnapshot) {
    NSString *uid = userModel.nimUser.user.accountId ?: @"";
    if (!showAllMembers && uid.length > 0) {
      [filters removeObject:uid];
      if ([uid isEqualToString:[[IMKitClient instance] account]]) {
        continue;
      }
      if ([uid isEqualToString:self.teamInfoModel.team.ownerAccountId]) {
        continue;
      }
      if (userModel.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
        [self.managerSet addObject:uid];
        [self.selectDic removeObjectForKey:uid];
        continue;
      }
    }

    NESelectTeamMember *selectMember = [[NESelectTeamMember alloc] init];
    selectMember.member = userModel;
    [self.datas addObject:selectMember];
    [self.showDatas addObject:selectMember];
  }

  NSArray<NSString *> *filterSnapshot = filters.allObjects;
  for (NSString *uid in filterSnapshot) {
    [self.selectDic removeObjectForKey:uid];
  }

  NSArray<NESelectTeamMember *> *dataSnapshot = [self.datas copy];
  for (NESelectTeamMember *member in dataSnapshot) {
    NSString *accid = member.member.nimUser.user.accountId ?: @"";
    if (accid.length > 0 && self.selectDic[accid]) {
      member.isSelected = YES;
    }
  }
}

- (void)onTeamMemberUpdate:(NSString *)accountId {
  (void)accountId;
  NSString *tid = self.teamInfoModel.team.teamId ?: @"";
  if (tid.length == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self getTeamInfo:tid showAllMembers:self.showAllMembers completion:^(NSError * _Nullable error) {
    if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedRefresh)]) {
      [weakSelf.delegate didNeedRefresh];
    } else {
      [NEALog infoLog:[TeamMemberSelectViewModel className]
                 desc:[NSString stringWithFormat:@"%@ memberCacheDidChange get team info error %@", NSStringFromSelector(_cmd), error.localizedDescription ?: @""]];
    }
  }];
}

- (NSArray<NESelectTeamMember *> *)searchAllData:(NSString *)searchText {
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NESelectTeamMember *evaluatedObject, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
    return [self findContainStr:searchText selectModel:evaluatedObject];
  }];
  return [self.datas filteredArrayUsingPredicate:predicate];
}

- (NSArray<NESelectTeamMember *> *)searchShowData:(NSString *)searchText {
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NESelectTeamMember *evaluatedObject, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
    return [self findContainStr:searchText selectModel:evaluatedObject];
  }];
  return [self.showDatas filteredArrayUsingPredicate:predicate];
}

- (BOOL)findContainStr:(NSString *)text selectModel:(NESelectTeamMember *)selectModel {
  NSString *uid = selectModel.member.nimUser.user.accountId ?: @"";
  NSString *nick = [selectModel.member.nimUser showName:NO] ?: @"";
  NSString *alias = selectModel.member.nimUser.friend.alias ?: @"";
  NSString *teamNick = selectModel.member.teamMember.teamNick ?: @"";
  return [uid containsString:text] || [nick containsString:text] || [alias containsString:text] || [teamNick containsString:text];
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

- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members {
  BOOL isCurrentTeam = NO;
  NSArray<V2NIMTeamMember *> *memberSnapshot = [members copy];
  for (V2NIMTeamMember *member in memberSnapshot) {
    if ([self.teamInfoModel.team.teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
      break;
    }
  }

  if (isCurrentTeam) {
    NSString *tid = self.teamInfoModel.team.teamId ?: @"";
    if (tid.length == 0) {
      return;
    }

    __weak typeof(self) weakSelf = self;
    [self getTeamInfo:tid showAllMembers:self.showAllMembers completion:^(NSError * _Nullable error) {
      if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedRefresh)]) {
        [weakSelf.delegate didNeedRefresh];
      }
    }];
  }
}

- (void)getTeamMembers:(NETeamInfoModel *)teamInfo
             queryType:(V2NIMTeamMemberRoleQueryType)queryType
            completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamid:%@", NSStringFromSelector(_cmd), teamInfo.team.teamId ?: @""]];
  NSString *teamId = teamInfo.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  NSArray<NETeamMemberInfoModel *> *cachedMembers = [[NETeamUserManager shared] getAllTeamMemberModels];
  if (cachedMembers) {
    teamInfo.users = [cachedMembers copy];
    if (completion) {
      completion(nil, teamInfo);
    }
    [NEALog infoLog:[TeamMemberSelectViewModel className] desc:@"load team member from cache success."];
    return;
  }

  NSMutableArray<V2NIMTeamMember *> *memberLists = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  [self getSelectMemberInfos:teamId
                   nextToken:nil
                  memberList:memberLists
                   queryType:queryType
                  completion:^(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error) {
    if (error) {
      [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [TeamMemberSelectViewModel className]]
                 desc:[NSString stringWithFormat:@"CALLBACK fetchTeamMember %@", error]];
      if (completion) {
        completion(error, nil);
      }
      return;
    }

    if (members.count > 0) {
      [weakSelf splitSelectMembers:members model:teamInfo maxSizeByPage:150 completion:completion];
    } else if (completion) {
      completion(nil, teamInfo);
    }
  }];
}

- (void)splitSelectMembers:(NSArray<V2NIMTeamMember *> *)members
                     model:(NETeamInfoModel *)model
             maxSizeByPage:(NSInteger)maxSizeByPage
                completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, members.count:%lu", NSStringFromSelector(_cmd), (unsigned long)members.count]];
  NSMutableArray<NSArray<V2NIMTeamMember *> *> *remain = [NSMutableArray array];
  NSInteger index = 0;
  while (index < members.count) {
    NSInteger size = MIN(maxSizeByPage, members.count - index);
    [remain addObject:[members subarrayWithRange:NSMakeRange(index, size)]];
    index += size;
  }
  [self fetchSelectUsersInfo:remain model:model completion:completion];
}

- (void)fetchSelectUsersInfo:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                       model:(NETeamInfoModel *)model
                  completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion {
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
      NSMutableArray<NETeamMemberInfoModel *> *users = [model.users mutableCopy] ?: [NSMutableArray array];
      for (NSUInteger index = 0; index < members.count; index++) {
        NETeamMemberInfoModel *memberInfoModel = [[NETeamMemberInfoModel alloc] init];
        memberInfoModel.teamMember = members[index];
        if (infos.count > index) {
          memberInfoModel.nimUser = infos[index];
        }
        [users addObject:memberInfoModel];
      }
      model.users = [users copy];
    }

    [remainUserIds removeObjectAtIndex:0];
    [weakSelf fetchSelectUsersInfo:remainUserIds model:model completion:completion];
  }];
}

- (void)getSelectMemberInfos:(NSString *)teamId
                   nextToken:(NSString *)nextToken
                  memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                   queryType:(V2NIMTeamMemberRoleQueryType)queryType
                  completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion {
  V2NIMTeamMemberQueryOption *option = [[V2NIMTeamMemberQueryOption alloc] init];
  option.limit = 1000;
  option.onlyChatBanned = NO;
  option.direction = V2NIM_QUERY_DIRECTION_ASC;
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
      [weakSelf getSelectMemberInfos:teamId
                           nextToken:result.nextToken
                          memberList:memberList
                           queryType:queryType
                          completion:completion];
    }
  }];
}

@end
