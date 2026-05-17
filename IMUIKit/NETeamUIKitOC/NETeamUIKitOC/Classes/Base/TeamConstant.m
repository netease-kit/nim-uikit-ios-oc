// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamConstant.h"
#import "NETeamLoader.h"
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

NSString *const NETeamUIKitModuleName = @"NETeamUIKit";
NSNotificationName const NETeamUIKitLeaveTeamBySelfNotification = @"team.leaveTeamBySelf";
NSNotificationName const NETeamUIKitPopGroupChatVCNotification = @"team.popGroupChatVC";

NECommonLoader *NETeamUIKitLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NETeamLoader class]];
  });
  return loader;
}

NSString *NETeamUIKitLocalizable(NSString *key) {
  return [NETeamUIKitLoader() localizable:key];
}

NSString *NETeamUIKitErrorToast(NSError *error) {
  if (!error) {
    return commonLocalizable(@"failed_operation");
  }

  NSInteger code = error.code;
  if (code == protocolSendFailed) {
    return commonLocalizable(@"network_error");
  } else if (code == teamNotExistCode) {
    return commonLocalizable(@"team_not_exist");
  } else if (code == noPermissionCode ||
             code == noPermissionInviteCode ||
             code == noPermissionOperationCode) {
    return NETeamUIKitLocalizable(@"no_permission_tip");
  } else if (code == teamMemberLimitExceededCode) {
    return NETeamUIKitLocalizable(@"team_member_limit_exceeded");
  } else if (code == joinedTeamLimitExceededCode) {
    return NETeamUIKitLocalizable(@"joined_team_limit_exceeded");
  } else if (code == alreadyInTeamCode) {
    return NETeamUIKitLocalizable(@"already_in_the_team");
  } else if (code == invitationExpiredCode) {
    return NETeamUIKitLocalizable(@"invitation_expired");
  } else if (code == teamMemberNotExist) {
    return commonLocalizable(@"team_member_not_exist");
  }

  return commonLocalizable(@"failed_operation");
}
