// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberSelectViewModel.h"
#import "TeamConstant.h"
#import "NESelectTeamMember.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>

@interface TeamMemberSelectViewModel ()

- (void)getData:(BOOL)showAllMembers pruneSelection:(BOOL)pruneSelection;

@end

@implementation TeamMemberSelectViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _datas = [NSMutableArray array];
    _showDatas = [NSMutableArray array];
    _selectDic = [NSMutableDictionary dictionary];
    _managerSet = [NSMutableSet set];
    _searchResults = [NSMutableDictionary dictionary];
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
  self.isLoadingMembers = YES;
  self.memberLoadError = nil;
  self.showAllMembers = showAllMembers;

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                  completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (error) {
      weakSelf.isRequest = NO;
      weakSelf.isLoadingMembers = NO;
      weakSelf.memberLoadError = error;
      if (completion) {
        completion(error);
      }
      return;
    }

    NETeamInfoModel *teamInfo = [[NETeamInfoModel alloc] init];
    teamInfo.team = team;
    NSArray<NETeamMemberInfoModel *> *cachedMembers = [[NETeamUserManager shared] getAllTeamMemberModels];
    V2NIMTeam *cachedTeam = [[NETeamUserManager shared] getTeamInfo];
    if ([cachedTeam.teamId isEqualToString:teamId] &&
        cachedMembers.count > 0 &&
        team.memberCount == cachedMembers.count) {
      NSMutableArray<NETeamMemberInfoModel *> *members = [cachedMembers mutableCopy];
      if (!showAllMembers) {
        NSIndexSet *indexes = [members indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
          NSString *account = obj.teamMember.accountId ?: obj.nimUser.user.accountId ?: @"";
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
      weakSelf.isLoadingMembers = NO;
      weakSelf.memberLoadError = nil;
      if (completion) {
        completion(nil);
      }
      return;
    }

    [[NETeamUserManager shared] getAllTeamMembers:teamId
                                       queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                        progress:^(NETeamMemberLoadProgress *progress) {
      if (![progress.teamId isEqualToString:teamId]) {
        return;
      }
      weakSelf.isLoadingMembers = progress.phase == NETeamMemberLoadPhaseLoading;
      weakSelf.memberLoadError = progress.error;
      if (progress.phase != NETeamMemberLoadPhaseLoading &&
          progress.phase != NETeamMemberLoadPhaseFinished) {
        if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefresh)]) {
          [weakSelf.delegate didNeedRefresh];
        }
        return;
      }
      NETeamInfoModel *snapshot = [[NETeamInfoModel alloc] init];
      snapshot.team = team;
      NSMutableArray<NETeamMemberInfoModel *> *members = [NSMutableArray array];
      for (NETeamMemberInfoModel *member in progress.members) {
        NSString *accountId = member.teamMember.accountId ?: @"";
        if (showAllMembers || ![[NEAIUserManager shared] isAIUser:accountId]) {
          [members addObject:member];
        }
      }
      snapshot.users = [members copy];
      weakSelf.teamInfoModel = snapshot;
      [weakSelf.datas removeAllObjects];
      [weakSelf.showDatas removeAllObjects];
      [weakSelf getData:showAllMembers pruneSelection:progress.phase == NETeamMemberLoadPhaseFinished];
      if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefresh)]) {
        [weakSelf.delegate didNeedRefresh];
      }
    }
                                      completion:^(__unused NSArray<NEUserWithFriend *> *users) {
      weakSelf.isRequest = NO;
      NSArray<NETeamMemberInfoModel *> *members = [[NETeamUserManager shared] getAllTeamMemberModels];
      V2NIMTeam *currentTeam = [[NETeamUserManager shared] getTeamInfo];
      if ([currentTeam.teamId isEqualToString:teamId] && members.count > 0) {
        NSMutableArray<NETeamMemberInfoModel *> *filteredMembers = [NSMutableArray array];
        for (NETeamMemberInfoModel *member in members) {
          NSString *accountId = member.teamMember.accountId ?: @"";
          if (showAllMembers || ![[NEAIUserManager shared] isAIUser:accountId]) {
            [filteredMembers addObject:member];
          }
        }
        teamInfo.users = [filteredMembers copy];
        weakSelf.teamInfoModel = teamInfo;
        [weakSelf.datas removeAllObjects];
        [weakSelf.showDatas removeAllObjects];
        [weakSelf getData:showAllMembers];
        weakSelf.isLoadingMembers = NO;
        weakSelf.memberLoadError = nil;
      }
      if (completion) {
        completion(weakSelf.memberLoadError);
      }
    }];
  }];
}

- (void)getData:(BOOL)showAllMembers {
  [self getData:showAllMembers pruneSelection:YES];
}

- (void)getData:(BOOL)showAllMembers pruneSelection:(BOOL)pruneSelection {
  NSMutableSet<NSString *> *filters = [NSMutableSet set];
  [filters addObjectsFromArray:self.selectDic.allKeys];
  [self.managerSet removeAllObjects];

  NSArray<NETeamMemberInfoModel *> *userSnapshot = [self.teamInfoModel.users copy];
  for (NETeamMemberInfoModel *userModel in userSnapshot) {
    NSString *uid = userModel.teamMember.accountId ?: userModel.nimUser.user.accountId ?: @"";
    if (uid.length > 0) {
      [filters removeObject:uid];
    }
    if (!showAllMembers && uid.length > 0) {
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

  if (pruneSelection) {
    NSArray<NSString *> *filterSnapshot = filters.allObjects;
    for (NSString *uid in filterSnapshot) {
      [self.selectDic removeObjectForKey:uid];
    }
  }

  NSArray<NESelectTeamMember *> *dataSnapshot = [self.datas copy];
  for (NESelectTeamMember *member in dataSnapshot) {
    NSString *accid = member.member.teamMember.accountId ?: member.member.nimUser.user.accountId ?: @"";
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
  [self.searchResults removeAllObjects];
  NSMutableArray<NESelectTeamMember *> *result = [NSMutableArray array];
  for (NESelectTeamMember *member in self.datas) {
    NETeamMemberSearchResult *searchResult = [self searchResult:searchText forSelectModel:member];
    if (!searchResult) {
      continue;
    }
    [result addObject:member];
    NSString *accountId = member.member.teamMember.accountId;
    if (accountId.length > 0) {
      self.searchResults[accountId] = searchResult;
    }
  }
  return [result copy];
}

- (NSArray<NESelectTeamMember *> *)searchShowData:(NSString *)searchText {
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NESelectTeamMember *evaluatedObject, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
    return [self findContainStr:searchText selectModel:evaluatedObject];
  }];
  return [self.showDatas filteredArrayUsingPredicate:predicate];
}

- (BOOL)findContainStr:(NSString *)text selectModel:(NESelectTeamMember *)selectModel {
  return [self searchResult:text forSelectModel:selectModel] != nil;
}

- (NETeamMemberSearchResult *)searchResult:(NSString *)text
                            forSelectModel:(NESelectTeamMember *)selectModel {
  return [NETeamMemberSearchMatcher resultWithKeyword:text
                                             teamNick:selectModel.member.teamMember.teamNick
                                          friendAlias:selectModel.member.nimUser.friend.alias
                                         userNickname:selectModel.member.nimUser.user.name
                                            accountId:selectModel.member.teamMember.accountId ?: selectModel.member.nimUser.user.accountId];
}

- (nullable NETeamMemberSearchResult *)currentSearchResultForSelectModel:(NESelectTeamMember *)selectModel {
  NSString *accountId = selectModel.member.teamMember.accountId;
  if (accountId.length == 0) {
    return nil;
  }
  return self.searchResults[accountId];
}

- (void)resetSearchResults {
  [self.searchResults removeAllObjects];
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
