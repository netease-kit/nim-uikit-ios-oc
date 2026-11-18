// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamJoinAction.h"
#import "ContactConst.h"
#import <NEChatKit/ChatConstant.h>

NSTimeInterval neTeamJoinActionReadTime = 0;
NSInteger neTeamJoinActionPageLimit = 100;

__attribute__((constructor))
static void _initTeamJoinActionReadTime(void) {
  neTeamJoinActionReadTime = [[NSUserDefaults standardUserDefaults] doubleForKey:keyTeamJoinActionReadTime];
}

@implementation NETeamJoinAction

- (instancetype)initWithActionInfo:(V2NIMTeamJoinActionInfo *)info {
  self = [super init];
  if (self) {
    _nimTeamJoinAction = info;
    _displayUserId = info.operatorAccountId;
    _handleStatus = info.actionStatus;
    _unreadCount = info.timestamp > neTeamJoinActionReadTime ? 1 : 0;
    _detail = contactLocalizable(@"add_request");
  }
  return self;
}

- (instancetype)init:(V2NIMTeamJoinActionInfo *)info {
  return [self initWithActionInfo:info];
}

- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti
     compareStatus:(BOOL)compareStatus {
  if ([self.nimTeamJoinAction.operatorAccountId isEqualToString:noti.operatorAccountId] &&
      [self.nimTeamJoinAction.teamId isEqualToString:noti.teamId] &&
      self.nimTeamJoinAction.actionType == noti.actionType) {
    if (compareStatus) {
      return self.handleStatus == noti.actionStatus;
    }
    return YES;
  }
  return NO;
}

- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti :(BOOL)compareStatus {
  return [self isEqualTo:noti compareStatus:compareStatus];
}

- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti {
  return [self isEqualTo:noti compareStatus:YES];
}

@end
