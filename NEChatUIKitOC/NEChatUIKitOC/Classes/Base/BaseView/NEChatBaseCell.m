// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatBaseCell.h"

#import "ChatCellConstantValue.h"

@implementation NEChatBaseCell {
  /// (约束, inset)：inset 用来还原页面自己的宽度语义（例如回复条、文件气泡）。
  NSMutableArray<NSArray *> *_viewportWidthConstraints;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _viewportWidthConstraints = [NSMutableArray array];
  }
  return self;
}

- (CGFloat)chatContentMaxW {
  return self.chatViewport ? self.chatViewport.maximumBubbleWidth : MAX(32, chat_content_maxW());
}

- (CGFloat)chatTextMaxW {
  return self.chatViewport ? self.chatViewport.maximumTextWidth : MAX(16, chat_text_maxW);
}

- (CGFloat)audioMaxWidth {
  return self.chatViewport ? self.chatViewport.maximumAudioWidth : (chat_content_maxW() <= 325 ? 230 : 265);
}

- (CGFloat)chatContainerWidth {
  return self.chatViewport ? self.chatViewport.contentWidth : chat_content_maxW() + 156;
}

- (NSLayoutConstraint *)messageWidthConstraint:(NSLayoutDimension *)anchor inset:(CGFloat)inset {
  NSLayoutConstraint *constraint =
      [anchor constraintLessThanOrEqualToConstant:MAX(16, self.chatContentMaxW - inset)];
  [_viewportWidthConstraints addObject:@[ constraint, @(inset) ]];
  return constraint;
}

- (void)applyViewport:(NEChatViewport *)viewport {
  self.chatViewport = viewport;
  for (NSArray *entry in _viewportWidthConstraints) {
    NSLayoutConstraint *constraint = entry.firstObject;
    CGFloat inset = [entry.lastObject doubleValue];
    constraint.constant = MAX(16, self.chatContentMaxW - inset);
  }
}

- (void)uploadProgress:(NSUInteger)progress {}
- (void)setModel:(MessageContentModel *)model {}
- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {}

@end
