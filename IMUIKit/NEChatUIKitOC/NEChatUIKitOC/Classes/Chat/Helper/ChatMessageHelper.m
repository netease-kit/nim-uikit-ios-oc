
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NECustomUtils.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import "NEEmotionTool.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/NSObject+YXModel.h>
#import <NEChatKitOC/NEPathUtils.h>
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "MessageTextModel.h"
#import "MessageAIStreamModel.h"
#import "MessageImageModel.h"
#import "MessageAudioModel.h"
#import "MessageVideoModel.h"
#import "MessageFileModel.h"
#import "MessageLocationModel.h"
#import "MessageCallRecordModel.h"
#import "MessageTipsModel.h"
#import "MessageRichTextModel.h"
#import "MessageCustomModel.h"
#import "MessageAtInfoModel.h"
#import "NETeamUserManager.h"
#import "NEP2PChatUserCache.h"
#import "NEChatUIKitClient.h"
#import "NotificationMessageUtils.h"
#import "NEEmotionAttachment.h"

// ── AI error-code constants (mirrors Swift numeric values) ────────────
static const NSInteger kFailedOperation            = 414;
static const NSInteger kRateLimitExceeded          = 416;
static const NSInteger kUserNotExistCode           = 102404;
static const NSInteger kUserBannedCode             = 102422;
static const NSInteger kUserChatBannedCode         = 102421;
static const NSInteger kNoFriendCode               = 104404;
static const NSInteger kMessageHitAntispam1        = 107451;
static const NSInteger kMessageHitAntispam2        = 189451;
static const NSInteger kTeamMemberNotExist         = 109404;
static const NSInteger kTeamNormalMemberChatBanned = 108306;
static const NSInteger kTeamMemberChatBanned       = 109424;
static const NSInteger kNotAIAccount               = 102304;
static const NSInteger kCannotBlockAIAccount       = 106403;
static const NSInteger kAIMessagesDisabled         = 107337;
static const NSInteger kAIMessageRequestFailed     = 189308;
static const NSInteger kAIMessageNotSupport        = 107336;

// ── serverExtension key constants ────────────────────────────────────
static NSString *const kYxAtMsg             = @"yxAitMsg";
static NSString *const kAtSegmentsKey       = @"segments";
static NSString *const kKeyReplyMsgKey      = @"yxReplyMsg";
static NSString *const kRevokeLocalMessage  = @"revoke_message_local";
static NSString *const kRevokeLocalMsgTime  = @"revoke_message_local_time";
static NSString *const kRevokeLocalMsgContent = @"revoke_message_local_content";
static NSString *const kMergedMessageNickKey   = @"mergedMessageNickKey";
static NSString *const kMergedMessageAvatarKey = @"mergedMessageAvatarKey";
static const NSInteger kAtRangeOffset       = 1;

// ── imkit directory ──────────────────────────────────────────────────
static NSString *const kImkitDir = @"NEIMUIKit/";

static Class NEChatResolveCellClass(NSString *className) {
  Class cellClass = NSClassFromString(className);
  if (cellClass && [cellClass isSubclassOfClass:[UITableViewCell class]]) {
    return cellClass;
  }
  return Nil;
}

static void NEChatSetThreadReply(V2NIMMessage *message, V2NIMMessageRefer *threadReply) {
  SEL selector = NSSelectorFromString(@"setThreadReply:");
  if (![message respondsToSelector:selector]) {
    return;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [message performSelector:selector withObject:threadReply];
#pragma clang diagnostic pop
}

static NSString *NEChatStringValue(NSDictionary<NSString *, id> *params, NSString *key) {
  id value = params[key];
  return [value isKindOfClass:[NSString class]] ? value : nil;
}

@implementation ChatMessageHelper

#pragma mark - Geometry

+ (CGSize)getSizeWithMaxSize:(CGSize)maxSize size:(CGSize)size miniWH:(CGFloat)miniWH {
  CGSize realSize = CGSizeZero;
  if (MIN(size.width, size.height) > 0) {
    if (size.width > size.height) {
      CGFloat width = MIN(maxSize.width, size.width);
      realSize = CGSizeMake(width, width * size.height / size.width);
      if (realSize.height < miniWH) {
        realSize.height = miniWH;
      }
    } else {
      CGFloat height = MIN(maxSize.height, size.height);
      realSize = CGSizeMake(height * size.width / size.height, height);
      if (realSize.width < miniWH) {
        realSize.width = miniWH;
      }
    }
  } else {
    realSize = maxSize;
  }
  return realSize;
}

#pragma mark - Session Name

+ (NSString *)getSessionName:(NSString *)conversationId showAlias:(BOOL)showAlias {
  NSString *sessionId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
  if (!sessionId) {
    return @"";
  }
  V2NIMConversationType convType = [V2NIMConversationIdUtil conversationType:conversationId];
  if (convType == V2NIM_CONVERSATION_TYPE_P2P) {
    NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:sessionId];
    NSString *name = [user showName:showAlias];
    return name ?: sessionId;
  } else {
    V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
    return team.name ?: sessionId;
  }
}

#pragma mark - Cell Registration Dictionaries

+ (NSDictionary<NSString *, Class> *)getChatCellRegisterDic:(BOOL)isFun {
  Class (^cls)(NSString *, NSString *) = ^Class(NSString *normal, NSString *fun) {
    return NEChatResolveCellClass(isFun ? fun : normal);
  };
  NSMutableDictionary<NSString *, Class> *registerDic = [NSMutableDictionary dictionary];
  Class cellClass = Nil;

  cellClass = cls(@"ChatMessageTextCell", @"FunChatMessageTextCell");
  if (cellClass) registerDic[@(MessageTypeText).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageAIStreamTextCell", @"FunChatMessageAIStreamTextCell");
  if (cellClass) registerDic[@(MessageTypeAIStreamText).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageCallCell", @"FunChatMessageCallCell");
  if (cellClass) registerDic[@(MessageTypeRtcCallRecord).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageAudioCell", @"FunChatMessageAudioCell");
  if (cellClass) registerDic[@(MessageTypeAudio).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageImageCell", @"FunChatMessageImageCell");
  if (cellClass) registerDic[@(MessageTypeImage).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageRevokeCell", @"FunChatMessageRevokeCell");
  if (cellClass) registerDic[@(MessageTypeRevoke).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageVideoCell", @"FunChatMessageVideoCell");
  if (cellClass) registerDic[@(MessageTypeVideo).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageFileCell", @"FunChatMessageFileCell");
  if (cellClass) registerDic[@(MessageTypeFile).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageLocationCell", @"FunChatMessageLocationCell");
  if (cellClass) registerDic[@(MessageTypeLocation).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageTipCell", @"FunChatMessageTipCell");
  if (cellClass) registerDic[@(MessageTypeTime).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageMultiForwardCell", @"FunChatMessageMultiForwardCell");
  if (cellClass) registerDic[@(MessageTypeMultiForward).stringValue] = cellClass;

  cellClass = cls(@"ChatMessageRichTextCell", @"FunChatMessageRichTextCell");
  if (cellClass) registerDic[@(MessageTypeRichText).stringValue] = cellClass;

  return registerDic.copy;
}

+ (NSDictionary<NSString *, Class> *)getChatCellRegisterDicWithIsFun:(BOOL)isFun {
  return [self getChatCellRegisterDic:isFun];
}

+ (NSDictionary<NSString *, Class> *)getPinCellRegisterDic:(BOOL)isFun {
  Class (^cls)(NSString *, NSString *) = ^Class(NSString *normal, NSString *fun) {
    return NEChatResolveCellClass(isFun ? fun : normal);
  };
  NSMutableDictionary<NSString *, Class> *registerDic = [NSMutableDictionary dictionary];
  Class cellClass = Nil;

  cellClass = cls(@"PinMessageTextCell", @"FunPinMessageTextCell");
  if (cellClass) {
    registerDic[@(MessageTypeText).stringValue] = cellClass;
    registerDic[@(MessageTypeAIStreamText).stringValue] = cellClass;
  }

  cellClass = cls(@"PinMessageImageCell", @"FunPinMessageImageCell");
  if (cellClass) registerDic[@(MessageTypeImage).stringValue] = cellClass;

  cellClass = cls(@"PinMessageAudioCell", @"FunPinMessageAudioCell");
  if (cellClass) registerDic[@(MessageTypeAudio).stringValue] = cellClass;

  cellClass = cls(@"PinMessageVideoCell", @"FunPinMessageVideoCell");
  if (cellClass) registerDic[@(MessageTypeVideo).stringValue] = cellClass;

  cellClass = cls(@"PinMessageLocationCell", @"FunPinMessageLocationCell");
  if (cellClass) registerDic[@(MessageTypeLocation).stringValue] = cellClass;

  cellClass = cls(@"PinMessageFileCell", @"FunPinMessageFileCell");
  if (cellClass) registerDic[@(MessageTypeFile).stringValue] = cellClass;

  cellClass = cls(@"PinMessageMultiForwardCell", @"FunPinMessageMultiForwardCell");
  if (cellClass) registerDic[@(MessageTypeMultiForward).stringValue] = cellClass;

  cellClass = cls(@"PinMessageRichTextCell", @"FunPinMessageRichTextCell");
  if (cellClass) registerDic[@(MessageTypeRichText).stringValue] = cellClass;

  cellClass = cls(@"PinMessageDefaultCell", @"FunPinMessageDefaultCell");
  if (cellClass) registerDic[@"NEBasePinMessageTextCell"] = cellClass;

  return registerDic.copy;
}

+ (NSDictionary<NSString *, Class> *)getCollectionCellRegisterDic:(BOOL)isFun {
  Class (^cls)(NSString *, NSString *) = ^Class(NSString *normal, NSString *fun) {
    return NEChatResolveCellClass(isFun ? fun : normal);
  };
  NSMutableDictionary<NSString *, Class> *registerDic = [NSMutableDictionary dictionary];
  Class cellClass = Nil;

  cellClass = cls(@"CollectionMessageTextCell", @"FunCollectionMessageTextCell");
  if (cellClass) {
    registerDic[@(MessageTypeText).stringValue] = cellClass;
    registerDic[@(MessageTypeAIStreamText).stringValue] = cellClass;
  }

  cellClass = cls(@"CollectionMessageImageCell", @"FunCollectionMessageImageCell");
  if (cellClass) registerDic[@(MessageTypeImage).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageAudioCell", @"FunCollectionMessageAudioCell");
  if (cellClass) registerDic[@(MessageTypeAudio).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageVideoCell", @"FunCollectionMessageVideoCell");
  if (cellClass) registerDic[@(MessageTypeVideo).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageLocationCell", @"FunCollectionMessageLocationCell");
  if (cellClass) registerDic[@(MessageTypeLocation).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageFileCell", @"FunCollectionMessageFileCell");
  if (cellClass) registerDic[@(MessageTypeFile).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageMultiForwardCell", @"FunCollectionMessageMultiForwardCell");
  if (cellClass) registerDic[@(MessageTypeMultiForward).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageRichTextCell", @"FunCollectionMessageRichTextCell");
  if (cellClass) registerDic[@(MessageTypeRichText).stringValue] = cellClass;

  cellClass = cls(@"CollectionMessageDefaultCell", @"FunCollectionMessageDefaultCell");
  if (cellClass) registerDic[@"NEBasePinMessageTextCell"] = cellClass;

  cellClass = cls(@"CollectionDefaultCell", @"FunCollectionDefaultCell");
  if (cellClass) registerDic[@"NEBaseCollectionDefaultCell"] = cellClass;

  return registerDic.copy;
}

#pragma mark - Message Model Factory

+ (MessageContentModel *)modelFromMessage:(V2NIMMessage *)message {
  MessageContentModel *model;

  switch (message.messageType) {
    case V2NIM_MESSAGE_TYPE_VIDEO:
      model = [[MessageVideoModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_TEXT: {
      // 数字人回复的消息使用 Markdown 解析
      if (message.aiConfig != nil &&
          message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_RESPONSE) {
        return [[MessageAIStreamModel alloc] initWithMessage:message];
      }
      // 机器人回复的消息也使用 Markdown 解析（与数字人一致）
      if (message.senderId &&
          [[NEAIRobotManager shared] isRobot:message.senderId]) {
        return [[MessageAIStreamModel alloc] initWithMessage:message];
      }
      model = [[MessageTextModel alloc] initWithMessage:message];
      break;
    }

    case V2NIM_MESSAGE_TYPE_IMAGE:
      model = [[MessageImageModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_AUDIO:
      model = [[MessageAudioModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_NOTIFICATION:
    case V2NIM_MESSAGE_TYPE_TIP:
      model = [[MessageTipsModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_FILE:
      model = [[MessageFileModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_LOCATION:
      model = [[MessageLocationModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_CALL:
      model = [[MessageCallRecordModel alloc] initWithMessage:message];
      break;

    case V2NIM_MESSAGE_TYPE_CUSTOM: {
      NSNumber *typeNum = [NECustomUtils typeOfCustomMessage:message.attachment];
      if (typeNum != nil) {
        NSInteger type = [typeNum integerValue];
        if (type == customMultiForwardType) {
          return [[MessageCustomModel alloc] initWithMessage:message
                                                  customType:type
                                               contentHeight:(NSInteger)customMultiForwardCellHeight];
        }
        if (type == customRichTextType) {
          return [[MessageRichTextModel alloc] initWithMessage:message];
        }
        // 注册过的自定义消息类型
        NSDictionary<NSString *, Class> *registerDic = [[NEChatUIKitClient instance] getRegisterCustomCell];
        if (registerDic[[NSString stringWithFormat:@"%ld", (long)type]] != nil) {
          [NEALog infoLog:keyCustomMessage
                     desc:[NSString stringWithFormat:@"%s type: %ld, messageClientId: %@",
                           __FUNCTION__, (long)type,
                           message.messageClientId ?: @"(null)"]];
          return [[MessageCustomModel alloc] initWithMessage:message
                                                  customType:type
                                               contentHeight:(NSInteger)customMultiForwardCellHeight];
        }
      }
      // fallthrough to default
      message.text = chatLocalizable(@"msg_unknown");
      model = [[MessageTextModel alloc] initWithMessage:message];
      model.unkonwMessage = YES;
      break;
    }

    default:
      // 未识别的消息类型，默认为文本消息类型
      message.text = chatLocalizable(@"msg_unknown");
      model = [[MessageTextModel alloc] initWithMessage:message];
      model.unkonwMessage = YES;
      break;
  }

  return model;
}

+ (void)modelFromMessage:(V2NIMMessage *)message completion:(void (^)(MessageContentModel *model))completion {
  switch (message.messageType) {
    case V2NIM_MESSAGE_TYPE_VIDEO: {
      MessageContentModel *model = [[MessageVideoModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_TEXT: {
      // 数字人回复的消息使用 Markdown 解析
      if (message.aiConfig != nil &&
          message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_RESPONSE) {
        completion([[MessageAIStreamModel alloc] initWithMessage:message]);
        return;
      }
      // 机器人回复的消息也使用 Markdown 解析（与数字人一致）
      if (message.senderId &&
          [[NEAIRobotManager shared] isRobot:message.senderId]) {
        completion([[MessageAIStreamModel alloc] initWithMessage:message]);
        return;
      }
      MessageContentModel *model = [[MessageTextModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_IMAGE: {
      MessageContentModel *model = [[MessageImageModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_AUDIO: {
      MessageContentModel *model = [[MessageAudioModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_NOTIFICATION:
    case V2NIM_MESSAGE_TYPE_TIP: {
      // 查询通知消息中 targetId 的用户信息
      if (message.messageType == V2NIM_MESSAGE_TYPE_NOTIFICATION) {
        V2NIMMessageNotificationAttachment *attach =
            (V2NIMMessageNotificationAttachment *)message.attachment;
        if ([attach isKindOfClass:[V2NIMMessageNotificationAttachment class]] &&
            attach.targetIds.count > 0) {
          NSMutableArray<NSString *> *accIds = [attach.targetIds mutableCopy];
          if (message.senderId) {
            [accIds addObject:message.senderId];
          }
          [[NETeamUserManager shared] getTeamMembers:accIds
                                              notify:NO
                                          completion:^{
            completion([[MessageTipsModel alloc] initWithMessage:message]);
          }];
          return;
        }
      }
      completion([[MessageTipsModel alloc] initWithMessage:message]);
      break;
    }

    case V2NIM_MESSAGE_TYPE_FILE: {
      MessageContentModel *model = [[MessageFileModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_LOCATION: {
      MessageContentModel *model = [[MessageLocationModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_CALL: {
      MessageContentModel *model = [[MessageCallRecordModel alloc] initWithMessage:message];
      completion(model);
      break;
    }

    case V2NIM_MESSAGE_TYPE_CUSTOM: {
      NSNumber *typeNum = [NECustomUtils typeOfCustomMessage:message.attachment];
      if (typeNum != nil) {
        NSInteger type = [typeNum integerValue];
        if (type == customMultiForwardType) {
          completion([[MessageCustomModel alloc] initWithMessage:message
                                                      customType:type
                                                   contentHeight:(NSInteger)customMultiForwardCellHeight]);
          return;
        }
        if (type == customRichTextType) {
          completion([[MessageRichTextModel alloc] initWithMessage:message]);
          return;
        }
        // 注册过的自定义消息类型
        NSDictionary<NSString *, Class> *registerDic = [[NEChatUIKitClient instance] getRegisterCustomCell];
        if (registerDic[[NSString stringWithFormat:@"%ld", (long)type]] != nil) {
          [NEALog infoLog:keyCustomMessage
                     desc:[NSString stringWithFormat:@"%s type: %ld, messageClientId: %@",
                           __FUNCTION__, (long)type,
                           message.messageClientId ?: @"(null)"]];
          completion([[MessageCustomModel alloc] initWithMessage:message
                                                      customType:type
                                                   contentHeight:(NSInteger)customMultiForwardCellHeight]);
          return;
        }
      }
      // fallthrough to default
      [NEALog infoLog:NSStringFromClass([self class])
                 desc:[NSString stringWithFormat:@"%s message type unknown, messageClientId: %@",
                       __FUNCTION__,
                       message.messageClientId ?: @"(null)"]];
      message.text = chatLocalizable(@"msg_unknown");
      MessageContentModel *model = [[MessageTextModel alloc] initWithMessage:message];
      model.unkonwMessage = YES;
      completion(model);
      break;
    }

    default: {
      [NEALog infoLog:NSStringFromClass([self class])
                 desc:[NSString stringWithFormat:@"%s message type unknown, messageClientId: %@",
                       __FUNCTION__,
                       message.messageClientId ?: @"(null)"]];
      message.text = chatLocalizable(@"msg_unknown");
      MessageContentModel *model = [[MessageTextModel alloc] initWithMessage:message];
      model.unkonwMessage = YES;
      completion(model);
      break;
    }
  }
}

#pragma mark - Image URL Extraction

+ (NSArray<NSString *> *)getUrls:(nullable MessageContentModel *)current
                        messages:(NSArray<MessageContentModel *> *)messages
                     currentIndex:(NSInteger *)indexOut {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ChatUIKitModuleName, NSStringFromClass([self class])]
             desc:NSStringFromSelector(_cmd)];

  NSMutableArray<NSString *> *urls = [NSMutableArray array];
  BOOL isFound = NO;
  NSInteger currentIndex = 0;

  for (MessageContentModel *model in messages) {
    if (model.type == MessageTypeImage) {
      V2NIMMessageImageAttachment *imageAttach =
          (V2NIMMessageImageAttachment *)model.message.attachment;
      if (![imageAttach isKindOfClass:[V2NIMMessageImageAttachment class]]) {
        continue;
      }

      if (!isFound) {
        if (![model.message.messageClientId isEqualToString:current.message.messageClientId]) {
          currentIndex += 1;
        } else {
          isFound = YES;
        }
      }

      if (imageAttach.url.length > 0) {
        [urls addObject:imageAttach.url];
      } else {
        NSString *path = imageAttach.path;
        if (path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
          [urls addObject:path];
        }
      }
    }
  }

  if (indexOut) {
    *indexOut = currentIndex;
  }
  return [urls copy];
}

+ (void)getUrlsWithModel:(nullable MessageContentModel *)current
                messages:(NSArray<MessageContentModel *> *)messages
             currentIndex:(NSInteger *)indexOut
               showImages:(NSArray<NSString *> * _Nullable * _Nullable)showImagesOut {
  NSArray<NSString *> *urls = [self getUrls:current messages:messages currentIndex:indexOut];
  if (showImagesOut) {
    *showImagesOut = urls;
  }
}

#pragma mark - Time Separator

+ (void)addTimeMessage:(MessageContentModel *)model lastModel:(nullable MessageContentModel *)lastModel {
  if (!model.message) {
    [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ChatUIKitModuleName, NSStringFromClass([self class])]
                desc:[NSString stringWithFormat:@"%s, model.message is nil", __FUNCTION__]];
    return;
  }

  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ChatUIKitModuleName, NSStringFromClass([self class])]
             desc:[NSString stringWithFormat:@"%s, messageId: %@",
                   __FUNCTION__,
                   model.message.messageClientId ?: @"(null)"]];

  if ([NotificationMessageUtils isDiscussSeniorTeamNoti:model.message]) {
    return;
  }

  NSTimeInterval lastTs = lastModel.message ? lastModel.message.createTime : 0.0;
  NSTimeInterval curTs = model.message.createTime;
  NSTimeInterval dur = curTs - lastTs;

  if ((dur / 60.0) > 5.0) {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:curTs];
    NSString *timeText = [self ne_stringFromDate:date];
    model.timeContent = timeText;
  }
}

#pragma mark - Display Text

+ (NSString *)contentOfMessage:(nullable V2NIMMessage *)message {
  switch (message.messageType) {
    case V2NIM_MESSAGE_TYPE_TEXT:
      return message.text ?: chatLocalizable(@"message_not_found");

    case V2NIM_MESSAGE_TYPE_IMAGE:
      return chatLocalizable(@"msg_image");

    case V2NIM_MESSAGE_TYPE_AUDIO:
      return chatLocalizable(@"msg_audio");

    case V2NIM_MESSAGE_TYPE_VIDEO:
      return chatLocalizable(@"msg_video");

    case V2NIM_MESSAGE_TYPE_FILE:
      return chatLocalizable(@"msg_file");

    case V2NIM_MESSAGE_TYPE_LOCATION:
      return [NSString stringWithFormat:@"%@ %@",
              chatLocalizable(@"msg_location"),
              message.text ?: @""];

    case V2NIM_MESSAGE_TYPE_CALL: {
      if ([message.attachment isKindOfClass:[V2NIMMessageCallAttachment class]]) {
        V2NIMMessageCallAttachment *attach = (V2NIMMessageCallAttachment *)message.attachment;
        return attach.type == 1
               ? chatLocalizable(@"msg_rtc_audio")
               : chatLocalizable(@"msg_rtc_video");
      }
      return chatLocalizable(@"msg_rtc_call");
    }

    case V2NIM_MESSAGE_TYPE_CUSTOM: {
      // 换行消息
      NSString *richContent = [NECustomUtils contentOfRichText:message.attachment];
      if (richContent) {
        return richContent;
      }
      // 合并转发
      NSNumber *typeNum = [NECustomUtils typeOfCustomMessage:message.attachment];
      if (typeNum && [typeNum integerValue] == customMultiForwardType) {
        return [NSString stringWithFormat:@"[%@]", chatLocalizable(@"chat_history")];
      }
      return chatLocalizable(@"msg_custom");
    }

    default:
      return chatLocalizable(@"msg_unknown");
  }
}

#pragma mark - AI Error Message

+ (nullable NSString *)getAIErrorMessage:(NSInteger)errorCode {
  NSString *content = nil;
  if (errorCode == kFailedOperation) {
    content = commonLocalizable(@"parameter_setting_error");
  } else if (errorCode == kRateLimitExceeded) {
    content = commonLocalizable(@"rate_limit_exceeded");
  } else if (errorCode == kUserNotExistCode) {
    content = commonLocalizable(@"user_not_exist");
  } else if (errorCode == kUserBannedCode) {
    content = commonLocalizable(@"user_banned");
  } else if (errorCode == kUserChatBannedCode) {
    content = commonLocalizable(@"user_chat_banned");
  } else if (errorCode == kNoFriendCode) {
    content = commonLocalizable(@"friend_not_exist");
  } else if (errorCode == kMessageHitAntispam1 || errorCode == kMessageHitAntispam2) {
    content = commonLocalizable(@"message_hit_antispam");
  } else if (errorCode == kTeamMemberNotExist) {
    content = commonLocalizable(@"team_member_not_exist");
  } else if (errorCode == kTeamNormalMemberChatBanned) {
    content = commonLocalizable(@"team_normal_member_chat_banned");
  } else if (errorCode == kTeamMemberChatBanned) {
    content = commonLocalizable(@"team_member_chat_banned");
  } else if (errorCode == kNotAIAccount) {
    content = commonLocalizable(@"not_ai_account");
  } else if (errorCode == kCannotBlockAIAccount) {
    content = commonLocalizable(@"cannot_blocklist_ai_account");
  } else if (errorCode == kAIMessagesDisabled) {
    content = commonLocalizable(@"ai_messages_function_disabled");
  } else if (errorCode == kAIMessageRequestFailed) {
    content = commonLocalizable(@"failed_request_to_the_LLM");
  } else if (errorCode == kAIMessageNotSupport) {
    content = chatLocalizable(@"format_not_supported");
  }
  return content;
}

#pragma mark - Forward Message Construction

+ (void)clearForwardAtMark:(V2NIMMessage *)forwardMessage {
  NSDictionary *remoteExtDict = getDictionaryFromJSONString(forwardMessage.serverExtension ?: @"");
  if (![remoteExtDict isKindOfClass:[NSDictionary class]]) {
    return;
  }
  NSMutableDictionary *remoteExt = [remoteExtDict mutableCopy];
  [remoteExt removeObjectForKey:kYxAtMsg];
  [remoteExt removeObjectForKey:kKeyReplyMsgKey];
  forwardMessage.serverExtension = getJSONStringFromDictionary(remoteExt);
}

+ (void)clearForwardReplyMark:(V2NIMMessage *)forwardMessage {
  [ChatMessageHelper clearForwardAtMark:forwardMessage];
  NSDictionary *localExtDict = getDictionaryFromJSONString(forwardMessage.localExtension ?: @"");
  if ([localExtDict isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *localExt = [localExtDict mutableCopy];
    [localExt removeObjectForKey:kKeyReplyMsgKey];
    forwardMessage.localExtension = getJSONStringFromDictionary(localExt);
  }
  if (forwardMessage.threadReply) {
    NEChatSetThreadReply(forwardMessage, nil);
  }
}

+ (NSString *)buildHeader:(NSInteger)messageCount {
  NSMutableDictionary *dic = [NSMutableDictionary dictionary];
  dic[@"version"] = @(0);        // 功能版本
  dic[@"terminal"] = @(2);       // iOS
  dic[@"message_count"] = @(messageCount); // 转发消息数量
  return getJSONStringFromDictionary(dic);
}

+ (void)buildBody:(NSArray<V2NIMMessage *> *)messages
       completion:(void (^)(NSString *body, NSArray<NSDictionary<NSString *, id> *> *abstracts))completion {
  NSString *enter = @"\n"; // 分隔符
  NSMutableString *body = [NSMutableString string]; // 序列化结果
  NSMutableArray<NSDictionary<NSString *, id> *> *abstracts = [NSMutableArray array]; // 摘要信息

  [messages enumerateObjectsUsingBlock:^(V2NIMMessage *msg, NSUInteger i, BOOL *stop) {
    // 移除扩展字段中的 回复、@ 信息
    NSString *originalRemoteExt = msg.serverExtension;
    NSString *originalLocalExt = msg.localExtension;
    V2NIMMessageRefer *originalThreadReply = msg.threadReply;
    [ChatMessageHelper clearForwardReplyMark:msg];

    // 保存消息昵称和头像
    NSString *from = [ChatMessageHelper getSenderId:msg];
    if (from) {
      NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:from];
      if (user) {
        NSString *senderNick = [user showName:NO];
        NSDictionary *currentExt = getDictionaryFromJSONString(msg.serverExtension ?: @"");
        NSMutableDictionary *extToWrite = nil;
        if ([currentExt isKindOfClass:[NSDictionary class]]) {
          extToWrite = [currentExt mutableCopy];
        } else {
          extToWrite = [NSMutableDictionary dictionary];
        }
        extToWrite[kMergedMessageNickKey] = senderNick ?: @"";
        NSString *avatarUrl = user.user.avatar;
        if (!avatarUrl || avatarUrl.length == 0) {
          avatarUrl = [NEFriendUserCache getShortName:senderNick ?: @"" length:2];
        }
        extToWrite[kMergedMessageAvatarKey] = avatarUrl ?: @"";
        msg.serverExtension = getJSONStringFromDictionary(extToWrite);

        // 摘要信息（最多取前3条）
        if (i < 3) {
          NSString *content = [ChatMessageHelper contentOfMessage:msg];
          [abstracts addObject:@{
            @"senderNick": senderNick ?: @"",
            @"content": content ?: @"",
            @"userAccId": from,
          }];
        }
      }

      // 序列化消息
      NSString *stringData = [V2NIMMessageConverter messageSerialization:msg];
      if (stringData) {
        [body appendString:enter];
        [body appendString:stringData];
      }
    }

    // 恢复扩展字段中的 回复、@ 信息
    msg.serverExtension = originalRemoteExt;
    msg.localExtension = originalLocalExt;
    if (originalThreadReply) {
      NEChatSetThreadReply(msg, originalThreadReply);
    }
  }];

  completion([body copy], [abstracts copy]);
}

#pragma mark - Server Extension Parsing

+ (nullable NSDictionary<NSString *, id> *)getMessageServerExtension:(V2NIMMessage *)message {
  if (!message.serverExtension) {
    return nil;
  }
  NSDictionary *dict = getDictionaryFromJSONString(message.serverExtension);
  if ([dict isKindOfClass:[NSDictionary class]]) {
    return (NSDictionary<NSString *, id> *)dict;
  }
  return nil;
}

+ (BOOL)isRevokeMessage:(nullable V2NIMMessage *)message {
  if (!message) {
    return NO;
  }
  NSDictionary<NSString *, id> *localExt = [ChatMessageHelper getMessageServerExtension:message];
  if (localExt) {
    NSNumber *isRevoke = localExt[kRevokeLocalMessage];
    if ([isRevoke isKindOfClass:[NSNumber class]] && [isRevoke boolValue]) {
      return YES;
    }
  }
  return NO;
}

+ (nullable NSString *)getRevokeMessageContent:(MessageContentModel *)model {
  if (!model.message) {
    return nil;
  }
  if (model.type != MessageTypeText && model.type != MessageTypeRichText) {
    return nil;
  }
  NSDictionary<NSString *, id> *localExt = [ChatMessageHelper getMessageServerExtension:model.message];
  if (localExt) {
    NSNumber *timeNum = localExt[kRevokeLocalMsgTime];
    if ([timeNum isKindOfClass:[NSNumber class]]) {
      model.revokeTime = [timeNum doubleValue];
    }
    NSString *content = localExt[kRevokeLocalMsgContent];
    if ([content isKindOfClass:[NSString class]]) {
      return content;
    }
  }
  return nil;
}

#pragma mark - Reply Message Handling

+ (NSDictionary<NSString *, id> *)createReplyDic:(V2NIMMessageRefer *)messageRefer {
  NSMutableDictionary *yxReplyMsg = [NSMutableDictionary dictionary];
  if (messageRefer.messageClientId) {
    yxReplyMsg[@"idClient"] = messageRefer.messageClientId;
  }
  yxReplyMsg[@"scene"] = @(messageRefer.conversationType);
  if (messageRefer.senderId) {
    yxReplyMsg[@"from"] = messageRefer.senderId;
  }
  if (messageRefer.receiverId) {
    yxReplyMsg[@"receiverId"] = messageRefer.receiverId;
  }
  if (messageRefer.conversationId) {
    yxReplyMsg[@"to"] = messageRefer.conversationId;
  }
  if (messageRefer.messageServerId) {
    yxReplyMsg[@"idServer"] = messageRefer.messageServerId;
  }
  yxReplyMsg[@"time"] = @((NSInteger)(messageRefer.createTime * 1000));
  return [yxReplyMsg copy];
}

+ (V2NIMMessageRefer *)createMessageRefer:(nullable NSDictionary<NSString *, id> *)params {
  V2NIMMessageRefer *refer = [[V2NIMMessageRefer alloc] init];
  refer.messageClientId = NEChatStringValue(params, @"idClient");
  refer.messageServerId = NEChatStringValue(params, @"idServer");
  refer.senderId = NEChatStringValue(params, @"from");
  NSNumber *timeMs = params[@"time"];
  refer.createTime = [timeMs isKindOfClass:[NSNumber class]]
                     ? ([timeMs doubleValue] / 1000.0)
                     : 0.0;
  refer.conversationId = NEChatStringValue(params, @"to");
  refer.receiverId = NEChatStringValue(params, @"receiverId");
  NSNumber *sceneNum = params[@"scene"];
  if ([sceneNum isKindOfClass:[NSNumber class]]) {
    refer.conversationType = (V2NIMConversationType)[sceneNum integerValue];
  }
  return refer;
}

+ (nullable NSDictionary<NSString *, id> *)getReplyDictionary:(V2NIMMessage *)message {
  NSArray<NSString *> *extensions = @[
    message.serverExtension ?: @"",
    message.localExtension ?: @""
  ];
  for (NSString *extension in extensions) {
    NSDictionary *remoteExt = getDictionaryFromJSONString(extension);
    if (![remoteExt isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    NSDictionary *yxReplyMsg = remoteExt[kKeyReplyMsgKey];
    if ([yxReplyMsg isKindOfClass:[NSDictionary class]]) {
      return yxReplyMsg;
    }
  }
  return nil;
}

#pragma mark - Sender Utilities

+ (BOOL)isAISender:(nullable V2NIMMessage *)message {
  if (message.aiConfig != nil &&
      message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_RESPONSE) {
    return YES;
  }
  return NO;
}

+ (nullable NSString *)getSenderId:(nullable V2NIMMessage *)message {
  NSString *senderId = message.senderId;
  // 数字人回复的消息
  if ([IMKitConfigCenter shared].enableAIUser &&
      message.aiConfig != nil &&
      message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_RESPONSE) {
    senderId = message.aiConfig.accountId;
  }
  return senderId;
}

+ (BOOL)isSelf:(nullable V2NIMMessage *)message {
  NSString *senderId = [ChatMessageHelper getSenderId:message];
  NSString *account = [[IMKitClient instance] account];
  return [senderId isEqualToString:account];
}

+ (nullable NEUserWithFriend *)getUserFromCache:(NSString *)accountId {
  NEUserWithFriend *user = [[NEAIUserManager shared] getNEUserById:accountId];
  if (user) return user;
  user = [[NEFriendUserCache shared] getFriendInfo:accountId];
  if (user) return user;
  user = [[NEP2PChatUserCache shared] getUserInfo:accountId];
  if (user) return user;
  user = [[NETeamUserManager shared] getUserInfo:accountId];
  return user;
}

#pragma mark - @ and Keyword Highlighting (Private Helper)

/// 计算富文本中表情附件多占用的字符数
+ (NSInteger)getReduceIndexCount:(NSAttributedString *)attribute {
  __block NSInteger count = 0;
  [attribute enumerateAttributesInRange:NSMakeRange(0, attribute.length)
                                options:0
                             usingBlock:^(NSDictionary<NSAttributedStringKey, id> *dics,
                                          NSRange range,
                                          BOOL *stop) {
    NEEmotionAttachment *neAttachment = dics[NSAttachmentAttributeName];
    if ([neAttachment isKindOfClass:[NEEmotionAttachment class]]) {
      NSString *tag = neAttachment.emotion.tag;
      if (tag) {
        count += (NSInteger)tag.length - 1;
      }
    }
  }];
  return count;
}

#pragma mark - @ Highlighting

+ (nullable NSMutableAttributedString *)loadAtInMessage:(nullable V2NIMMessage *)message
                                           attributeStr:(nullable NSMutableAttributedString *)attributeStr {
  // 数字人回复的消息不展示高亮
  if (message.aiConfig != nil &&
      message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_RESPONSE) {
    return nil;
  }

  NSString *text = message.text ?: @"";
  BOOL isSelf = (message.isSelf == YES);
  CGFloat messageTextSize = isSelf
                            ? [ChatUIConfig shared].messageProperties.selfMessageTextSize
                            : [ChatUIConfig shared].messageProperties.receiveMessageTextSize;
  UIFont *messageTextFont = [UIFont systemFontOfSize:messageTextSize];
  UIColor *messageTextColor = isSelf
                              ? [ChatUIConfig shared].messageProperties.selfMessageTextColor
                              : [ChatUIConfig shared].messageProperties.receiveMessageTextColor;

  // 兼容老的表情消息，如果前面有表情而位置计算异常则回退回老的解析
  BOOL notFound = NO;

  NSDictionary *remoteExtDict = getDictionaryFromJSONString(message.serverExtension ?: @"");
  if (![remoteExtDict isKindOfClass:[NSDictionary class]]) {
    return attributeStr;
  }
  NSDictionary *atDic = remoteExtDict[kYxAtMsg];
  if (![atDic isKindOfClass:[NSDictionary class]]) {
    return attributeStr;
  }

  // 第一轮：根据转码后的 index 处理 @
  for (id key in atDic) {
    id value = atDic[key];
    if (![value isKindOfClass:[NSDictionary class]]) continue;
    NSDictionary *contentDic = (NSDictionary *)value;
    NSArray *array = contentDic[kAtSegmentsKey];
    if (![array isKindOfClass:[NSArray class]]) continue;

    NSArray<MessageAtInfoModel *> *models = [NSArray yx_modelArrayWithClass:[MessageAtInfoModel class]
                                                                       json:array];
    if (![models isKindOfClass:[NSArray class]]) continue;

    for (MessageAtInfoModel *model in models) {
      if (model.start < 0 || model.end < model.start ||
          model.start >= (NSInteger)text.length ||
          model.end + kAtRangeOffset > (NSInteger)text.length) {
        notFound = YES;
        break;
      }

      // 前面因为表情增加的索引数量
      NSInteger countOffset = 0;
      if (model.start > 0 && (NSInteger)text.length > model.start) {
        NSString *frontStr = [text substringToIndex:model.start];
        NSMutableAttributedString *frontAttrStr =
            [NEEmotionTool getAttWithStr:frontStr
                                    font:messageTextFont
                                   color:messageTextColor
                                  offset:CGPointZero];
        countOffset = [ChatMessageHelper getReduceIndexCount:frontAttrStr];
      }

      NSInteger start = model.start - countOffset;
      if (start < 0) {
        notFound = YES;
        break;
      }

      NSInteger rawLength = model.end - model.start + kAtRangeOffset;
      if (rawLength <= 0 || model.start + rawLength > (NSInteger)text.length) {
        notFound = YES;
        break;
      }
      NSString *rangeStr = [text substringWithRange:NSMakeRange(model.start, rawLength)];
      NSMutableAttributedString *rangeAttrStr =
          [NEEmotionTool getAttWithStr:rangeStr
                                  font:messageTextFont
                                 color:messageTextColor
                                offset:CGPointZero];
      NSInteger innerCount = [ChatMessageHelper getReduceIndexCount:rangeAttrStr];
      NSInteger end = model.end - countOffset - innerCount;
      if (end <= start) {
        notFound = YES;
        break;
      }

      NSInteger attrLength = end - start + kAtRangeOffset;
      if (attrLength > 0 && start >= 0 &&
          start + attrLength <= (NSInteger)attributeStr.length) {
        [attributeStr addAttribute:NSForegroundColorAttributeName
                             value:[UIColor ne_normalTheme]
                             range:NSMakeRange(start, attrLength)];
      }
    }

    if (notFound) break;
  }

  // 第二轮回退：直接用原始 index 处理
  if (notFound) {
    for (id key in atDic) {
      id value = atDic[key];
      if (![value isKindOfClass:[NSDictionary class]]) continue;
      NSDictionary *contentDic = (NSDictionary *)value;
      NSArray *array = contentDic[kAtSegmentsKey];
      if (![array isKindOfClass:[NSArray class]]) continue;

      NSArray<MessageAtInfoModel *> *models = [NSArray yx_modelArrayWithClass:[MessageAtInfoModel class]
                                                                         json:array];
      if (![models isKindOfClass:[NSArray class]]) continue;

      for (MessageAtInfoModel *model in models) {
        NSInteger attrLength = model.end - model.start + kAtRangeOffset;
        if (model.start >= 0 && attrLength > 0 &&
            model.start + attrLength <= (NSInteger)attributeStr.length) {
          [attributeStr addAttribute:NSForegroundColorAttributeName
                               value:[UIColor ne_normalTheme]
                               range:NSMakeRange(model.start, attrLength)];
        }
      }
    }
  }

  return attributeStr;
}

#pragma mark - Keyword Highlighting

+ (nullable NSMutableAttributedString *)loadKeywordInMessage:(nullable V2NIMMessage *)message
                                                attributeStr:(nullable NSMutableAttributedString *)attributeStr
                                                     keyword:(NSString *)keyword
                                                  themeColor:(UIColor *)themeColor {
  NSString *text = attributeStr.string ?: (message.text ?: @"");
  BOOL isSelf = (message.isSelf == YES);
  CGFloat messageTextSize = isSelf
                            ? [ChatUIConfig shared].messageProperties.selfMessageTextSize
                            : [ChatUIConfig shared].messageProperties.receiveMessageTextSize;
  UIFont *messageTextFont = [UIFont systemFontOfSize:messageTextSize];
  UIColor *messageTextColor = isSelf
                              ? [ChatUIConfig shared].messageProperties.selfMessageTextColor
                              : [ChatUIConfig shared].messageProperties.receiveMessageTextColor;

  BOOL notFound = NO;

  NSError *regexError = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:keyword
                                                                         options:0
                                                                           error:&regexError];
  if (!regex) {
    return nil;
  }

  NSArray<NSTextCheckingResult *> *matches =
      [regex matchesInString:text
                     options:0
                       range:NSMakeRange(0, [text length])];
  if (!matches || matches.count == 0) {
    return nil;
  }

  for (NSTextCheckingResult *match in matches) {
    if (match.range.location == NSNotFound) {
      continue;
    }
    NSInteger modelStart = match.range.location;
    NSInteger modelEnd = match.range.location + match.range.length;
    if (modelStart < 0 || modelEnd < modelStart || modelEnd > (NSInteger)text.length) {
      notFound = YES;
      break;
    }

    // 前面因为表情增加的索引数量
    NSInteger countOffset = 0;
    if (modelStart > 0 && (NSInteger)text.length > modelStart) {
      NSString *frontStr = [text substringToIndex:modelStart];
      NSMutableAttributedString *frontAttrStr =
          [NEEmotionTool getAttWithStr:frontStr
                                  font:messageTextFont
                                 color:messageTextColor
                                offset:CGPointZero];
      countOffset = [ChatMessageHelper getReduceIndexCount:frontAttrStr];
    }

    NSInteger start = modelStart - countOffset;
    if (start < 0) {
      notFound = YES;
      break;
    }

    NSInteger rawLength = modelEnd - modelStart;
    if (rawLength <= 0 || modelStart + rawLength > (NSInteger)text.length) {
      notFound = YES;
      break;
    }
    NSString *rangeStr = [text substringWithRange:NSMakeRange(modelStart, rawLength)];
    NSMutableAttributedString *rangeAttrStr =
        [NEEmotionTool getAttWithStr:rangeStr
                                font:messageTextFont
                               color:messageTextColor
                              offset:CGPointZero];
    NSInteger innerCount = [ChatMessageHelper getReduceIndexCount:rangeAttrStr];
    NSInteger end = modelEnd - countOffset - innerCount;
    if (end <= start) {
      notFound = YES;
      break;
    }

    NSInteger attrLength = end - start;
    if (attrLength > 0 && start >= 0 &&
        start + attrLength <= (NSInteger)attributeStr.length) {
      [attributeStr addAttribute:NSForegroundColorAttributeName
                           value:themeColor
                           range:NSMakeRange(start, attrLength)];
    }
  }

  if (notFound) {
    for (NSTextCheckingResult *match in matches) {
      if (match.range.location == NSNotFound) {
        continue;
      }
      NSInteger modelStart = match.range.location;
      NSInteger modelEnd = match.range.location + match.range.length;
      NSInteger attrLength = modelEnd - modelStart;
      if (modelStart >= 0 && attrLength > 0 &&
          modelStart + attrLength <= (NSInteger)attributeStr.length) {
        [attributeStr addAttribute:NSForegroundColorAttributeName
                             value:themeColor
                             range:NSMakeRange(modelStart, attrLength)];
      }
    }
  }

  return attributeStr;
}

#pragma mark - File Utilities

+ (nullable NSString *)getFileChecksum:(NSURL *)fileURL {
  // 打开文件，创建文件句柄
  NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:fileURL.path];
  if (!file) {
    return nil;
  }

  // 创建 MD5 上下文对象
  CC_MD5_CTX context;
  CC_MD5_Init(&context);

  // 读取文件数据并更新上下文对象
  BOOL keepReading = YES;
  while (keepReading) {
    @autoreleasepool {
      NSData *data = [file readDataOfLength:1024];
      if (data.length == 0) {
        keepReading = NO;
      } else {
        CC_MD5_Update(&context, data.bytes, (CC_LONG)data.length);
      }
    }
  }

  // 计算 MD5 值并关闭文件
  unsigned char digest[CC_MD5_DIGEST_LENGTH];
  CC_MD5_Final(digest, &context);
  [file closeFile];

  // 将 MD5 值转换为字符串格式
  NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [md5String appendFormat:@"%02hhx", digest[i]];
  }
  return [md5String copy];
}

+ (nullable NSString *)getFileChecksumWithFileURL:(NSURL *)fileURL {
  return [self getFileChecksum:fileURL];
}

+ (NSString *)createFilePath:(nullable V2NIMMessage *)message {
  NSString *path = [NEPathUtils getDirectoryForDocuments:kImkitDir] ?: @"";

  if (![message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) {
    return path;
  }
  V2NIMMessageFileAttachment *attach = (V2NIMMessageFileAttachment *)message.attachment;

  switch (message.messageType) {
    case V2NIM_MESSAGE_TYPE_AUDIO:
      path = [NEPathUtils getDirectoryForDocuments:
              [NSString stringWithFormat:@"%@audio/", kImkitDir]] ?: @"";
      break;
    case V2NIM_MESSAGE_TYPE_IMAGE:
      path = [NEPathUtils getDirectoryForDocuments:
              [NSString stringWithFormat:@"%@image/", kImkitDir]] ?: @"";
      break;
    case V2NIM_MESSAGE_TYPE_VIDEO:
      path = [NEPathUtils getDirectoryForDocuments:
              [NSString stringWithFormat:@"%@video/", kImkitDir]] ?: @"";
      break;
    default:
      path = [NEPathUtils getDirectoryForDocuments:
              [NSString stringWithFormat:@"%@file/", kImkitDir]] ?: @"";
      break;
  }

  if (message.messageClientId.length > 0) {
    path = [path stringByAppendingString:message.messageClientId];
  }

  // 后缀（例如：.png），超过 5 个字符不追加
  if (attach.ext.length > 0 && attach.ext.length < 5) {
    path = [path stringByAppendingString:attach.ext];
  }

  return path;
}

#pragma mark - Private Helpers

/// String.stringFromDate OC 等价实现
+ (NSString *)ne_stringFromDate:(NSDate *)date {
  return [self ne_stringFromDate:date showHM:YES];
}

/// String.stringFromDate(date:showHM:) OC 等价实现
+ (NSString *)ne_stringFromDate:(NSDate *)date showHM:(BOOL)showHM {
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  NSCalendar *calendar = [NSCalendar currentCalendar];

  if (showHM && [calendar isDateInToday:date]) {
    fmt.dateFormat = commonLocalizable(@"hm");
  } else {
    // 判断是否是今年
    NSDateComponents *yearComps = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear fromDate:date];
    if (yearComps.year == dateComps.year) {
      fmt.dateFormat = showHM ? commonLocalizable(@"mdhm") : commonLocalizable(@"md");
    } else {
      fmt.dateFormat = showHM ? commonLocalizable(@"ymdhm") : commonLocalizable(@"ymd");
    }
  }
  return [fmt stringFromDate:date];
}

@end
