// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPinMessageModel.h"
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/NSString+NECommon.h>
#import "ChatMessageHelper.h"
#import "ChatUIConfig.h"
#import "MessageFileModel.h"
#import "MessageRichTextModel.h"
#import "MessageTextModel.h"

@implementation NEPinMessageModel

- (instancetype)initWithMessage:(V2NIMMessage *)message item:(V2NIMMessagePin *)item {
  self = [super init];
  if (self) {
    _message = message;
    _item = item;
    _conversationId = item.messageRefer.conversationId;

    _chatmodel = [ChatMessageHelper modelFromMessage:message];

    NSString *uid = [ChatMessageHelper getSenderId:message];
    _chatmodel.fullName = uid ?: @"";
    _chatmodel.shortName = [NEFriendUserCache getShortName:uid ?: @"" length:2];

    if (_chatmodel.type == MessageTypeFile) {
      _pinFileModel = [[PinMessageFileModel alloc] init];
      if ([_chatmodel isKindOfClass:[MessageFileModel class]]) {
        MessageFileModel *filemodel = (MessageFileModel *)_chatmodel;
        _pinFileModel.size = filemodel.size;
      }
    }
  }
  return self;
}

- (CGFloat)cellHeight:(CGFloat)pinContentMaxW {
  CGFloat height = self.chatmodel.contentSize.height;

  CGFloat fontSize = [ChatUIConfig shared].messageProperties.pinMessageTextSize;
  UIFont *titleFont = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
  UIFont *bodyFont = [UIFont systemFontOfSize:fontSize];
  CGSize maxSize = CGSizeMake(pinContentMaxW, CGFLOAT_MAX);

  if ([self.chatmodel isKindOfClass:[MessageRichTextModel class]]) {
    MessageRichTextModel *richTextModel = (MessageRichTextModel *)self.chatmodel;
    // 换行消息：标题最多 1 行
    CGSize titleSize = [NSAttributedString ne_getRealLabelSize:richTextModel.titleAttributeStr
                                                       font:titleFont
                                                       size:maxSize
                                              numberOfLines:1];
    height = titleSize.height;
    // 换行消息：正文最多 2 行
    CGSize textSize = [NSAttributedString ne_getRealLabelSize:richTextModel.attributeStr
                                                      font:bodyFont
                                                      size:maxSize
                                             numberOfLines:2];
    height += textSize.height;
  } else if ([self.chatmodel isKindOfClass:[MessageTextModel class]]) {
    MessageTextModel *textModel = (MessageTextModel *)self.chatmodel;
    // 文本消息最多 3 行
    CGSize textSize = [NSAttributedString ne_getRealLabelSize:textModel.attributeStr
                                                      font:bodyFont
                                                      size:maxSize
                                             numberOfLines:3];
    height = textSize.height;
  }

  height += 100;

  if (self.chatmodel.isReply) {
    height += 12;
  }

  return height;
}

@end
