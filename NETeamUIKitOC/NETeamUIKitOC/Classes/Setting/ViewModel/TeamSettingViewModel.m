// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingViewModel.h"
#import "TeamConstant.h"
#import "SettingCellModel.h"
#import "SettingSectionModel.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatUIKitOC/NEChatUIConstant.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NECommonUtil.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@implementation TeamSettingViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _sectionData = [NSMutableArray array];
    _teamRepo = [TeamRepo shared];
    _contactRepo = [ContactRepo shared];
    _teamSettingType = TeamSettingTypeDiscuss;
    _conversationRepo = [ConversationRepo shared];
    _localConversationRepo = [LocalConversationRepo shared];
    _allMembersDic = [NSMutableDictionary dictionary];
    [_teamRepo addTeamListener:self];
    if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
      [_localConversationRepo addLocalConversationListener:self];
    } else {
      [_conversationRepo addConversationListener:self];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didTapHeader:)
                                                 name:NENotificationDidTapHeader
                                               object:nil];
    NETeamInfoModel *teamInfo = [[NETeamInfoModel alloc] init];
    teamInfo.team = [[NETeamUserManager shared] getTeamInfo];
    _teamInfoModel = teamInfo;
  }
  return self;
}

- (void)dealloc {
  [self clear];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didTapHeader:(NSNotification *)notification {
  if (![notification.object isKindOfClass:[NEUserWithFriend class]]) {
    return;
  }
  NEUserWithFriend *user = (NEUserWithFriend *)notification.object;
  NSString *accid = user.user.accountId ?: @"";
  if (accid.length <= 0 || ![[NETeamUserManager shared] isCurrentMember:accid]) {
    return;
  }

  BOOL isDidFind = NO;
  NSArray<NETeamMemberInfoModel *> *userSnapshot = [self.teamInfoModel.users copy];
  for (NETeamMemberInfoModel *model in userSnapshot) {
    NSString *accountId = model.nimUser.user.accountId ?: @"";
    if ([accountId isEqualToString:accid]) {
      model.nimUser = user;
      isDidFind = YES;
    }
  }
  if (isDidFind && [self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
    [self.delegate didNeedRefreshUI];
  }
}

- (void)clear {
  [self.teamRepo removeTeamListener:self];
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo removeLocalConversationListener:self];
  } else {
    [self.conversationRepo removeConversationListener:self];
  }
}

- (void)getData {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  [self.sectionData removeAllObjects];
  [self.sectionData addObject:[self getTwoSection]];
  V2NIMTeamType type = self.teamInfoModel.team.teamType;
  if (type == V2NIM_TEAM_TYPE_NORMAL) {
    if ([self.teamInfoModel.team.serverExtension containsString:discussTeamKey]) {
      return;
    }
    [self.sectionData addObject:[self getThreeSection]];
  }
}

- (SettingSectionModel *)getOneSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  SettingCellModel *cellModel = [[SettingCellModel alloc] init];
  cellModel.type = SettingCellTypeSettingHeaderCell;
  cellModel.rowHeight = 160.0;
  cellModel.cornerType = CornerTypeTopLeft | CornerTypeTopRight | CornerTypeBottomLeft | CornerTypeBottomRight;
  [model.cellModels addObject:cellModel];
  return model;
}

- (SettingSectionModel *)getTwoSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  __weak typeof(self) weakSelf = self;

  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  if ([IMKitConfigCenter shared].enablePinMessage) {
    SettingCellModel *mark = [[SettingCellModel alloc] init];
    mark.cellName = NETeamUIKitLocalizable(@"mark");
    mark.type = SettingCellTypeSettingArrowCell;
    mark.cellClick = ^{
      if ([weakSelf.delegate respondsToSelector:@selector(didClickMark)]) {
        [weakSelf.delegate didClickMark];
      }
    };
    [model.cellModels addObject:mark];
  }

  SettingCellModel *history = [[SettingCellModel alloc] init];
  history.cellName = chatLocalizable(@"historical_record");
  history.type = SettingCellTypeSettingArrowCell;
  history.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didClickHistoryMessage)]) {
      [weakSelf.delegate didClickHistoryMessage];
    }
  };
  [model.cellModels addObject:history];

  SettingCellModel *remind = [[SettingCellModel alloc] init];
  remind.cellName = NETeamUIKitLocalizable(@"message_remind");
  remind.type = SettingCellTypeSettingSwitchCell;
  NSString *teamId = weakSelf.teamInfoModel.team.teamId ?: @"";
  if (teamId.length > 0) {
    V2NIMTeamMessageMuteMode mode = [self.teamRepo getTeamMuteStatus:teamId teamType:V2NIM_TEAM_TYPE_NORMAL];
    if (mode == V2NIM_TEAM_MESSAGE_MUTE_MODE_OFF) {
      remind.switchOpen = YES;
    }
  }
  remind.swichChange = ^(BOOL isOpen) {
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      remind.switchOpen = !isOpen;
      if ([weakSelf.delegate respondsToSelector:@selector(didShowNoNetworkToast)]) {
        [weakSelf.delegate didShowNoNetworkToast];
      }
      if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
        [weakSelf.delegate didNeedRefreshUI];
      }
      return;
    }

    NSString *tid = weakSelf.teamInfoModel.team.teamId ?: @"";
    if (tid.length <= 0) {
      return;
    }
    if (isOpen) {
      [weakSelf.teamRepo setTeamMuteStatus:tid
                                  teamType:V2NIM_TEAM_TYPE_NORMAL
                                  muteMode:V2NIM_TEAM_MESSAGE_MUTE_MODE_OFF
                                completion:^(NSError * _Nullable error) {
        if (error) {
          if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
            [weakSelf.delegate didNeedRefreshUI];
          }
          if ([weakSelf.delegate respondsToSelector:@selector(didError:)]) {
            [weakSelf.delegate didError:error];
          }
        } else {
          remind.switchOpen = NO;
        }
      }];
    } else {
      [weakSelf.teamRepo setTeamMuteStatus:tid
                                  teamType:V2NIM_TEAM_TYPE_NORMAL
                                  muteMode:V2NIM_TEAM_MESSAGE_MUTE_MODE_ON
                                completion:^(NSError * _Nullable error) {
        if (error) {
          if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
            [weakSelf.delegate didNeedRefreshUI];
          }
          if ([weakSelf.delegate respondsToSelector:@selector(didError:)]) {
            [weakSelf.delegate didError:error];
          }
        } else {
          remind.switchOpen = YES;
        }
      }];
    }
  };
  [model.cellModels addObject:remind];

  SettingCellModel *setTop = [[SettingCellModel alloc] init];
  setTop.cellName = NETeamUIKitLocalizable(@"session_set_top");
  setTop.type = SettingCellTypeSettingSwitchCell;
  setTop.switchOpen = self.conversation.stickTop;
  setTop.swichChange = ^(BOOL isOpen) {
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      setTop.switchOpen = !isOpen;
      if ([weakSelf.delegate respondsToSelector:@selector(didShowNoNetworkToast)]) {
        [weakSelf.delegate didShowNoNetworkToast];
      }
      if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
        [weakSelf.delegate didNeedRefreshUI];
      }
      return;
    }

    NSString *teamId = weakSelf.teamInfoModel.team.teamId ?: @"";
    NSString *conversationId = teamId.length > 0 ? [V2NIMConversationIdUtil teamConversationId:teamId] : nil;
    if (conversationId.length <= 0) {
      return;
    }

    void (^completion)(NSError * _Nullable) = ^(NSError * _Nullable error) {
      [NEALog infoLog:[TeamSettingViewModel className]
                 desc:[NSString stringWithFormat:@"%@%@ error : %@",
                       NSStringFromSelector(_cmd),
                       isOpen ? @"addStickTop" : @"removeStickTop",
                       error.localizedDescription ?: @""]];
      if (error) {
        if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [weakSelf.delegate didNeedRefreshUI];
        }
        if ([weakSelf.delegate respondsToSelector:@selector(didError:)]) {
          [weakSelf.delegate didError:error];
        }
      } else {
        setTop.switchOpen = isOpen;
      }
    };

    if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
      [weakSelf.localConversationRepo setStickTop:conversationId stickTop:isOpen completion:completion];
    } else {
      [weakSelf.conversationRepo setStickTop:conversationId stickTop:isOpen completion:completion];
    }
  };
  [model.cellModels addObject:setTop];

  if (![self isNormalTeam]) {
    SettingCellModel *nick = [[SettingCellModel alloc] init];
    nick.cellName = NETeamUIKitLocalizable(@"team_nick");
    nick.type = SettingCellTypeSettingArrowCell;
    nick.cellClick = ^{
      if ([weakSelf.delegate respondsToSelector:@selector(didClickChangeNick)]) {
        [weakSelf.delegate didClickChangeNick];
      }
    };
    [model.cellModels addObject:nick];
  }

  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getThreeSection {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  __weak typeof(self) weakSelf = self;

  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  SettingCellModel *forbiddenWords = [[SettingCellModel alloc] init];
  forbiddenWords.cellName = NETeamUIKitLocalizable(@"team_no_speak");
  forbiddenWords.type = SettingCellTypeSettingSwitchCell;
  V2NIMTeamChatBannedMode bannedMode = self.teamInfoModel.team.chatBannedMode;
  forbiddenWords.switchOpen = bannedMode == V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_ALL ||
                              bannedMode == V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_NORMAL;
  forbiddenWords.swichChange = ^(BOOL isOpen) {
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      forbiddenWords.switchOpen = !isOpen;
      if ([weakSelf.delegate respondsToSelector:@selector(didShowNoNetworkToast)]) {
        [weakSelf.delegate didShowNoNetworkToast];
      }
      if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
        [weakSelf.delegate didNeedRefreshUI];
      }
      return;
    }

    NSString *teamId = weakSelf.teamInfoModel.team.teamId ?: @"";
    if (teamId.length <= 0) {
      return;
    }
    [weakSelf.teamRepo setTeamChatBannedMode:teamId
                                    teamType:V2NIM_TEAM_TYPE_NORMAL
                              chatBannedMode:isOpen ? V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_NORMAL : V2NIM_TEAM_CHAT_BANNED_MODE_NONE
                                  completion:^(NSError * _Nullable error) {
      if (error) {
        forbiddenWords.switchOpen = !isOpen;
        if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [weakSelf.delegate didNeedRefreshUI];
        }
        if ([weakSelf.delegate respondsToSelector:@selector(didError:)]) {
          [weakSelf.delegate didError:error];
        }
      } else {
        forbiddenWords.switchOpen = isOpen;
      }
    }];
  };

  SettingCellModel *teamManager = [[SettingCellModel alloc] init];
  teamManager.cellName = NETeamUIKitLocalizable(@"manage_team");
  teamManager.type = SettingCellTypeSettingArrowCell;
  teamManager.cellClick = ^{
    if ([weakSelf.delegate respondsToSelector:@selector(didClickTeamManage)]) {
      [weakSelf.delegate didClickTeamManage];
    }
  };

  if ([self isOwner]) {
    [model.cellModels addObject:forbiddenWords];
  }
  if ([self isOwner] || [self isManager]) {
    [model.cellModels addObject:teamManager];
  }
  [model setCornerType];
  return model;
}

- (void)getTeamWithMembers:(NSString *)teamId completion:(void (^)(NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamId:%@", NSStringFromSelector(_cmd), teamId]];
  __weak typeof(self) weakSelf = self;
  if (self.isRequestSettingData) {
    return;
  }

  [NEALog infoLog:[NSString stringWithFormat:@"%@ [Performance]", [self className]]
             desc:[NSString stringWithFormat:@"%@ first page start, timestamp: %f", NSStringFromSelector(_cmd), [NSDate date].timeIntervalSince1970]];
  [self getTeamInfoWithSomeMembers:teamId completion:^(NSError * _Nullable error, __unused NSNumber * _Nullable finished) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ [Performance]", [TeamSettingViewModel className]]
               desc:[NSString stringWithFormat:@"%@ first page onSuccess, timestamp: %f", NSStringFromSelector(_cmd), [NSDate date].timeIntervalSince1970]];
    weakSelf.isRequestSettingData = NO;
    if (!error) {
      [weakSelf getData];
    }
    if (completion) {
      completion(error);
    }
  }];
}

- (void)getTeamWithMembers:(NSString *)teamId :(void (^)(NSError * _Nullable))completion {
  [self getTeamWithMembers:teamId completion:completion];
}

- (void)getAllTeamMemberInfos:(NSString *)teamId
                    queryType:(V2NIMTeamMemberRoleQueryType)queryType
                   completion:(void (^)(NSError * _Nullable))completion {
  (void)teamId;
  (void)queryType;
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamid:%@", NSStringFromSelector(_cmd), teamId]];
  if ([[NETeamUserManager shared] getAllTeamMemberModels] != nil) {
    [NEALog infoLog:[self className] desc:@"load team member from cache success."];
    if (completion) {
      completion(nil);
    }
  }
}

- (void)getAllTeamMemberInfos:(NSString *)teamId
                             :(V2NIMTeamMemberRoleQueryType)queryType
                             :(void (^)(NSError * _Nullable))completion {
  [self getAllTeamMemberInfos:teamId queryType:queryType completion:completion];
}

- (void)getTeamInfoWithSomeMembers:(NSString *)teamId
                        completion:(void (^)(NSError * _Nullable, NSNumber * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamId:%@", NSStringFromSelector(_cmd), teamId]];
  __weak typeof(self) weakSelf = self;

  NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
  if (conversationId.length <= 0) {
    return;
  }

  void (^loadTeamInfo)(void) = ^{
    [weakSelf.teamRepo getTeamInfo:teamId
                          teamType:V2NIM_TEAM_TYPE_NORMAL
                        completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
      if (error) {
        if (completion) {
          completion(error, @NO);
        }
        return;
      }

      NETeamInfoModel *teamInfo = [[NETeamInfoModel alloc] init];
      teamInfo.team = team;
      weakSelf.teamInfoModel = teamInfo;

      V2NIMTeamMemberQueryOption *option = [[V2NIMTeamMemberQueryOption alloc] init];
      option.nextToken = @"";
      option.limit = 20;
      option.direction = V2NIM_QUERY_DIRECTION_ASC;
      option.onlyChatBanned = NO;
      option.roleQueryType = V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL;
      [weakSelf.teamRepo getTeamMemberList:teamId
                                  teamType:V2NIM_TEAM_TYPE_NORMAL
                               queryOption:option
                                completion:^(V2NIMTeamMemberListResult * _Nullable result, NSError * _Nullable memberError) {
        if (memberError) {
          if (completion) {
            completion(memberError, result ? @(result.finished) : nil);
          }
          return;
        }

        NSArray<V2NIMTeamMember *> *members = result.memberList;
        if (members.count <= 0) {
          if (completion) {
            completion(nil, result ? @(result.finished) : nil);
          }
          return;
        }

        [weakSelf getUserInfo:members completion:^(NSError * _Nullable infoError, NSArray<NETeamMemberInfoModel *> * _Nullable models) {
          if (infoError) {
            if (completion) {
              completion(infoError, result ? @(result.finished) : nil);
            }
            return;
          }
          if (models) {
            weakSelf.teamInfoModel.users = [models mutableCopy];
          }
          if (completion) {
            completion(nil, result ? @(result.finished) : nil);
          }
        }];
      }];
    }];
  };

  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo getConversation:conversationId completion:^(V2NIMLocalConversation * _Nullable conversation, NSError * _Nullable error) {
      if (!error) {
        weakSelf.conversation = conversation;
      }
      loadTeamInfo();
    }];
  } else {
    [self.conversationRepo getConversation:conversationId completion:^(V2NIMConversation * _Nullable conversation, NSError * _Nullable error) {
      if (!error) {
        weakSelf.conversation = conversation;
      }
      loadTeamInfo();
    }];
  }
}

- (void)getUserInfo:(NSArray<V2NIMTeamMember *> *)members
         completion:(void (^)(NSError * _Nullable, NSArray<NETeamMemberInfoModel *> * _Nullable))completion {
  NSMutableArray<NSString *> *accids = [NSMutableArray array];
  NSMutableArray<NETeamMemberInfoModel *> *memberModels = [NSMutableArray array];
  for (V2NIMTeamMember *member in members) {
    if (member.accountId.length > 0) {
      [accids addObject:member.accountId];
    }
    NETeamMemberInfoModel *model = [[NETeamMemberInfoModel alloc] init];
    model.teamMember = member;
    [memberModels addObject:model];
  }

  [self.contactRepo getUserWithFriend:accids completion:^(NSArray<NEUserWithFriend *> * _Nullable users, NSError * _Nullable error) {
    if (error) {
      if (completion) {
        completion(nil, memberModels);
      }
      return;
    }

    NSMutableDictionary<NSString *, NEUserWithFriend *> *dic = [NSMutableDictionary dictionary];
    for (NEUserWithFriend *user in users) {
      NSString *accountId = user.user.accountId ?: @"";
      if (accountId.length > 0) {
        dic[accountId] = user;
      }
    }
    for (NETeamMemberInfoModel *model in memberModels) {
      NSString *accountId = model.teamMember.accountId ?: @"";
      if (accountId.length > 0 && dic[accountId]) {
        model.nimUser = dic[accountId];
      }
    }
    if (completion) {
      completion(nil, memberModels);
    }
  }];
}

- (void)getUserInfo:(NSArray<V2NIMTeamMember *> *)members
                    :(void (^)(NSError * _Nullable, NSArray<NETeamMemberInfoModel *> * _Nullable))completion {
  [self getUserInfo:members completion:completion];
}

- (void)dismissTeam:(NSString *)teamId completion:(void (^)(NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamId:%@", NSStringFromSelector(_cmd), teamId]];
  [self.teamRepo dismissTeam:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:completion];
}

- (void)dismissTeam:(NSString *)teamId :(void (^)(NSError * _Nullable))completion {
  [self dismissTeam:teamId completion:completion];
}

- (void)leaveTeam:(NSString *)teamId completion:(void (^)(NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamId:%@", NSStringFromSelector(_cmd), teamId]];
  [self.teamRepo leaveTeam:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:completion];
}

- (void)leaveTeam:(NSString *)teamId :(void (^)(NSError * _Nullable))completion {
  [self leaveTeam:teamId completion:completion];
}

- (void)removeStickTop:(void (^)(NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  NSString *conversationId = teamId.length > 0 ? [V2NIMConversationIdUtil teamConversationId:teamId] : nil;
  if (conversationId.length <= 0) {
    return;
  }

  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo setStickTop:conversationId stickTop:YES completion:completion];
  } else {
    [self.conversationRepo setStickTop:conversationId stickTop:YES completion:completion];
  }
}

- (void)getCurrentMember:(NSString *)userId
                  teamId:(NSString *)teamId
              completion:(void (^)(V2NIMTeamMember * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, userId:%@", NSStringFromSelector(_cmd), userId]];
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
      weakSelf.memberInTeam = member;
      if (completion) {
        completion(member, nil);
      }
    } else if (completion) {
      completion(member, error);
    }
  }];
}

- (void)getCurrentMember:(NSString *)userId
                        :(NSString *)teamId
              completion:(void (^)(V2NIMTeamMember * _Nullable, NSError * _Nullable))completion {
  [self getCurrentMember:userId teamId:teamId completion:completion];
}

- (BOOL)isOwner {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  return [[NETeamUserManager shared] isOwner:[IMKitClient instance].account];
}

- (BOOL)isManager {
  return self.memberInTeam.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER;
}

- (NSString *)sampleMemberId:(NSArray<NETeamMemberInfoModel *> *)arr owner:(NSString *)owner {
  NSArray<NETeamMemberInfoModel *> *sortedArr = [arr sortedArrayUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time1 < time2) return NSOrderedAscending;
    if (time1 > time2) return NSOrderedDescending;
    return NSOrderedSame;
  }];

  for (NETeamMemberInfoModel *model in sortedArr) {
    NSString *accid = model.teamMember.accountId ?: @"";
    if (accid.length > 0 &&
        ![accid isEqualToString:owner] &&
        ![[NEAIUserManager shared] isAIUser:accid]) {
      return accid;
    }
  }
  return owner;
}

- (NSString *)sampleMemberIdWithArr:(NSArray<NETeamMemberInfoModel *> *)arr owner:(NSString *)owner {
  return [self sampleMemberId:arr owner:owner];
}

- (void)transferTeamOwner:(void (^)(NSError * _Nullable))completion {
  if (![self isOwner]) {
    if (completion) {
      completion([NSError errorWithDomain:@"imuikit"
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"not team manager"}]);
    }
    return;
  }

  NSMutableArray<NETeamMemberInfoModel *> *members = [self.teamInfoModel.users mutableCopy];
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (members.count <= 0 || teamId.length <= 0) {
    if (completion) {
      completion([NSError errorWithDomain:@"imuikit"
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"team info error"}]);
    }
    return;
  }

  NSIndexSet *aiIndexes = [members indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
    NSString *accountId = obj.nimUser.user.accountId ?: @"";
    return accountId.length > 0 && [[NEAIUserManager shared] isAIUser:accountId];
  }];
  [members removeObjectsAtIndexes:aiIndexes];

  NSString *userId = [IMKitClient instance].account ?: @"";
  if (members.count == 1) {
    [self dismissTeam:teamId completion:completion];
    return;
  }

  NSString *sampleOwnerId = [self sampleMemberId:members owner:userId];
  if (sampleOwnerId.length > 0) {
    userId = sampleOwnerId;
  }
  if ([userId isEqualToString:[IMKitClient instance].account]) {
    [self dismissTeam:teamId completion:completion];
    return;
  }

  [self.teamRepo transferTeam:teamId
                     teamType:V2NIM_TEAM_TYPE_NORMAL
                      account:userId
                         quit:YES
                   completion:completion];
}

- (BOOL)isNormalTeam {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:NSStringFromSelector(_cmd)];
  return [self.teamInfoModel.team.serverExtension containsString:discussTeamKey];
}

- (void)onTeamInfoUpdated:(V2NIMTeam *)team {
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length > 0 && [teamId isEqualToString:team.teamId]) {
    self.teamInfoModel.team = team;
    [self getData];
    if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
      [self.delegate didNeedRefreshUI];
    }
  }
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

- (void)onTeamSyncFinished {
  [NEALog infoLog:[self className]
             desc:[NSString stringWithFormat:@"%@ team setting viewmo model onTeamSyncFinished ", NSStringFromSelector(_cmd)]];
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self getCurrentMember:[IMKitClient instance].account
                  teamId:teamId
              completion:^(__unused V2NIMTeamMember * _Nullable member, __unused NSError * _Nullable error) {
    [weakSelf getTeamInfoWithSomeMembers:teamId completion:^(NSError * _Nullable infoError, __unused NSNumber * _Nullable finished) {
      if (!infoError) {
        [weakSelf getData];
        if ([weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [weakSelf.delegate didNeedRefreshUI];
        }
      }
    }];
  }];
}

- (void)onTeamMemberInfoUpdated:(NSArray<V2NIMTeamMember *> *)teamMembers {
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  NSString *account = [IMKitClient instance].account ?: @"";
  for (V2NIMTeamMember *member in teamMembers) {
    if (teamId.length > 0 &&
        [teamId isEqualToString:member.teamId] &&
        account.length > 0 &&
        [member.accountId isEqualToString:account]) {
      self.memberInTeam = member;
      break;
    }
  }
  [self onTeamMemberChanged:teamMembers];
}

- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked {
  (void)team;
  (void)isKicked;
}

- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members {
  BOOL isCurrentTeam = NO;
  NSString *teamId = self.teamInfoModel.team.teamId ?: @"";
  NSString *account = [IMKitClient instance].account ?: @"";

  for (V2NIMTeamMember *member in members) {
    if (teamId.length > 0 && [teamId isEqualToString:member.teamId]) {
      isCurrentTeam = YES;
    }
    if (account.length > 0 && [member.accountId isEqualToString:account] && teamId.length > 0) {
      [self getCurrentMember:account
                      teamId:teamId
                  completion:^(__unused V2NIMTeamMember * _Nullable memberInfo, __unused NSError * _Nullable error) {
      }];
    }
  }

  if (isCurrentTeam && teamId.length > 0) {
    __weak typeof(self) weakSelf = self;
    [self getTeamWithMembers:teamId completion:^(NSError * _Nullable error) {
      if (!error && [weakSelf.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
        [weakSelf.delegate didNeedRefreshUI];
      }
    }];
  }
}

- (void)inviteUsers:(NSArray<NSString *> *)members
             teamId:(NSString *)teamId
         completion:(void (^)(NSError * _Nullable, NSArray<V2NIMTeamMember *> * _Nullable))completion {
  [self.teamRepo inviteTeamMembers:teamId
                          teamType:V2NIM_TEAM_TYPE_NORMAL
                           members:members
                        completion:completion];
}

- (void)inviteUsers:(NSArray<NSString *> *)members
                   :(NSString *)teamId
                   :(void (^)(NSError * _Nullable, NSArray<V2NIMTeamMember *> * _Nullable))completion {
  [self inviteUsers:members teamId:teamId completion:completion];
}

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  NSString *currentConversationId = self.conversation.conversationId ?: @"";
  if (currentConversationId.length <= 0) {
    return;
  }
  for (V2NIMConversation *conversation in conversations) {
    if ([currentConversationId isEqualToString:conversation.conversationId]) {
      BOOL didChangeStickTop = self.conversation.stickTop != conversation.stickTop;
      self.conversation = conversation;
      if (didChangeStickTop) {
        [self getData];
        if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [self.delegate didNeedRefreshUI];
        }
      }
      break;
    }
  }
}

- (void)onLocalConversationChanged:(NSArray<V2NIMLocalConversation *> *)conversations {
  NSString *currentConversationId = self.conversation.conversationId ?: @"";
  if (currentConversationId.length <= 0) {
    return;
  }
  for (V2NIMLocalConversation *conversation in conversations) {
    if ([currentConversationId isEqualToString:conversation.conversationId]) {
      BOOL didChangeStickTop = self.conversation.stickTop != conversation.stickTop;
      self.conversation = conversation;
      if (didChangeStickTop) {
        [self getData];
        if ([self.delegate respondsToSelector:@selector(didNeedRefreshUI)]) {
          [self.delegate didNeedRefreshUI];
        }
      }
      break;
    }
  }
}

@end
