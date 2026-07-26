// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageAIStreamModel.h"
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"
#import "NEMarkdownParser.h"
#import <NEChatKit/NSString+NECommon.h>
#import <NIMSDK/NIMSDK.h>

@implementation MessageAIStreamModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeAIStreamText;
    [self resetMessage:message];
  }
  return self;
}

- (void)resetMessage:(V2NIMMessage *)message {
  self.message = message;

  // 【服务器异常停止】模型返回可能为空，替换文案：服务器繁忙，请稍后再试
  if (message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_ABORTED &&
      (message.text == nil || message.text.length == 0)) {
    message.text = chatLocalizable(@"server_busy");
  }

  // 使用 NEMarkdownParser 解析 Markdown 富文本
  NSString *text = message.text ?: @"";
  NEMarkdownParser *parser = [[NEMarkdownParser alloc] initWithFont:[UIFont systemFontOfSize:16]];
  parser.code.textHighlightColor = UIColor.blackColor;
  // 与 Swift 版保持一致：Markdown 表格/图片宽度不能超过气泡内容区域。
  CGFloat contentMaxWidth = chat_content_maxW() - chat_content_margin * 2;
  parser.table.maxWidth = contentMaxWidth;
  parser.markdownImage.maxWidth = contentMaxWidth;
  parser.markdownImage.maxHeight = contentMaxWidth;
  NSMutableAttributedString *markdownAtt = [[parser parseMarkdownString:text] mutableCopy];
  if (markdownAtt && markdownAtt.length > 0) {
    self.attributeStr = markdownAtt;
  } else {
    // 无法解析 Markdown 则回退到纯文本
    [super resetMessage:message];
    return;
  }

  [self resetHeight:nil];
  self.offset = 0;
}

- (CGSize)getTextSize:(NSAttributedString *)attributeStr {
  NSAttributedString *att = attributeStr ?: self.attributeStr;
  return [NSAttributedString getRealTextViewSize:att
                                            font:self.messageTextFont
                                         maxSize:self.messageMaxSize];
}

@end
