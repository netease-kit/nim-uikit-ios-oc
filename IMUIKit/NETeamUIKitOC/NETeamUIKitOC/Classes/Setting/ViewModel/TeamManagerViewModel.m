// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamManagerViewModel.h"
#import "TeamConstant.h"
#import "SettingCellLabelArrowModel.h"
#import "SettingCellModel.h"
#import "SettingSectionModel.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NECommonUtil.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@implementation TeamManagerViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _chatRepo = [ChatRepo shared];
    _sectionData = [NSMutableArray array];
    _managerUsers = [NSMutableArray array];
    [_teamRepo addTeamListener:self];
  }
  return self;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
}

- (void)getSectionData {
  [self.sectionData removeAllObjects];
  NSString *ownerId = self.teamInfoModel.team.ownerAccountId ?: @"";
  if (ownerId.length > 0 && [ownerId isEqualToString:[IMKitClient instance].account]) {
    [self.sectionData addObject:[self getFirstSection]];
  }
  [self.sectionData addObject:[self getSecondSection]];
  [self.sectionData addObject:[self getThirdSection]];
}

- (void)getCurrentUserTeamMember:(NSString *)userId
                          teamId:(NSString *)teamId
                      completion:(void (^)(V2NIMTeamMember * _Nullable, NSError * _Nullable))completion {
  if (teamId.length <= 0) {
    if (completion) {
      completion(nil, nil);
    }
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamMember:teamId
                      teamType:V2NIM_TEAM_TYPE_NORMAL
                         accId:userId
                    completion:^(V2NIMTeamMember * _Nullable member, NSError * _Nullable error) {
    if (member) {
      weakSelf.teamMember = member;
      if (completion) {
        completion(member, nil);
      }
    } else if (completion) {
      completion(member, error);
    }
  }];
}

- (void)getTeamWithMembers:(NSString *)teamId completion:(void (^)(NSError * _Nullable))completion {
  if (self.isRequestData) {
    return;
  }
  self.isRequestData = YES;

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                  completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (error) {
      weakSelf.isRequestData = NO;
      if (completion) {
        completion(error);
      }
      return;
    }

    NSMutableArray<V2NIMTeamMember *> *memberList = [NSMutableArray array];
    [weakSelf getAllTeamManagers:teamId
                       nextToken:nil
                      memberList:memberList
                       queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_MANAGER
                      completion:^(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable memberError) {
      weakSelf.isRequestData = NO;
      if (memberError) {
        if (completion) {
          completion(memberError);
        }
        return;
      }

      NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
      model.team = team;
      weakSelf.teamInfoModel = model;
      [weakSelf.managerUsers removeAllObjects];
      for (V2NIMTeamMember *member in members) {
        if (member.memberRole != V2NIM_TEAM_MEMBER_ROLE_OWNER) {
          [weakSelf.managerUsers addObject:member];
        }
      }
      [weakSelf.sectionData removeAllObjects];
      [weakSelf getSectionData];
      if (completion) {
        completion(nil);
      }
    }];
  }];
}

- (SettingSectionModel *)getFirstSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  __weak typeof(self) weakSelf = self;

  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  SettingCellLabelArrowModel *manager = [[SettingCellLabelArrowModel alloc] init];
  manager.cellName = NETeamUIKitLocalizable(@"manage_manger");
  manager.type = SettingCellTypeSettingArrowCell;
  manager.rowHeight = 56.0;
  manager.arrowLabelText = [NSString stringWithFormat:@"%lu", (unsigned long)self.managerUsers.count];
  manager.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didManagerClick)]) {
      [weakSelf.delegate didManagerClick];
    }
  };
  [model.cellModels addObject:manager];
  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getSecondSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  __weak typeof(self) weakSelf = self;

  SettingSectionModel *model = [[SettingSectionModel alloc] init];

  SettingCellModel *editTeamPermission = [[SettingCellModel alloc] init];
  editTeamPermission.cellName = NETeamUIKitLocalizable(@"who_edit_team_info");
  editTeamPermission.type = SettingCellTypeSettingSelectCell;
  editTeamPermission.rowHeight = 73.0;
  if (self.teamInfoModel.team.updateInfoMode == V2NIM_TEAM_UPDATE_INFO_MODE_ALL) {
    editTeamPermission.subTitle = NETeamUIKitLocalizable(@"team_all");
  } else {
    editTeamPermission.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
  }
  editTeamPermission.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didUpdateTeamInfoClick:)]) {
      [weakSelf.delegate didUpdateTeamInfoClick:editTeamPermission];
    }
  };

  SettingCellModel *invitePermission = [[SettingCellModel alloc] init];
  invitePermission.cellName = NETeamUIKitLocalizable(@"who_edit_user_info");
  invitePermission.type = SettingCellTypeSettingSelectCell;
  invitePermission.rowHeight = 73.0;
  if (self.teamInfoModel.team.inviteMode == V2NIM_TEAM_INVITE_MODE_ALL) {
    invitePermission.subTitle = NETeamUIKitLocalizable(@"team_all");
  } else {
    invitePermission.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
  }
  invitePermission.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didChangeInviteModeClick:)]) {
      [weakSelf.delegate didChangeInviteModeClick:invitePermission];
    }
  };

  SettingCellModel *atAllPermission = [[SettingCellModel alloc] init];
  atAllPermission.cellName = NETeamUIKitLocalizable(@"who_at_all");
  atAllPermission.type = SettingCellTypeSettingSelectCell;
  atAllPermission.rowHeight = 73.0;
  atAllPermission.subTitle = [self getTeamAtAllPermissionValue];
  atAllPermission.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didAtPermissionClick:)]) {
      [weakSelf.delegate didAtPermissionClick:atAllPermission];
    }
  };

  [model.cellModels addObjectsFromArray:@[ editTeamPermission, invitePermission, atAllPermission ]];

  if ([IMKitConfigCenter shared].enableTopMessage) {
    SettingCellModel *topMessagePermission = [[SettingCellModel alloc] init];
    topMessagePermission.cellName = NETeamUIKitLocalizable(@"who_can_top_message");
    topMessagePermission.type = SettingCellTypeSettingSelectCell;
    topMessagePermission.rowHeight = 73.0;
    topMessagePermission.subTitle = [self getTeamTopMessagePermissionValue];
    topMessagePermission.cellClick = ^{
      if ([weakSelf.delegate respondsToSelector:@selector(didTopMessagePermissionClick:)]) {
        [weakSelf.delegate didTopMessagePermissionClick:topMessagePermission];
      }
    };
    [model.cellModels addObject:topMessagePermission];
  }

  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getThirdSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  __weak typeof(self) weakSelf = self;

  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  if ([IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) {
    SettingCellModel *joinTeamNeedAgree = [[SettingCellModel alloc] init];
    joinTeamNeedAgree.cellName = NETeamUIKitLocalizable(@"invitation_acceptance_requirement");
    joinTeamNeedAgree.type = SettingCellTypeSettingSubtitleSelectCell;
    joinTeamNeedAgree.rowHeight = 73.0;
    joinTeamNeedAgree.subTitle = NETeamUIKitLocalizable(@"invitation_acceptance_requirement_desc");
    joinTeamNeedAgree.switchOpen = self.teamInfoModel.team.agreeMode == V2NIM_TEAM_AGREE_MODE_AUTH;
    joinTeamNeedAgree.swichChange = ^(BOOL isOpen) {
      if ([weakSelf.delegate respondsToSelector:@selector(didJoinTeamNeedAgreeClick:isOpen:)]) {
        [weakSelf.delegate didJoinTeamNeedAgreeClick:joinTeamNeedAgree isOpen:isOpen];
      }
    };
    [model.cellModels addObject:joinTeamNeedAgree];

    SettingCellModel *joinTeamNeedVerification = [[SettingCellModel alloc] init];
    joinTeamNeedVerification.cellName = NETeamUIKitLocalizable(@"require_verification_to_join");
    joinTeamNeedVerification.type = SettingCellTypeSettingSubtitleSelectCell;
    joinTeamNeedVerification.rowHeight = 73.0;
    joinTeamNeedVerification.subTitle = NETeamUIKitLocalizable(@"require_verification_to_join_desc");
    joinTeamNeedVerification.switchOpen = self.teamInfoModel.team.joinMode == V2NIM_TEAM_JOIN_MODE_APPLY;
    joinTeamNeedVerification.swichChange = ^(BOOL isOpen) {
      if ([weakSelf.delegate respondsToSelector:@selector(didJoinTeamNeedVerificationClick:isOpen:)]) {
        [weakSelf.delegate didJoinTeamNeedVerificationClick:joinTeamNeedVerification isOpen:isOpen];
      }
    };
    [model.cellModels addObject:joinTeamNeedVerification];
  }

  [model setCornerType];
  return model;
}

- (void)updateTeamAtAllPermission:(BOOL)isManager completion:(void (^)(NSError * _Nullable))completion {
  NSString *value = isManager ? allowAtManagerValue : allowAtAllValue;
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                  completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(error);
      }
      return;
    }

    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (team.serverExtension.length > 0) {
      NSDictionary *json = [NECommonUtil getDictionaryFromJSONString:team.serverExtension];
      if ([json isKindOfClass:[NSDictionary class]]) {
        [dic addEntriesFromDictionary:json];
      }
    }
    dic[keyAllowAtAll] = value;
    dic[@"lastOpt"] = keyAllowAtAll;
    NSString *info = [NECommonUtil getJSONStringFromDictionary:dic];
    [weakSelf.teamRepo updateTeamExtension:teamId
                                  teamType:V2NIM_TEAM_TYPE_NORMAL
                                       ext:info
                                      mode:nil
                                completion:^(NSError * _Nullable updateError) {
      if (completion) {
        completion(updateError);
      }
    }];
  }];
}

- (NSString *)getTeamAtAllPermissionValue {
  NSString *custom = self.teamInfoModel.team.serverExtension ?: @"";
  if (custom.length > 0) {
    NSDictionary *dic = [NECommonUtil getDictionaryFromJSONString:custom];
    NSString *value = [dic isKindOfClass:[NSDictionary class]] ? dic[keyAllowAtAll] : nil;
    if ([value isEqualToString:allowAtManagerValue]) {
      return NETeamUIKitLocalizable(@"team_owner_and_manager");
    }
  }
  return NETeamUIKitLocalizable(@"team_all");
}

- (NSString *)getTeamTopMessagePermissionValue {
  NSString *custom = self.teamInfoModel.team.serverExtension ?: @"";
  if (custom.length > 0) {
    NSDictionary *dic = [NECommonUtil getDictionaryFromJSONString:custom];
    NSString *value = [dic isKindOfClass:[NSDictionary class]] ? dic[keyAllowTopMessage] : nil;
    if ([value isEqualToString:allowAtAllValue]) {
      return NETeamUIKitLocalizable(@"team_all");
    }
  }
  return NETeamUIKitLocalizable(@"team_owner_and_manager");
}

- (void)updateTeamTopMessagePermission:(BOOL)isManager completion:(void (^)(NSError * _Nullable))completion {
  NSString *value = isManager ? allowAtManagerValue : allowAtAllValue;
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId
                    teamType:V2NIM_TEAM_TYPE_NORMAL
                  completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(error);
      }
      return;
    }

    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (team.serverExtension.length > 0) {
      NSDictionary *json = [NECommonUtil getDictionaryFromJSONString:team.serverExtension];
      if ([json isKindOfClass:[NSDictionary class]]) {
        [dic addEntriesFromDictionary:json];
      }
    }
    dic[keyAllowTopMessage] = value;
    dic[@"lastOpt"] = keyAllowTopMessage;
    NSString *info = [NECommonUtil getJSONStringFromDictionary:dic];
    [weakSelf.teamRepo updateTeamExtension:teamId
                                  teamType:V2NIM_TEAM_TYPE_NORMAL
                                       ext:info
                                      mode:@(V2NIM_TEAM_UPDATE_EXTENSION_MODE_ALL)
                                completion:^(NSError * _Nullable updateError) {
      if (completion) {
        completion(updateError);
      }
    }];
  }];
}

- (void)updateTeamAgreeMode:(BOOL)isNeedAgree completion:(void (^)(NSError * _Nullable))completion {
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }
  V2NIMTeamAgreeMode value = isNeedAgree ? V2NIM_TEAM_AGREE_MODE_AUTH : V2NIM_TEAM_AGREE_MODE_NO_AUTH;
  [self.teamRepo updateTeamAgreeMode:teamId
                            teamType:V2NIM_TEAM_TYPE_NORMAL
                                mode:value
                          completion:^(NSError * _Nullable error, __unused V2NIMTeam * _Nullable team) {
    if (completion) {
      completion(error);
    }
  }];
}

- (void)updateTeamJoinMode:(BOOL)isNeedAgree completion:(void (^)(NSError * _Nullable))completion {
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }
  V2NIMTeamJoinMode value = isNeedAgree ? V2NIM_TEAM_JOIN_MODE_APPLY : V2NIM_TEAM_JOIN_MODE_FREE;
  [self.teamRepo updateTeamJoinMode:teamId
                           teamType:V2NIM_TEAM_TYPE_NORMAL
                               mode:value
                         completion:^(NSError * _Nullable error, __unused V2NIMTeam * _Nullable team) {
    if (completion) {
      completion(error);
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

- (void)onTeamInfoUpdated:(V2NIMTeam *)team {
  [self updateTeamInfo:team.teamId ?: @""];
}

- (void)updateTeamInfoPrivilege:(NSString *)teamId
                           mode:(V2NIMTeamUpdateInfoMode)mode
                     completion:(void (^)(NSError * _Nullable, V2NIMTeam * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, mode:%ld", NSStringFromSelector(_cmd), (long)mode]];
  [self.teamRepo updateTeamInfoMode:teamId
                           teamType:V2NIM_TEAM_TYPE_NORMAL
                               mode:mode
                         completion:completion];
}

- (void)updateInviteMode:(NSString *)teamId
                    mode:(V2NIMTeamInviteMode)mode
              completion:(void (^)(NSError * _Nullable, V2NIMTeam * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, mode:%ld", NSStringFromSelector(_cmd), (long)mode]];
  [self.teamRepo updateInviteMode:teamId
                         teamType:V2NIM_TEAM_TYPE_NORMAL
                             mode:mode
                       completion:completion];
}

- (void)updateTeamInfo:(NSString *)teamId {
  NSString *currentTeamId = self.teamInfoModel.team.teamId ?: @"";
  if (currentTeamId.length <= 0 || ![currentTeamId isEqualToString:teamId]) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self getTeamWithMembers:teamId completion:^(NSError * _Nullable error) {
    if (!error && [weakSelf.delegate respondsToSelector:@selector(didRefreshData)]) {
      [weakSelf.delegate didRefreshData];
    }
  }];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members {
  BOOL isCurrentTeam = NO;
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  NSString *account = [IMKitClient instance].account ?: @"";

  for (V2NIMTeamMember *member in members) {
    if (teamId.length > 0 && [teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
    }
    if (account.length > 0 && [member.accountId isEqualToString:account]) {
      self.teamMember = member;
    }
  }

  if (isCurrentTeam && teamId.length > 0) {
    [self updateTeamInfo:teamId];
  }
}

- (void)getAllTeamManagers:(NSString *)teamId
                 nextToken:(NSString *)nextToken
                memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                 queryType:(V2NIMTeamMemberRoleQueryType)queryType
                completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable, NSError * _Nullable))completion {
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
      [weakSelf getAllTeamManagers:teamId
                         nextToken:result.nextToken
                        memberList:memberList
                         queryType:queryType
                        completion:completion];
    }
  }];
}

@end
