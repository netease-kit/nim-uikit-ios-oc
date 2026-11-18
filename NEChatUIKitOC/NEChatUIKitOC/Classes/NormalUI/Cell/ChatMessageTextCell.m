// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageTextCell.h"
#import <NEChatKit/NSString+NECommon.h>
#import "NEChatUIConstant.h"
#import "UIImage+Chat.h"
#import "NormalChatUIColor.h"

@interface ChatMessageTextCell ()
@property (nonatomic, strong) UIView *translationAreaLeft;
@property (nonatomic, strong) UIView *translationAreaRight;
@property (nonatomic, strong) UILabel *translationTextLabelLeft;
@property (nonatomic, strong) UILabel *translationTextLabelRight;
@property (nonatomic, strong) NSLayoutConstraint *translationAreaLeftHeightZero;
@property (nonatomic, strong) NSLayoutConstraint *translationAreaRightHeightZero;
@property (nonatomic, strong) NSLayoutConstraint *translationAreaLeftTopAnchor;
@property (nonatomic, strong) NSLayoutConstraint *translationAreaRightTopAnchor;
@end

@implementation ChatMessageTextCell

- (BOOL)usesInlineReactionSurface {
    return YES;
}

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
        _contentLabelLeft.backgroundColor = UIColor.clearColor;
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
        _contentLabelRight.backgroundColor = UIColor.clearColor;
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

- (void)tapFunc {
    self.contentModel.selectRange = nil;
    if ([self.delegate respondsToSelector:@selector(didTextViewLoseFocus:model:)]) {
        [self.delegate didTextViewLoseFocus:self model:self.contentModel];
    }
    self.isLongPress = NO;
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    [self.bubbleImageLeft addSubview:self.translationAreaLeft];
    NSLayoutConstraint *bottom = [self.contentLabelLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:-chat_content_margin];
    bottom.priority = UILayoutPriorityDefaultLow;
    self.translationAreaLeftHeightZero = [self.translationAreaLeft.heightAnchor constraintEqualToConstant:0];
    self.translationAreaLeftHeightZero.active = YES;
    self.translationAreaLeftTopAnchor = [self.translationAreaLeft.topAnchor constraintEqualToAnchor:self.reactionViewLeft.bottomAnchor];
    self.reactionTopAnchorLeft.active = NO;
    self.reactionTopAnchorLeft = [self.reactionViewLeft.topAnchor constraintEqualToAnchor:self.contentLabelLeft.bottomAnchor
                                                                                  constant:chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin],
        [self.contentLabelLeft.topAnchor constraintEqualToAnchor:self.replyViewLeft.bottomAnchor constant:chat_content_margin],
        bottom,
        self.translationAreaLeftTopAnchor,
        [self.translationAreaLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin],
        [self.translationAreaLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.translationAreaLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:-chat_content_margin],
        self.reactionTopAnchorLeft,
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.contentLabelRight];
    [self.bubbleImageRight addSubview:self.translationAreaRight];
    NSLayoutConstraint *bottom = [self.contentLabelRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:-chat_content_margin];
    bottom.priority = UILayoutPriorityDefaultLow;
    self.translationAreaRightHeightZero = [self.translationAreaRight.heightAnchor constraintEqualToConstant:0];
    self.translationAreaRightHeightZero.active = YES;
    self.translationAreaRightTopAnchor = [self.translationAreaRight.topAnchor constraintEqualToAnchor:self.reactionViewRight.bottomAnchor];
    self.reactionTopAnchorRight.active = NO;
    self.reactionTopAnchorRight = [self.reactionViewRight.topAnchor constraintEqualToAnchor:self.contentLabelRight.bottomAnchor
                                                                                    constant:chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-chat_content_margin],
        [self.contentLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
        [self.contentLabelRight.topAnchor constraintEqualToAnchor:self.replyViewRight.bottomAnchor constant:chat_content_margin],
        bottom,
        self.translationAreaRightTopAnchor,
        [self.translationAreaRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
        [self.translationAreaRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-chat_content_margin],
        [self.translationAreaRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:-chat_content_margin],
        self.reactionTopAnchorRight,
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentLabelLeft.hidden = showRight;
    self.contentLabelRight.hidden = !showRight;
    self.translationAreaLeft.hidden = YES;
    self.translationAreaRight.hidden = YES;
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
    NSUInteger length = contentLabel.text.length;
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
    if ([model isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *m = (MessageTextModel *)model;
        contentLabel.attributedText = m.attributeStr;
        contentLabel.accessibilityValue = m.message.text;
        [self contentSizeToFit:contentLabel model:m];
        [self bindTranslation:m isSend:isSend];
    } else {
        contentLabel.text = model.message.text;
        contentLabel.accessibilityValue = model.message.text;
    }

    // Keep Normal/Feishu reactions in the body, between text and translation.
    // The base cell still owns the same reaction view and callbacks; only the
    // bubble dimensions and vertical spacing are changed here.
    NEMessageReactionView *reactionView = isSend ? self.reactionViewRight : self.reactionViewLeft;
    BOOL hasReaction = model.reactionHeight > 0;
    // Always measure text reactions against the available message width.
    // Minimum-height short bubbles must not be mistaken for multi-line text.
    CGFloat reactionInset = [self reactionHorizontalInsetForModel:model];
    CGFloat reactionMaxWidth = MAX(26.0, self.chatContentMaxW - reactionInset * 2.0);
    CGFloat measuredReactionWidth = hasReaction
        ? [reactionView layoutWidthForMaxWidth:reactionMaxWidth]
        : 0;
    CGFloat reactionWidth = hasReaction
        ? MIN(reactionMaxWidth, MAX(measuredReactionWidth, 26.0))
        : 0;
    CGFloat bubbleWidth = hasReaction
        ? MIN(self.chatContentMaxW, MAX(model.contentSize.width, reactionWidth + reactionInset * 2.0))
        : model.contentSize.width;
    // 极短消息的原文宽度可能小于译文 footer；只按原文宽度约束气泡会裁切译文区域。
    if ([model isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *textModel = (MessageTextModel *)model;
        BOOL hasTranslation = textModel.translationVisible &&
            (textModel.translationFailed || textModel.translationInfo.translatedText.length > 0) &&
            !textModel.inMultiForward;
        if (hasTranslation) {
            bubbleWidth = MAX(bubbleWidth,
                              [textModel estimateTranslationTextWidth] + chat_content_margin * 2);
        }
    }
    if (isSend) {
        self.bubbleWRight.constant = bubbleWidth;
        self.bubbleHRight.constant = model.contentSize.height + (hasReaction ? model.reactionHeight : 0);
        self.translationAreaRightTopAnchor.constant = 0.0;
    } else {
        self.bubbleWLeft.constant = bubbleWidth;
        self.bubbleHLeft.constant = model.contentSize.height + (hasReaction ? model.reactionHeight : 0);
        self.translationAreaLeftTopAnchor.constant = 0.0;
    }
}

- (UIView *)makeTranslationArea:(BOOL)isSend {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.hidden = YES;
    [container addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTranslationLongPress:)]];
    [container addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTranslationRetryTap:)]];

    UIView *divider = [[UIView alloc] init];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = UIColor.normalChatTranslationDividerColor;
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.numberOfLines = 0;
    textLabel.font = self.messageTextFont;
    textLabel.textColor = UIColor.ne_darkText;
    textLabel.accessibilityIdentifier = @"id.translationText";
    UIView *footer = [[UIView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"chat_translation"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *tag = [[UILabel alloc] init];
    tag.translatesAutoresizingMaskIntoConstraints = NO;
    tag.text = chatLocalizable(@"chat_translate_tag");
    tag.font = [UIFont systemFontOfSize:12];
    tag.textColor = UIColor.normalChatTranslationTagColor;
    [tag setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [tag setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [footer addSubview:icon];
    [footer addSubview:tag];
    [container addSubview:divider];
    [container addSubview:textLabel];
    [container addSubview:footer];
    [NSLayoutConstraint activateConstraints:@[
        [divider.topAnchor constraintEqualToAnchor:container.topAnchor constant:6],
        [divider.leftAnchor constraintEqualToAnchor:container.leftAnchor],
        [divider.rightAnchor constraintEqualToAnchor:container.rightAnchor],
        [divider.heightAnchor constraintEqualToConstant:0.5],
        [textLabel.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12],
        [textLabel.leftAnchor constraintEqualToAnchor:container.leftAnchor],
        [textLabel.rightAnchor constraintEqualToAnchor:container.rightAnchor],
        [footer.topAnchor constraintEqualToAnchor:textLabel.bottomAnchor constant:6],
        [footer.leftAnchor constraintEqualToAnchor:container.leftAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [footer.heightAnchor constraintEqualToConstant:20],
        [icon.leftAnchor constraintEqualToAnchor:footer.leftAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:14],
        [icon.heightAnchor constraintEqualToConstant:14],
        [tag.leftAnchor constraintEqualToAnchor:icon.rightAnchor constant:4],
        [tag.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [tag.rightAnchor constraintEqualToAnchor:footer.rightAnchor],
    ]];
    if (isSend) self.translationTextLabelRight = textLabel;
    else self.translationTextLabelLeft = textLabel;
    return container;
}

- (void)bindTranslation:(MessageTextModel *)model isSend:(BOOL)isSend {
    UIView *area = isSend ? self.translationAreaRight : self.translationAreaLeft;
    UILabel *label = isSend ? self.translationTextLabelRight : self.translationTextLabelLeft;
    NSLayoutConstraint *zero = isSend ? self.translationAreaRightHeightZero : self.translationAreaLeftHeightZero;
    BOOL visible = model.translationVisible && model.translationInfo.translatedText.length > 0 && !model.inMultiForward;
    BOOL failure = model.translationVisible && model.translationFailed && !model.inMultiForward;
    label.text = failure ? chatLocalizable(@"chat_translate_failed_retry") : (visible ? model.translationInfo.translatedText : nil);
    label.textColor = failure ? UIColor.ne_normalTheme : UIColor.ne_darkText;
    zero.active = !(visible || failure);
    area.hidden = !(visible || failure);
}

- (void)onTranslationLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan &&
        [self.delegate respondsToSelector:@selector(didLongPressTranslationView:model:)]) {
        [self.delegate didLongPressTranslationView:self model:self.contentModel];
    }
}

- (void)onTranslationRetryTap:(UITapGestureRecognizer *)gesture {
    MessageTextModel *model = [self.contentModel isKindOfClass:[MessageTextModel class]]
        ? (MessageTextModel *)self.contentModel
        : nil;
    if (gesture.state == UIGestureRecognizerStateEnded && model.translationFailed &&
        [self.delegate respondsToSelector:@selector(didTapTranslationRetryView:model:)]) {
        [self.delegate didTapTranslationRetryView:self model:model];
    }
}

- (UIView *)translationAreaLeft {
    if (!_translationAreaLeft) _translationAreaLeft = [self makeTranslationArea:NO];
    return _translationAreaLeft;
}

- (UIView *)translationAreaRight {
    if (!_translationAreaRight) _translationAreaRight = [self makeTranslationArea:YES];
    return _translationAreaRight;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (void)selectText {
    NEChatTextView *contentLabel = self.contentLabelLeft.hidden ? self.contentLabelRight : self.contentLabelLeft;
    NSRange range = contentLabel.selectedRange;
    self.contentModel.selectRange = [NSValue valueWithRange:range];
    [self.delegate didLongPressMessageView:self model:self.contentModel];
    if (self.contentModel.selectRange != nil && self.contentModel.selectRange.rangeValue.length > 0) {
        [contentLabel becomeFirstResponder];
    } else {
        [contentLabel resignFirstResponder];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.isLongPress && self.contentModel.selectRange == nil) {
        [self selectAllRange];
        return;
    }
    if (textView.selectedRange.length == 0 || self.contentModel.selectRange == nil) {
        [self tapFunc];
    } else {
        [self selectText];
    }
}

- (CGSize)getTextSize:(nullable NSAttributedString *)attributedText {
    return [NSAttributedString getRealTextViewSize:attributedText
                                              font:self.messageTextFont
                                              size:self.contentModel.messageMaxSize];
}

- (void)contentSizeToFit:(UITextView *)contentLabel model:(MessageTextModel *)model {
    CGSize titleSize = [self getTextSize:contentLabel.attributedText];
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

@end
