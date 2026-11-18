// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageRichTextCell.h"

@implementation ChatMessageRichTextCell

- (NEChatTextView *)titleLabelLeft {
    if (!_titleLabelLeft) {
        _titleLabelLeft = [[NEChatTextView alloc] init];
        _titleLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft.editable = NO;
        _titleLabelLeft.selectable = YES;
        _titleLabelLeft.scrollEnabled = NO;
        _titleLabelLeft.showsVerticalScrollIndicator = NO;
        _titleLabelLeft.showsHorizontalScrollIndicator = NO;
        _titleLabelLeft.delegate = self;
        _titleLabelLeft.textContainerInset = UIEdgeInsetsZero;
        _titleLabelLeft.contentInset = UIEdgeInsetsZero;
        _titleLabelLeft.textContainer.lineFragmentPadding = 0.0;
        _titleLabelLeft.userInteractionEnabled = NO;
        _titleLabelLeft.font = [UIFont systemFontOfSize:self.messageTextFont.pointSize weight:UIFontWeightSemibold];
        _titleLabelLeft.backgroundColor = UIColor.clearColor;
        _titleLabelLeft.accessibilityIdentifier = @"id.messageTitle";

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        [_titleLabelLeft addGestureRecognizer:singleTap];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        doubleTap.numberOfTapsRequired = 2;
        [_titleLabelLeft addGestureRecognizer:doubleTap];
        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAllRange)];
        [_titleLabelLeft addGestureRecognizer:longTap];
    }
    return _titleLabelLeft;
}

- (NEChatTextView *)titleLabelRight {
    if (!_titleLabelRight) {
        _titleLabelRight = [[NEChatTextView alloc] init];
        _titleLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelRight.editable = NO;
        _titleLabelRight.selectable = YES;
        _titleLabelRight.scrollEnabled = NO;
        _titleLabelRight.showsVerticalScrollIndicator = NO;
        _titleLabelRight.showsHorizontalScrollIndicator = NO;
        _titleLabelRight.delegate = self;
        _titleLabelRight.textContainerInset = UIEdgeInsetsZero;
        _titleLabelRight.contentInset = UIEdgeInsetsZero;
        _titleLabelRight.textContainer.lineFragmentPadding = 0.0;
        _titleLabelRight.userInteractionEnabled = NO;
        _titleLabelRight.font = [UIFont systemFontOfSize:self.messageTextFont.pointSize weight:UIFontWeightSemibold];
        _titleLabelRight.backgroundColor = UIColor.clearColor;
        _titleLabelRight.accessibilityIdentifier = @"id.messageTitle";

        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        [_titleLabelRight addGestureRecognizer:singleTap];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFunc)];
        doubleTap.numberOfTapsRequired = 2;
        [_titleLabelRight addGestureRecognizer:doubleTap];
        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(selectAllRange)];
        [_titleLabelRight addGestureRecognizer:longTap];
    }
    return _titleLabelRight;
}

- (void)commonUILeft {
    [self.bubbleImageLeft addSubview:self.replyViewLeft];
    self.replyViewLeftHeightAnchor = [self.replyViewLeft.heightAnchor constraintEqualToConstant:self.replyViewHeight];
    self.replyViewLeftHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewLeft.leadingAnchor constraintEqualToAnchor:self.bubbleImageLeft.leadingAnchor constant:chat_content_margin],
        [self.replyViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:0],
        [self.replyViewLeft.trailingAnchor constraintEqualToAnchor:self.bubbleImageLeft.trailingAnchor constant:-chat_content_margin],
    ]];

    [self.bubbleImageLeft addSubview:self.titleLabelLeft];
    self.titleLabelLeftHeightAnchor = [self.titleLabelLeft.heightAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.height];
    self.titleLabelLeftHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft.topAnchor constraintEqualToAnchor:self.replyViewLeft.bottomAnchor constant:chat_content_margin],
        [self.titleLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.titleLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin],
    ]];

    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    self.contentLabelLeftHeightAnchor = [self.contentLabelLeft.heightAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.height];
    self.contentLabelLeftHeightAnchor.active = YES;
    self.reactionTopAnchorLeft.active = NO;
    self.reactionTopAnchorLeft = [self.reactionViewLeft.topAnchor constraintEqualToAnchor:self.contentLabelLeft.bottomAnchor
                                                                                   constant:chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.titleLabelLeft.rightAnchor constant:0],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.titleLabelLeft.leftAnchor constant:0],
        [self.contentLabelLeft.topAnchor constraintEqualToAnchor:self.titleLabelLeft.bottomAnchor constant:chat_content_margin],
        self.reactionTopAnchorLeft,
    ]];
}

- (void)commonUIRight {
    [self.bubbleImageRight addSubview:self.replyViewRight];
    self.replyViewRightHeightAnchor = [self.replyViewRight.heightAnchor constraintEqualToConstant:self.replyViewHeight];
    self.replyViewRightHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewRight.leadingAnchor constraintEqualToAnchor:self.bubbleImageRight.leadingAnchor constant:chat_content_margin],
        [self.replyViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:0],
        [self.replyViewRight.trailingAnchor constraintEqualToAnchor:self.bubbleImageRight.trailingAnchor constant:-chat_content_margin],
    ]];

    [self.bubbleImageRight addSubview:self.titleLabelRight];
    self.titleLabelRightHeightAnchor = [self.titleLabelRight.heightAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.height];
    self.titleLabelRightHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelRight.topAnchor constraintEqualToAnchor:self.replyViewRight.bottomAnchor constant:chat_content_margin],
        [self.titleLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-chat_content_margin],
        [self.titleLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
    ]];

    [self.bubbleImageRight addSubview:self.contentLabelRight];
    self.contentLabelRightHeightAnchor = [self.contentLabelRight.heightAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.height];
    self.contentLabelRightHeightAnchor.active = YES;
    self.reactionTopAnchorRight.active = NO;
    self.reactionTopAnchorRight = [self.reactionViewRight.topAnchor constraintEqualToAnchor:self.contentLabelRight.bottomAnchor
                                                                                       constant:chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight.rightAnchor constraintEqualToAnchor:self.titleLabelRight.rightAnchor constant:0],
        [self.contentLabelRight.leftAnchor constraintEqualToAnchor:self.titleLabelRight.leftAnchor constant:0],
        [self.contentLabelRight.topAnchor constraintEqualToAnchor:self.titleLabelRight.bottomAnchor constant:chat_content_margin],
        self.reactionTopAnchorRight,
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.titleLabelLeft.hidden = showRight;
    self.titleLabelRight.hidden = !showRight;
}

- (void)resetSelectRange {
    [super resetSelectRange];
    self.titleLabelLeft.selectedRange = NSMakeRange(0, 0);
    self.titleLabelRight.selectedRange = NSMakeRange(0, 0);
}

- (void)selectAllRange {
    [super selectAllRange];
    if ([self.contentModel isKindOfClass:[MessageTextModel class]] && ((MessageTextModel *)self.contentModel).attributeStr == nil) {
        NEChatTextView *titleLabel = self.titleLabelLeft.hidden ? self.titleLabelRight : self.titleLabelLeft;
        NSUInteger length = titleLabel.text.length;
        NSRange range = NSMakeRange(0, length);
        titleLabel.selectedRange = range;
        self.contentModel.selectRange = [NSValue valueWithRange:range];
        [self.delegate didLongPressMessageView:self model:self.contentModel];
        [titleLabel becomeFirstResponder];
    }
}

- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect {
    [super setSelect:model enableSelect:enableSelect];
    NEChatTextView *titleLabel = self.titleLabelLeft.hidden ? self.titleLabelRight : self.titleLabelLeft;
    titleLabel.userInteractionEnabled = !enableSelect;
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress {
    if ([self.contentModel isKindOfClass:[MessageTextModel class]] && ((MessageTextModel *)self.contentModel).attributeStr == nil) {
        [self selectAllRange];
    } else {
        [super longPress:longPress];
    }
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    NEChatTextView *titleLabel = isSend ? self.titleLabelRight : self.titleLabelLeft;
    NSLayoutConstraint *titleLabelHeightAnchor = isSend ? self.titleLabelRightHeightAnchor : self.titleLabelLeftHeightAnchor;
    NSLayoutConstraint *contentLabelHeightAnchor = isSend ? self.contentLabelRightHeightAnchor : self.contentLabelLeftHeightAnchor;

    if ([model isKindOfClass:[MessageTextModel class]]) {
        contentLabelHeightAnchor.constant = ((MessageTextModel *)model).textHeight;
    }
    if ([model isKindOfClass:[MessageRichTextModel class]]) {
        MessageRichTextModel *m = (MessageRichTextModel *)model;
        titleLabel.attributedText = m.titleAttributeStr;
        titleLabelHeightAnchor.constant = m.titleTextHeight;
        if (m.attributeStr == nil) {
            titleLabel.userInteractionEnabled = YES;
        } else {
            titleLabel.userInteractionEnabled = NO;
        }
    }
}

- (void)selectText {
    if ([self.contentModel isKindOfClass:[MessageTextModel class]] && ((MessageTextModel *)self.contentModel).attributeStr != nil) {
        [super selectText];
        return;
    }
    NEChatTextView *titleLabel = self.titleLabelLeft.hidden ? self.titleLabelRight : self.titleLabelLeft;
    NSRange range = titleLabel.selectedRange;
    self.contentModel.selectRange = [NSValue valueWithRange:range];
    [self.delegate didLongPressMessageView:self model:self.contentModel];
    if (self.contentModel.selectRange != nil && self.contentModel.selectRange.rangeValue.length > 0) {
        [titleLabel becomeFirstResponder];
    } else {
        [titleLabel resignFirstResponder];
    }
}

@end
