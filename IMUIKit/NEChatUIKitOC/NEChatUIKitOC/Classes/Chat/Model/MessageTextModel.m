// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageTextModel.h"
#import "ChatCellConstantValue.h"
#import "ChatMessageHelper.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import "NEEmotionTool.h"
#import <NEChatKit/NSString+NECommon.h>

@implementation MessageTextModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeText;
    self.messageText = message.text;
    [self resetMessage:message];
  }
  return self;
}

- (void)resetMessage:(V2NIMMessage *)message {
  [super resetMessage:message];

  if (self.messageText.length > 0) {
    self.attributeStr = [NEEmotionTool getAttWithStr:self.messageText
                                                font:self.messageTextFont
                                               color:self.messageTextColor
                                              offset:CGPointMake(0, -4)];
  } else {
    self.attributeStr = nil;
  }

  // 解析 @，效果高亮
  if ([IMKitConfigCenter shared].enableAtMessage) {
    NSMutableAttributedString *att = [ChatMessageHelper loadAtInMessage:message
                                                          attributeStr:self.attributeStr];
    if (att) {
      self.attributeStr = att;
    }
  }

  [self resetHeight:nil];
}

- (CGSize)getTextSize:(NSAttributedString *)attributeStr {
  NSAttributedString *att = attributeStr ?: self.attributeStr;
  return [NSAttributedString getRealTextViewSize:att font:self.messageTextFont maxSize:self.messageMaxSize];
}

- (void)resetHeight:(NSAttributedString *)attributeStr {
  CGSize textSize = [self getTextSize:attributeStr];
  self.textHeight = ceil(textSize.height);
  self.textWidth = ceil(textSize.width);
  CGFloat contentSizeWidth = self.textWidth + chat_content_margin * 2;
  CGFloat contentSizeHeight = self.textHeight + chat_content_margin * 2;
  self.contentSize = CGSizeMake(contentSizeWidth, contentSizeHeight);
  self.height = contentSizeHeight + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
}

- (void)resetWH:(CGFloat)height width:(CGFloat)width {
  self.textHeight = ceil(height);
  self.textWidth = ceil(width);
  CGFloat contentSizeWidth = self.textWidth + chat_content_margin * 2;
  CGFloat contentSizeHeight = self.textHeight + chat_content_margin * 2;
  self.contentSize = CGSizeMake(contentSizeWidth, contentSizeHeight);
  self.height = contentSizeHeight + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
}

/// 获取划词选中的文本（替换内置表情）
- (NSString *)selectText {
  if (self.selectRange) {
    NSRange range = self.selectRange.rangeValue;
    if (self.attributeStr.length == 0 || range.length == 0 || range.location >= self.attributeStr.length) {
      return nil;
    }
    // 内置表情转为文本
    NSString *text = [NEEmotionTool getTextWithAtt:self.attributeStr range:range];
    return text;
  }
  return nil;
}

@end
