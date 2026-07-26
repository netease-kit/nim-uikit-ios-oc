// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamJoinActionViewModel.h"
#import <NEChatKit/NEChatKitOC.h>
#import "ContactConst.h"
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/ChatConstant.h>

@interface TeamJoinActionViewModel () <NETeamListener>
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) NSInteger pageMaxLimit;
@end

@implementation TeamJoinActionViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _teamJoinActions = [NSMutableArray array];
    _offset = 0;
    _finished = NO;
    _pageMaxLimit = 100;
    [_teamRepo addTeamListener:self];
  }
  return self;
}

- (void)dealloc {
  [_teamRepo removeTeamListener:self];
}

- (void)loadTeamJoinActionList:(BOOL)firstLoad completion:(void (^)(NSError *_Nullable))completion {
  NSInteger offset = firstLoad ? 0 : self.offset;
  if (firstLoad) {
    self.finished = NO;
    [self.teamJoinActions removeAllObjects];
  }

  if (self.finished) {
    completion(nil);
    return;
  }

  V2NIMTeamJoinActionInfoQueryOption *option = [[V2NIMTeamJoinActionInfoQueryOption alloc] init];
  option.offset = offset;
  option.limit = self.pageMaxLimit;

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamJoinActionInfoList:option completion:^(V2NIMTeamJoinActionInfoResult *_Nullable result, NSError *_Nullable error) {
    if (error) {
      completion(error);
    } else if (result) {
      weakSelf.offset = result.offset;
      weakSelf.finished = result.finished;
      for (V2NIMTeamJoinActionInfo *item in result.infos ?: @[]) {
        [weakSelf convertToNETeamJoinAction:item move:NO completion:^(NSError *_Nullable err) {}];
      }
      [weakSelf loadTeamJoinActionList:NO completion:completion];
    }
  }];
}

- (void)convertToNETeamJoinAction:(V2NIMTeamJoinActionInfo *)item
                              move:(BOOL)move
                        completion:(void (^)(NSError *_Nullable))completion {
  BOOL isExist = NO;
  for (NSInteger index = 0; index < (NSInteger)self.teamJoinActions.count; index++) {
    NETeamJoinAction *neItem = self.teamJoinActions[index];
    if ([neItem isEqualTo:item]) {
      isExist = YES;
      if (item.timestamp > neTeamJoinActionReadTime) {
        neItem.unreadCount += 1;
      }
      if (move && index != 0) {
        [self.teamJoinActions removeObjectAtIndex:index];
        [self.teamJoinActions insertObject:neItem atIndex:0];
      }
      [self.delegate tableviewReload];
      break;
    }
  }

  if (isExist) {
    completion(nil);
    return;
  }

  NETeamJoinAction *teamJoinActionInfo = [[NETeamJoinAction alloc] initWithActionInfo:item];
  NSInteger teamJoinActionsCount = (NSInteger)self.teamJoinActions.count;
  NSInteger insertIndex = move ? 0 : (self.teamJoinActions.count == 0 ? 0 : teamJoinActionsCount);
  [self.teamJoinActions insertObject:teamJoinActionInfo atIndex:insertIndex];

  NSString *teamId = teamJoinActionInfo.nimTeamJoinAction.teamId;
  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam *_Nullable team, NSError *_Nullable error) {
    teamJoinActionInfo.displayTeam = team;
    NSString *teamName = team.name ?: teamId;
    switch (teamJoinActionInfo.nimTeamJoinAction.actionType) {
      case V2NIM_TEAM_JOIN_ACTION_TYPE_APPLICATION:
        teamJoinActionInfo.detail = [NSString stringWithFormat:@"%@ %@", contactLocalizable(@"apply_to_the_team_of"), teamName];
        break;
      case V2NIM_TEAM_JOIN_ACTION_TYPE_INVITATION:
        teamJoinActionInfo.detail = [NSString stringWithFormat:@"%@ %@", contactLocalizable(@"invite_to_join_the_team_of"), teamName];
        break;
      case V2NIM_TEAM_JOIN_ACTION_TYPE_REJECT_APPLICATION:
        teamJoinActionInfo.detail = [NSString stringWithFormat:@"%@ %@", contactLocalizable(@"rejected_the_apply"), teamName];
        break;
      case V2NIM_TEAM_JOIN_ACTION_TYPE_REJECT_INVITATION:
        teamJoinActionInfo.detail = [NSString stringWithFormat:@"%@ %@", contactLocalizable(@"refused_the_invitation"), teamName];
        break;
      default:
        teamJoinActionInfo.detail = @"";
        break;
    }
    [weakSelf.delegate tableviewReload];
  }];

  // 查询操作者信息
  [[ContactRepo shared] getUserWithFriend:@[teamJoinActionInfo.displayUserId] completion:^(NSArray<NEUserWithFriend *> *_Nullable users, NSError *_Nullable error) {
    NEUserWithFriend *user = users.firstObject;
    if (user) {
      teamJoinActionInfo.displayUserWithFriend = user;
      [weakSelf.delegate tableviewReload];
    }
  }];
}

- (void)setTeamJoinActionRead {
  neTeamJoinActionReadTime = [[NSDate date] timeIntervalSince1970];
  [[NSUserDefaults standardUserDefaults] setValue:@(neTeamJoinActionReadTime) forKey:keyTeamJoinActionReadTime];
  for (NETeamJoinAction *application in self.teamJoinActions) {
    application.unreadCount = 0;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationClearValidationMessageUnreadCount object:nil];
  });
}

- (void)changeTeamJoinActionStatus:(V2NIMTeamJoinActionInfo *)action
                            status:(V2NIMTeamJoinActionStatus)status {
  NSInteger changedIndex = -1;
  for (NSInteger index = 0; index < (NSInteger)self.teamJoinActions.count; index++) {
    NETeamJoinAction *item = self.teamJoinActions[index];
    if ([item isEqualTo:action compareStatus:NO]) {
      item.handleStatus = status;
      item.unreadCount = 0;
      changedIndex = index;
      break;
    }
  }

  if (changedIndex > -1) {
    NSInteger index = changedIndex + 1;
    while (index < (NSInteger)self.teamJoinActions.count) {
      if ([self.teamJoinActions[index] isEqualTo:action compareStatus:YES]) {
        [self.teamJoinActions removeObjectAtIndex:index];
      } else {
        index++;
      }
    }
  }
}

- (void)agreeRequest:(V2NIMTeamJoinActionInfo *)action
          completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  if (action.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_APPLICATION) {
    [self.teamRepo acceptJoinApplication:action completion:^(NSError *_Nullable error) {
      if (error) {
        NSLog(@"%@", error.localizedDescription);
      } else {
        [weakSelf changeTeamJoinActionStatus:action status:V2NIM_TEAM_JOIN_ACTION_STATUS_AGREED];
      }
      completion(error);
    }];
  } else if (action.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_INVITATION) {
    [self.teamRepo acceptInvitation:action completion:^(V2NIMTeam *_Nullable team, NSError *_Nullable error) {
      if (error) {
        NSLog(@"%@", error.localizedDescription);
      } else {
        [weakSelf changeTeamJoinActionStatus:action status:V2NIM_TEAM_JOIN_ACTION_STATUS_AGREED];
      }
      completion(error);
    }];
  }
}

- (void)refuseRequest:(V2NIMTeamJoinActionInfo *)action
           completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  if (action.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_APPLICATION) {
    [self.teamRepo rejectJoinApplication:action postscript:nil completion:^(NSError *_Nullable error) {
      if (error) {
        NSLog(@"%@", error.localizedDescription);
      } else {
        [weakSelf changeTeamJoinActionStatus:action status:V2NIM_TEAM_JOIN_ACTION_STATUS_REJECTED];
      }
      completion(error);
    }];
  } else if (action.actionType == V2NIM_TEAM_JOIN_ACTION_TYPE_INVITATION) {
    [self.teamRepo rejectInvitation:action postscript:nil completion:^(NSError *_Nullable error) {
      if (error) {
        NSLog(@"%@", error.localizedDescription);
      } else {
        [weakSelf changeTeamJoinActionStatus:action status:V2NIM_TEAM_JOIN_ACTION_STATUS_REJECTED];
      }
      completion(error);
    }];
  }
}

- (void)clearNotification:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [self.teamRepo clearAllTeamJoinActionInfo:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    }
    [weakSelf.teamJoinActions removeAllObjects];
    completion(error);
  }];
}

#pragma mark - NETeamListener

- (void)onReceive:(V2NIMTeamJoinActionInfo *)joinActionInfo {
  [self convertToNETeamJoinAction:joinActionInfo move:YES completion:^(NSError *_Nullable error) {}];
}

@end
