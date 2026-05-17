// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageTextCell.h"
#import <NEChatKitOC/NSString+NECommon.h>
#import "ChatCellConstantValue.h"
#import "MessageTextModel.h"

@implementation FunChatMessageTextCell

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin + self.funMargin],
        [self.contentLabelLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:chat_content_margin],
        [self.contentLabelLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:-chat_content_margin],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.contentLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-chat_content_margin - self.funMargin],
        [self.contentLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
        [self.contentLabelRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:chat_content_margin],
        [self.contentLabelRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:-chat_content_margin],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentLabelLeft.hidden = showRight;
    self.contentLabelRight.hidden = !showRight;
}

- (void)resetSelectRange {
    self.contentLabelLeft.selectedRange = NSMakeRange(0, 0);
    self.contentLabelRight.selectedRange = NSMakeRange(0, 0);
}

- (void)selectAllRange {
    if (self.contentModel.message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING) {
        return;
    }
    NEChatTextView *contentLabel = self.contentLabelLeft.hidden ? self.contentLabelRight : self.contentLabelLeft;
    NSUInteger length = [contentLabel.text lengthOfBytesUsingEncoding:NSUTF16StringEncoding] / 2;
    NSRange range = NSMakeRange(0, length);
    contentLabel.selectedRange = range;
    self.contentModel.selectRange = [NSValue valueWithRange:range];
    [self.delegate didLongPressMessageView:self model:self.contentModel];
    [contentLabel becomeFirstResponder];
}

- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect {
    [super setSelect:model enableSelect:enableSelect];
    self.contentLabelLeft.userInteractionEnabled = !enableSelect;
    self.contentLabelRight.userInteractionEnabled = !enableSelect;
    self.bubbleImageLeft.userInteractionEnabled = !enableSelect;
    self.bubbleImageRight.userInteractionEnabled = !enableSelect;
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress {
    self.isLongPress = YES;
    [self selectAllRange];
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    self.isLongPress = NO;
    self.contentModel.cell = self;

    NEChatTextView *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;

    if ([model isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *m = (MessageTextModel *)model;
        contentLabel.attributedText = m.attributeStr;
        contentLabel.accessibilityValue = m.message.text;
        [self contentSizeToFit:contentLabel model:m];
    }
    bubbleW.constant += self.funMargin;
}

- (void)tapFunc {}

- (void)selectText {
    NEChatTextView *contentLabel = self.contentLabelLeft.hidden ? self.contentLabelRight : self.contentLabelLeft;
    NSRange range = contentLabel.selectedRange;
    self.contentModel.selectRange = [NSValue valueWithRange:range];
    [self.delegate didLongPressMessageView:self model:self.contentModel];

    if (range.length > 0) {
        [contentLabel becomeFirstResponder];
    } else {
        [contentLabel resignFirstResponder];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.isLongPress && self.contentModel.selectRange == nil) {
        [self selectAllRange];
        return;
    }

    if (textView.selectedRange.length == 0 || self.contentModel.selectRange == nil) {
        self.contentModel.selectRange = nil;
        if ([self.delegate respondsToSelector:@selector(didTextViewLoseFocus:model:)]) {
            [self.delegate didTextViewLoseFocus:self model:self.contentModel];
        }
        self.isLongPress = NO;
    } else {
        [self selectText];
    }
}

- (CGSize)getTextSize:(NSAttributedString *)attributedText {
    return [NSAttributedString getRealTextViewSize:attributedText
                                              font:self.messageTextFont
                                           maxSize:self.contentModel.messageMaxSize];
}

- (void)contentSizeToFit:(NEChatTextView *)contentLabel model:(MessageTextModel *)model {
    CGSize titleSize = [self getTextSize:contentLabel.attributedText];

    if (model.contentSize.height == fun_chat_min_h) {
        contentLabel.textContainerInset = UIEdgeInsetsMake(4, 0, 0, 0);
        return;
    }

    CGFloat textHeight = titleSize.height;
    CGFloat textViewHeight = model.textHeight;
    if (textHeight <= textViewHeight) {
        CGFloat offsetY = (textViewHeight - textHeight) / 2;
        contentLabel.textContainerInset = UIEdgeInsetsMake(offsetY, 0, 0, 0);
    } else {
        contentLabel.textContainerInset = UIEdgeInsetsZero;
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    [self selectAllRange];
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.delegate respondsToSelector:@selector(didTapDetectedLink:model:url:)]) {
        [self.delegate didTapDetectedLink:self model:self.contentModel url:URL];
    }
    return NO;
}

#pragma mark - Lazy Load

- (NEChatTextView *)contentLabelLeft {
    if (!_contentLabelLeft) {
        _contentLabelLeft = [[NEChatTextView alloc] init];
        _contentLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft.editable = NO;
        _contentLabelLeft.selectable = YES;
        _contentLabelLeft.scrollEnabled = NO;
        _contentLabelLeft.showsVerticalScrollIndicator = NO;
        _contentLabelLeft.showsHorizontalScrollIndicator = NO;
        _contentLabelLeft.delegate = self;
        _contentLabelLeft.textContainerInset = UIEdgeInsetsZero;
        _contentLabelLeft.contentInset = UIEdgeInsetsZero;
        _contentLabelLeft.textContainer.lineFragmentPadding = 0.0;
        _contentLabelLeft.userInteractionEnabled = YES;
        _contentLabelLeft.font = self.messageTextFont;
        _contentLabelLeft.backgroundColor = [UIColor clearColor];
        _contentLabelLeft.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        _contentLabelLeft.accessibilityIdentifier = @"id.messageText";

        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        doubleTap.numberOfTapsRequired = 2;
        [_contentLabelLeft addGestureRecognizer:doubleTap];

        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAllRange)];
        [_contentLabelLeft addGestureRecognizer:longTap];
    }
    return _contentLabelLeft;
}

- (NEChatTextView *)contentLabelRight {
    if (!_contentLabelRight) {
        _contentLabelRight = [[NEChatTextView alloc] init];
        _contentLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight.editable = NO;
        _contentLabelRight.selectable = YES;
        _contentLabelRight.scrollEnabled = NO;
        _contentLabelRight.showsVerticalScrollIndicator = NO;
        _contentLabelRight.showsHorizontalScrollIndicator = NO;
        _contentLabelRight.delegate = self;
        _contentLabelRight.textContainerInset = UIEdgeInsetsZero;
        _contentLabelRight.contentInset = UIEdgeInsetsZero;
        _contentLabelRight.textContainer.lineFragmentPadding = 0.0;
        _contentLabelRight.userInteractionEnabled = YES;
        _contentLabelRight.font = self.messageTextFont;
        _contentLabelRight.backgroundColor = [UIColor clearColor];
        _contentLabelRight.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        _contentLabelRight.accessibilityIdentifier = @"id.messageText";

        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        doubleTap.numberOfTapsRequired = 2;
        [_contentLabelRight addGestureRecognizer:doubleTap];

        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAllRange)];
        [_contentLabelRight addGestureRecognizer:longTap];
    }
    return _contentLabelRight;
}

@end
