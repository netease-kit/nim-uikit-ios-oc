// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageRichTextModel.h"
#import <NEChatKitOC/NECustomUtils.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import "NEEmotionTool.h"
#import <NEChatKitOC/NSString+NECommon.h>
#import "ChatCellConstantValue.h"

@implementation MessageRichTextModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  NSDictionary *data = [NECustomUtils dataOfCustomMessage:message.attachment];
  NSString *title = data[@"title"];

  if (!title) {
    self = [super initWithMessage:message];
    return self;
  }

  NSString *body = data[@"body"] ?: @"";
  self = [super initWithMessage:message];
  if (self) {
    _titleText = [title copy];
    self.messageText = body;
    [self resetMessage:message];
    self.type = MessageTypeRichText;
    self.customType = customRichTextType;

    UIFont *font = [UIFont systemFontOfSize:self.messageTextFont.pointSize weight:UIFontWeightSemibold];
    _titleAttributeStr = [NEEmotionTool getAttWithStr:title
                                                 font:font
                                                color:self.messageTextColor
                                               offset:CGPointMake(0, -4)];

    CGSize textSize = [NSAttributedString getRealTextViewSize:_titleAttributeStr
                                                        font:self.messageTextFont
                                                     maxSize:self.messageMaxSize];
    _titleTextHeight = textSize.height;

    CGFloat contentSizeWidth = MAX(self.textWidth, textSize.width) + chat_content_margin * 2;
    CGFloat contentSizeHeight = self.contentSize.height + _titleTextHeight + (body.length == 0 ? 0 : chat_content_margin);
    self.contentSize = CGSizeMake(contentSizeWidth, contentSizeHeight);
    self.height = contentSizeHeight + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

- (NSString *)selectText {
  if (self.attributeStr == nil && _titleText != nil) {
    if (self.selectRange != nil) {
      NSRange range = self.selectRange.rangeValue;
      if (_titleAttributeStr.length == 0 || range.length == 0 || range.location >= _titleAttributeStr.length) {
        return nil;
      }
      NSString *text = [NEEmotionTool getTextWithAtt:_titleAttributeStr range:range];
      return text;
    }
  } else {
    return [super selectText];
  }
  return nil;
}

@end
