// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NotificationMessageUtils.h"
#import "NETeamUserManager.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatKit.h>

#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NIMSDK/NIMSDK.h>

static NSString *const kKeyAllowAtAll = @"yxAllowAt";
static NSString *const kKeyAllowTopMessage = @"yxAllowTop";
static NSString *const kKeyTopMessage = @"yxMessageTop";
static NSString *const kAllowAtAllValue = @"all";
static NSString *const kAllowAtManagerValue = @"manager";

@interface NENotificationTeamStateResult (NEChatUIKitInternal)
- (instancetype)initWithIsLeave:(BOOL)isLeave isDismiss:(BOOL)isDismiss;
@end

@implementation NotificationMessageUtils

+ (NSString *)textForNotification:(V2NIMMessage *)message {
  if (message.messageType != V2NIM_MESSAGE_TYPE_NOTIFICATION) {
    return @"";
  }
  if ([message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    return [self textForTeamNotificationMessage:message];
  } else {
    return [[self fromName:message] stringByAppendingString:message.text ?: @""];
  }
}

+ (NSString *)textForNotificationWithMessage:(V2NIMMessage *)message {
  return [self textForNotification:message];
}

+ (TeamType)teamTypeWithMessage:(V2NIMMessage *)message {
  (void)message;
  V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
  return [team ne_isDisscuss] ? TeamTypeDiscussTeam : TeamTypeAdvanceTeam;
}

+ (BOOL)isDiscussSeniorTeamNoti:(V2NIMMessage *)message {
  return [message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]];
}

+ (BOOL)isTeamLeave:(V2NIMMessage *)message {
  if ([message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)message.attachment;
    return content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE;
  }
  return NO;
}

+ (BOOL)isTeamDismiss:(V2NIMMessage *)message {
  if ([message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)message.attachment;
    return content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS;
  }
  return NO;
}

+ (NENotificationTeamStateResult *)teamLeaveOrDismissResult:(V2NIMMessage *)message {
  return [[NENotificationTeamStateResult alloc] initWithIsLeave:[self isTeamLeave:message]
                                                     isDismiss:[self isTeamDismiss:message]];
}

+ (NSString *)textForTeamNotificationMessage:(V2NIMMessage *)message {
  NSString *text = chatLocalizable(@"unknown_system_message");
  if (![message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    return text;
  }

  V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)message.attachment;
  NSString *fName = [self fromName:message];
  NSArray<NSString *> *toNames = [self toName:message];
  NSString *tName = [self teamName:message];
  NSString *groupChat = commonLocalizable(@"group_chat");

  NSString *toNamesText = @"";
  if (toNames.count == 1) {
    toNamesText = [NSString stringWithFormat:@"\"%@\"", toNames.firstObject ?: @""];
  } else if (toNames.count > 1) {
    toNamesText = [NSString stringWithFormat:@"\"%@\"", [toNames componentsJoinedByString:@"、"]];
  }

  switch (content.type) {
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE:
      text = [NSString stringWithFormat:@"%@%@%@%@%@", fName, chatLocalizable(@"invite"), toNamesText, chatLocalizable(@"enter"), groupChat];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS:
      text = [NSString stringWithFormat:@"%@%@%@", fName, chatLocalizable(@"dissolve"), groupChat];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_KICK:
      text = [NSString stringWithFormat:@"%@%@%@%@%@", fName, chatLocalizable(@"kick"), toNamesText, chatLocalizable(@"out"), groupChat];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_UPDATE_TINFO:
      text = [self textOfUpdateTeamWithFromName:fName teamName:tName content:content];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE:
      text = [NSString stringWithFormat:@"%@%@%@", fName, chatLocalizable(@"leave"), groupChat];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_APPLY_PASS:
      if (content.targetIds.count == 1 && [content.targetIds.firstObject isEqualToString:message.senderId]) {
        text = [NSString stringWithFormat:@"%@%@%@", fName, chatLocalizable(@"join"), groupChat];
      } else {
        text = [NSString stringWithFormat:@"%@%@", toNamesText, chatLocalizable(@"team_apply")];
      }
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_OWNER_TRANSFER:
      text = [NSString stringWithFormat:@"%@%@%@", fName, chatLocalizable(@"transfer"), toNamesText];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_ADD_MANAGER:
      text = [NSString stringWithFormat:@"%@%@", toNamesText, chatLocalizable(@"added_manager")];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_REMOVE_MANAGER:
      text = [NSString stringWithFormat:@"%@%@", toNamesText, chatLocalizable(@"removed_manager")];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE_ACCEPT:
      text = [NSString stringWithFormat:@"%@%@%@%@", fName, chatLocalizable(@"pass"), toNamesText, chatLocalizable(@"team_invitation")];
      break;
    case V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_BANNED_TEAM_MEMBER:
      text = [NSString stringWithFormat:@"%@ %@", toNamesText, content.chatBanned ? chatLocalizable(@"mute") : chatLocalizable(@"not_mute")];
      break;
    default:
      text = chatLocalizable(@"unknown_system_message");
      break;
  }
  return text;
}

+ (NSString *)fromName:(V2NIMMessage *)message {
  NSString *sourceId = message.senderId;
  if (sourceId) {
    if ([sourceId isEqualToString:[[IMKitClient instance] account]]) {
      return chatLocalizable(@"You");
    } else {
      return [NSString stringWithFormat:@"\"%@\"", [[NETeamUserManager shared] getShowName:sourceId]];
    }
  }
  return @"";
}

+ (NSArray<NSString *> *)toName:(V2NIMMessage *)message {
  NSMutableArray<NSString *> *toNames = [NSMutableArray array];
  if (![message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    return toNames;
  }

  V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)message.attachment;
  NSArray<NSString *> *targetIDs = content.targetIds;
  if (!targetIDs) return toNames;

  for (NSString *targetID in targetIDs) {
    if ([targetID isEqualToString:[[IMKitClient instance] account]]) {
      [toNames addObject:chatLocalizable(@"You")];
    } else {
      [toNames addObject:[[NETeamUserManager shared] getShowName:targetID]];
    }
  }
  return toNames;
}

+ (NSString *)teamName:(V2NIMMessage *)message {
  switch ([self teamTypeWithMessage:message]) {
    case TeamTypeDiscussTeam:
    case TeamTypeAdvanceTeam:
      return commonLocalizable(@"team_group");
  }
}

#pragma mark - Update Team Info Text

+ (NSString *)textOfUpdateTeamWithFromName:(NSString *)fromName
                                  teamName:(NSString *)teamName
                                   content:(V2NIMMessageNotificationAttachment *)content {
  NSString *text = [NSString stringWithFormat:@"%@%@%@", fromName, chatLocalizable(@"has_updated"), teamName];

  V2NIMUpdatedTeamInfo *updatedTeamInfo = content.updatedTeamInfo;
  if (!updatedTeamInfo) return text;

  // Team name
  if (updatedTeamInfo.name) {
    return [NSString stringWithFormat:@"%@%@%@%@%@\"%@\"",
            fromName, chatLocalizable(@"has_updated"), teamName,
            chatLocalizable(@"team_name"), chatLocalizable(@"to"), updatedTeamInfo.name];
  }

  // Team intro
  if (updatedTeamInfo.intro) {
    return [NSString stringWithFormat:@"%@%@%@%@",
            fromName, chatLocalizable(@"has_updated"), teamName, chatLocalizable(@"team_intro")];
  }

  // Team announcement
  if (updatedTeamInfo.announcement) {
    return [NSString stringWithFormat:@"%@%@%@%@",
            fromName, chatLocalizable(@"has_updated"), teamName, chatLocalizable(@"team_anouncement")];
  }

  // Team avatar
  if (updatedTeamInfo.avatar) {
    return [NSString stringWithFormat:@"%@%@%@%@",
            fromName, chatLocalizable(@"has_updated"), teamName, chatLocalizable(@"team_avatar")];
  }

  // Join mode
  if ((NSInteger)updatedTeamInfo.joinMode != -1) {
    NSString *modeStr = (updatedTeamInfo.joinMode == V2NIM_TEAM_JOIN_MODE_APPLY) ?
      chatLocalizable(@"has_open") : chatLocalizable(@"has_closed");
    return [NSString stringWithFormat:@"%@%@%@", fromName, modeStr, chatLocalizable(@"team_join_mode")];
  }

  // Agree mode
  if ((NSInteger)updatedTeamInfo.agreeMode != -1) {
    NSString *modeStr = (updatedTeamInfo.agreeMode == V2NIM_TEAM_AGREE_MODE_AUTH) ?
      chatLocalizable(@"has_open") : chatLocalizable(@"has_closed");
    return [NSString stringWithFormat:@"%@%@%@", fromName, modeStr, chatLocalizable(@"team_agree_mode")];
  }

  // Invite mode
  if ((NSInteger)updatedTeamInfo.inviteMode != -1) {
    NSString *inviteModeStr = (updatedTeamInfo.inviteMode == V2NIM_TEAM_INVITE_MODE_MANAGER) ?
      chatLocalizable(@"only_team_owner") : chatLocalizable(@"user_select_all");
    return [NSString stringWithFormat:@"%@%@%@ \"%@\" %@\"%@\"",
            fromName, chatLocalizable(@"has_updated"), chatLocalizable(@"team_permission"),
            chatLocalizable(@"team_be_invited_permission"), chatLocalizable(@"to"), inviteModeStr];
  }

  // Update info mode
  if ((NSInteger)updatedTeamInfo.updateInfoMode != -1) {
    NSString *updateModeStr = (updatedTeamInfo.updateInfoMode == V2NIM_TEAM_UPDATE_INFO_MODE_MANAGER) ?
      chatLocalizable(@"only_team_owner") : chatLocalizable(@"user_select_all");
    return [NSString stringWithFormat:@"%@%@%@ \"%@\" %@\"%@\"",
            fromName, chatLocalizable(@"has_updated"), chatLocalizable(@"team_permission"),
            chatLocalizable(@"team_update_info_permission"), chatLocalizable(@"to"), updateModeStr];
  }

  // Chat banned mode
  if ((NSInteger)updatedTeamInfo.chatBannedMode != -1) {
    return (updatedTeamInfo.chatBannedMode == V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_NORMAL) ?
      chatLocalizable(@"team_all_mute") : chatLocalizable(@"team_all_no_mute");
  }

  // Server extension
  NSString *serverExt = updatedTeamInfo.serverExtension;
  if (serverExt) {
    NSData *data = [serverExt dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *extDic = nil;
    if (data) {
      extDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    if (extDic && [extDic isKindOfClass:[NSDictionary class]]) {
      NSString *lastOpt = kKeyAllowAtAll;
      if (extDic[@"lastOpt"]) {
        lastOpt = extDic[@"lastOpt"];
      }

      // @all permission
      if ([lastOpt isEqualToString:kKeyAllowAtAll]) {
        NSString *allowAt = extDic[kKeyAllowAtAll];
        if ([allowAt isEqualToString:kAllowAtManagerValue]) {
          return [NSString stringWithFormat:@"%@%@", chatLocalizable(@"team_at_permission"), chatLocalizable(@"only_team_owner")];
        }
        if ([allowAt isEqualToString:kAllowAtAllValue]) {
          return [NSString stringWithFormat:@"%@%@", chatLocalizable(@"team_at_permission"), chatLocalizable(@"everyone")];
        }
      }

      // Top message permission
      if ([lastOpt isEqualToString:kKeyAllowTopMessage]) {
        NSString *allowTop = extDic[kKeyAllowTopMessage];
        if ([allowTop isEqualToString:kAllowAtManagerValue]) {
          return [NSString stringWithFormat:@"%@%@", chatLocalizable(@"team_top_permission"), chatLocalizable(@"only_team_owner")];
        }
        if ([allowTop isEqualToString:kAllowAtAllValue]) {
          return [NSString stringWithFormat:@"%@%@", chatLocalizable(@"team_top_permission"), chatLocalizable(@"everyone")];
        }
      }

      // Top message
      if ([lastOpt isEqualToString:kKeyTopMessage]) {
        NSDictionary *topInfo = extDic[kKeyTopMessage];
        if ([topInfo isKindOfClass:[NSDictionary class]]) {
          NSNumber *typeNum = topInfo[@"operation"];
          if (typeNum) {
            NSString *opStr = (typeNum.intValue == 0) ? chatLocalizable(@"top_message") : chatLocalizable(@"untop_message");
            return [NSString stringWithFormat:@"%@%@", fromName, opStr];
          }
        }
      }
    } else {
      return [NSString stringWithFormat:@"%@%@%@", fromName, chatLocalizable(@"has_updated"), chatLocalizable(@"team_custom_info")];
    }
  }

  // Update extension mode
  if ((NSInteger)updatedTeamInfo.updateExtensionMode != -1) {
    return [NSString stringWithFormat:@"%@%@%@", fromName, chatLocalizable(@"has_updated"), chatLocalizable(@"team_update_client_custom")];
  }

  return text;
}

+ (NSString *)textOfUpdateTeamFromName:(NSString *)fromName
                               teamName:(NSString *)teamName
                                content:(V2NIMMessageNotificationAttachment *)content {
  return [self textOfUpdateTeamWithFromName:fromName teamName:teamName content:content];
}

@end
