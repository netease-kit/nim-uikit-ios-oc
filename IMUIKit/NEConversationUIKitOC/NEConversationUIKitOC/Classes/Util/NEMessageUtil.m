// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMessageUtil.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NECustomUtils.h>

static NECommonLoader *NEConversationMessageLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEMessageUtil class]];
  });
  return loader;
}

static NSString *NEConversationMessageLocalizable(NSString *key) {
  return [NEConversationMessageLoader() localizable:key];
}

@implementation NEMessageUtil

+ (NSString *)messageContentFromLastMessage:(V2NIMLastMessage *)lastMessage {
  if (!lastMessage) return @"";
  return [self messageContentWithType:(NSInteger)lastMessage.messageType
                                 text:lastMessage.text
                           attachment:lastMessage.attachment];
}

+ (NSString *)messageContentWithType:(NSInteger)messageType
                                text:(NSString *)text
                          attachment:(id)attachment {
  // 对齐 Swift NEMessageUtil.messageContent(_:_:_:)
  switch ((V2NIMMessageType)messageType) {
    case V2NIM_MESSAGE_TYPE_TEXT:
      return text ?: @"";

    case V2NIM_MESSAGE_TYPE_TIP:
      return NEConversationMessageLocalizable(@"tip");

    case V2NIM_MESSAGE_TYPE_AUDIO:
      return NEConversationMessageLocalizable(@"voice");

    case V2NIM_MESSAGE_TYPE_IMAGE:
      return NEConversationMessageLocalizable(@"picture");

    case V2NIM_MESSAGE_TYPE_VIDEO:
      return NEConversationMessageLocalizable(@"video");

    case V2NIM_MESSAGE_TYPE_LOCATION:
      return [NSString stringWithFormat:@"%@ %@", NEConversationMessageLocalizable(@"location"), text ?: @""];

    case V2NIM_MESSAGE_TYPE_NOTIFICATION:
      return NEConversationMessageLocalizable(@"notification");

    case V2NIM_MESSAGE_TYPE_FILE:
      return NEConversationMessageLocalizable(@"file");

    case V2NIM_MESSAGE_TYPE_CUSTOM:
      return [self _contentOfCustomAttachment:attachment];

    case V2NIM_MESSAGE_TYPE_CALL:
      if ([attachment isKindOfClass:NSClassFromString(@"V2NIMMessageCallAttachment")]) {
        NSInteger callType = [[attachment valueForKey:@"type"] integerValue];
        return callType == 1 ? NEConversationMessageLocalizable(@"internet_phone") : NEConversationMessageLocalizable(@"video_chat");
      }
      return NEConversationMessageLocalizable(@"unknown");

    default:
      return NEConversationMessageLocalizable(@"unknown");
  }
}

+ (NSString *)_contentOfCustomAttachment:(id)attachment {
  if (!attachment) return NEConversationMessageLocalizable(@"unknown");
  if (![attachment isKindOfClass:[V2NIMMessageAttachment class]]) return NEConversationMessageLocalizable(@"unknown");

  NSNumber *customType = [NECustomUtils typeOfCustomMessage:(V2NIMMessageAttachment *)attachment];
  if (!customType) return NEConversationMessageLocalizable(@"unknown");

  if (customType.integerValue == customMultiForwardType) {
    return NEConversationMessageLocalizable(@"chat_history");
  }

  if (customType.integerValue == customRichTextType) {
    NSString *title = [NECustomUtils titleOfRichText:(V2NIMMessageAttachment *)attachment];
    return title.length > 0 ? title : NEConversationMessageLocalizable(@"custom");
  }

  return NEConversationMessageLocalizable(@"custom");
}

@end
