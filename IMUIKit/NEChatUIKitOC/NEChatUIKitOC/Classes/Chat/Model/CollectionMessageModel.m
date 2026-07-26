// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CollectionMessageModel.h"
#import <NEChatKit/NSString+NECommon.h>
#import "ChatMessageHelper.h"
#import "ChatUIConfig.h"
#import "MessageEnum.h"
#import "MessageFileModel.h"
#import "MessageRichTextModel.h"
#import "MessageTextModel.h"

@implementation CollectionMessageModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _chatmodel = [[MessageTextModel alloc] initWithMessage:nil];
  }
  return self;
}

- (void)setMessage:(V2NIMMessage *)message {
  _message = message;
  if (message) {
    _chatmodel = [ChatMessageHelper modelFromMessage:message];

    if (_chatmodel.type == MessageTypeFile) {
      _fileModel = [[CollectionFileModel alloc] init];
      if ([_chatmodel isKindOfClass:[MessageFileModel class]]) {
        MessageFileModel *file = (MessageFileModel *)_chatmodel;
        _fileModel.size = file.size;
      }
    }
  }
}

- (CGFloat)cellHeight:(CGFloat)contenttMaxW {
  CGFloat height = self.chatmodel.contentSize.height;

  CGFloat fontSize = [ChatUIConfig shared].messageProperties.pinMessageTextSize;
  UIFont *titleFont = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
  UIFont *bodyFont = [UIFont systemFontOfSize:fontSize];
  CGSize maxSize = CGSizeMake(contenttMaxW, CGFLOAT_MAX);

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

  height += 124;

  if (self.chatmodel.isReply) {
    height += 12;
  }

  return height;
}

@end
