// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ReplyMessageUtil.h"
#import "MessageContentModel.h"
#import "ChatMessageHelper.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NECustomUtils.h>
#import <NIMSDK/NIMSDK.h>

@implementation ReplyMessageUtil

+ (NSString *)textForReplyModel:(MessageContentModel *)model {
  NSMutableString *text = [NSMutableString string];
  if (model.fullName) {
    [text appendFormat:@"%@: ", model.fullName];
  }

  if (model.type == MessageTypeText || model.type == MessageTypeAIStreamText) {
    NSString *richContent = [NECustomUtils contentOfRichText:model.message.attachment];
    if (richContent) {
      [text appendString:richContent];
      return [text copy];
    }
    NSString *messageText = model.message.text ?: chatLocalizable(@"message_not_found");
    [text appendString:messageText];
  } else {
    [text appendString:[ChatMessageHelper contentOfMessage:model.message]];
  }

  return [text copy];
}

+ (NSString *)textForReplyModelWithModel:(MessageContentModel *)model {
  return [self textForReplyModel:model];
}

@end
