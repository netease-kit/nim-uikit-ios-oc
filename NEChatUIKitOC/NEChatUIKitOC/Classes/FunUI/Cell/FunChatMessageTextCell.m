// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageTextCell.h"
#import <NEChatKit/NSString+NECommon.h>
#import "ChatCellConstantValue.h"
#import "MessageTextModel.h"
#import "NEChatUIConstant.h"
#import "UIImage+Chat.h"

@interface FunChatMessageTextCell ()
@property (nonatomic, strong) UIView *translationBubbleLeft;
@property (nonatomic, strong) UIView *translationBubbleRight;
@property (nonatomic, strong) UILabel *translationTextLeft;
@property (nonatomic, strong) UILabel *translationTextRight;
@property (nonatomic, strong) NSLayoutConstraint *replyViewLeftTopToBubble;
@property (nonatomic, strong) NSLayoutConstraint *replyViewLeftTopToTranslation;
@property (nonatomic, strong) NSLayoutConstraint *replyViewRightTopToBubble;
@property (nonatomic, strong) NSLayoutConstraint *replyViewRightTopToTranslation;
@property (nonatomic, strong) NSLayoutConstraint *translationBubbleWidthLeft;
@property (nonatomic, strong) NSLayoutConstraint *translationBubbleWidthRight;
@end

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
    [self deactivateTopConstraintsForView:self.replyViewLeft];
    self.replyViewLeftTopToBubble = [self.replyViewLeft.topAnchor constraintEqualToAnchor:self.reactionViewLeft.bottomAnchor];
    self.replyViewLeftTopToTranslation = [self.replyViewLeft.topAnchor constraintEqualToAnchor:self.translationBubbleLeft.bottomAnchor];
    [self.contentView addSubview:self.translationBubbleLeft];
    [NSLayoutConstraint activateConstraints:@[
        self.replyViewLeftTopToBubble,
        [self.translationBubbleLeft.topAnchor constraintEqualToAnchor:self.reactionViewLeft.bottomAnchor constant:4],
        [self.translationBubbleLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:self.funMargin],
        [self messageWidthConstraint:self.translationBubbleLeft.widthAnchor inset:self.funMargin],
        [self.translationBubbleLeft.widthAnchor constraintGreaterThanOrEqualToConstant:[self translationBubbleMinWidth]],
    ]];
    self.translationBubbleWidthLeft = [self.translationBubbleLeft.widthAnchor constraintEqualToConstant:[self translationBubbleMinWidth]];
    self.translationBubbleWidthLeft.priority = UILayoutPriorityDefaultHigh;
    self.translationBubbleWidthLeft.active = YES;
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
    [self deactivateTopConstraintsForView:self.replyViewRight];
    self.replyViewRightTopToBubble = [self.replyViewRight.topAnchor constraintEqualToAnchor:self.reactionViewRight.bottomAnchor];
    self.replyViewRightTopToTranslation = [self.replyViewRight.topAnchor constraintEqualToAnchor:self.translationBubbleRight.bottomAnchor];
    [self.contentView addSubview:self.translationBubbleRight];
    [NSLayoutConstraint activateConstraints:@[
        self.replyViewRightTopToBubble,
        [self.translationBubbleRight.topAnchor constraintEqualToAnchor:self.reactionViewRight.bottomAnchor constant:4],
        [self.translationBubbleRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-self.funMargin],
        [self messageWidthConstraint:self.translationBubbleRight.widthAnchor inset:self.funMargin],
        [self.translationBubbleRight.widthAnchor constraintGreaterThanOrEqualToConstant:[self translationBubbleMinWidth]],
    ]];
    self.translationBubbleWidthRight = [self.translationBubbleRight.widthAnchor constraintEqualToConstant:[self translationBubbleMinWidth]];
    self.translationBubbleWidthRight.priority = UILayoutPriorityDefaultHigh;
    self.translationBubbleWidthRight.active = YES;
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentLabelLeft.hidden = showRight;
    self.contentLabelRight.hidden = !showRight;
    self.translationBubbleLeft.hidden = YES;
    self.translationBubbleRight.hidden = YES;
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
        [self bindTranslation:m isSend:isSend];
        [self updateReplyConstraints:isSend isReply:model.isReply hasTranslation:[self hasVisibleTranslation:m]];
    }
    if ([model isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *textModel = (MessageTextModel *)model;
        NEMessageReactionView *reactionView = isSend ? self.reactionViewRight : self.reactionViewLeft;
        CGFloat leadingInset = [self reactionLeadingInsetForModel:textModel isOutgoing:isSend];
        CGFloat trailingInset = [self reactionTrailingInsetForModel:textModel isOutgoing:isSend];
        CGFloat reactionMaxWidth = MAX(26.0, self.chatContentMaxW - leadingInset - trailingInset);
        CGFloat reactionWidth = MIN(reactionMaxWidth,
                                    MAX([reactionView layoutWidthForMaxWidth:reactionMaxWidth], 26.0));
        bubbleW.constant = MAX(bubbleW.constant,
                               MAX(textModel.contentSize.width + self.funMargin,
                                   reactionWidth + leadingInset + trailingInset));
    } else {
        bubbleW.constant += self.funMargin;
    }
}

- (CGFloat)translationBubbleMinWidth {
    CGFloat tagWidth = [chatLocalizable(@"chat_translate_tag") sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}].width;
    CGFloat horizontalInset = chat_content_margin + self.funMargin;
    return horizontalInset * 2 + 14 + 4 + ceil(tagWidth);
}

- (void)deactivateTopConstraintsForView:(UIView *)view {
    for (NSLayoutConstraint *constraint in self.contentView.constraints) {
        if (constraint.firstItem == view && constraint.firstAttribute == NSLayoutAttributeTop) {
            constraint.active = NO;
        }
    }
}

- (UIView *)makeTranslationBubble:(BOOL)isSend {
    UIView *bubble = [[UIView alloc] init];
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    bubble.backgroundColor = UIColor.whiteColor;
    bubble.layer.cornerRadius = 4;
    bubble.layer.masksToBounds = YES;
    bubble.hidden = YES;
    UIImageView *backgroundView = [[UIImageView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.contentMode = UIViewContentModeScaleToFill;
    backgroundView.image = [self translationBubbleImageForSend:isSend];
    [bubble addSubview:backgroundView];
    [bubble sendSubviewToBack:backgroundView];
    [NSLayoutConstraint activateConstraints:@[
        [backgroundView.leftAnchor constraintEqualToAnchor:bubble.leftAnchor],
        [backgroundView.rightAnchor constraintEqualToAnchor:bubble.rightAnchor],
        [backgroundView.topAnchor constraintEqualToAnchor:bubble.topAnchor],
        [backgroundView.bottomAnchor constraintEqualToAnchor:bubble.bottomAnchor],
    ]];
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.numberOfLines = 0;
    textLabel.font = self.messageTextFont;
    textLabel.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0];
    textLabel.accessibilityIdentifier = @"id.translationText";
    textLabel.userInteractionEnabled = YES;
    [textLabel addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTranslationLongPress:)]];
    [textLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTranslationRetryTap:)]];
    UIView *footer = [[UIView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"chat_translation"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *tag = [[UILabel alloc] init];
    tag.translatesAutoresizingMaskIntoConstraints = NO;
    tag.text = chatLocalizable(@"chat_translate_tag");
    tag.font = [UIFont systemFontOfSize:12];
    tag.textColor = [UIColor colorWithWhite:0 alpha:0.4];
    [tag setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [tag setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [footer addSubview:icon];
    [footer addSubview:tag];
    [bubble addSubview:textLabel];
    [bubble addSubview:footer];
    [NSLayoutConstraint activateConstraints:@[
        [textLabel.topAnchor constraintEqualToAnchor:bubble.topAnchor constant:8],
        [textLabel.leftAnchor constraintEqualToAnchor:bubble.leftAnchor constant:chat_content_margin + self.funMargin],
        [textLabel.rightAnchor constraintEqualToAnchor:bubble.rightAnchor constant:-chat_content_margin - self.funMargin],
        [footer.topAnchor constraintEqualToAnchor:textLabel.bottomAnchor constant:6],
        [footer.leftAnchor constraintEqualToAnchor:bubble.leftAnchor constant:chat_content_margin + self.funMargin],
        [footer.bottomAnchor constraintEqualToAnchor:bubble.bottomAnchor constant:-8],
        [footer.heightAnchor constraintEqualToConstant:20],
        [icon.leftAnchor constraintEqualToAnchor:footer.leftAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:14],
        [icon.heightAnchor constraintEqualToConstant:14],
        [tag.leftAnchor constraintEqualToAnchor:icon.rightAnchor constant:4],
        [tag.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
        [tag.rightAnchor constraintEqualToAnchor:footer.rightAnchor],
    ]];
    if (isSend) self.translationTextRight = textLabel;
    else self.translationTextLeft = textLabel;
    return bubble;
}

- (UIImage *)translationBubbleImageForSend:(BOOL)isSend {
    MessageProperties *properties = [ChatUIConfig shared].messageProperties;
    UIImage *image = isSend ? properties.selfMessageBgImage : properties.receiveMessageBgImage;
    if (!image) image = chatLoadImage(isSend ? @"chat_message_send_fun" : @"chat_message_receive_fun");
    UIEdgeInsets capInsets = properties.backgroundImageCapInsets;
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        image = [image resizableImageWithCapInsets:capInsets];
    }
    return image;
}

- (BOOL)hasVisibleTranslation:(MessageTextModel *)model {
    return (model.translationFailed || model.translationInfo.translatedText.length > 0) && model.translationVisible && !model.inMultiForward;
}

- (void)bindTranslation:(MessageTextModel *)model isSend:(BOOL)isSend {
    UIView *bubble = isSend ? self.translationBubbleRight : self.translationBubbleLeft;
    UILabel *label = isSend ? self.translationTextRight : self.translationTextLeft;
    BOOL visible = [self hasVisibleTranslation:model];
    BOOL failure = model.translationFailed && model.translationVisible && !model.inMultiForward;
    label.text = failure ? chatLocalizable(@"chat_translate_failed_retry") : (visible ? model.translationInfo.translatedText : nil);
    label.textColor = failure ? UIColor.ne_normalTheme : UIColor.blackColor;
    if (visible) {
        CGFloat minWidth = [self translationBubbleMinWidth];
        CGFloat maxWidth = MAX(minWidth, self.chatContentMaxW - self.funMargin);
        CGFloat horizontalInset = chat_content_margin + self.funMargin;
        CGFloat measuredWidth = [model estimateTranslationTextWidth] + horizontalInset * 2.0;
        CGFloat width = MIN(maxWidth, MAX(minWidth, measuredWidth));
        if (isSend) self.translationBubbleWidthRight.constant = width;
        else self.translationBubbleWidthLeft.constant = width;
    }
    bubble.hidden = !visible;
}

- (void)updateReplyConstraints:(BOOL)isSend isReply:(BOOL)isReply hasTranslation:(BOOL)hasTranslation {
    if (isSend) {
        self.replyViewRightTopToBubble.active = !isReply || !hasTranslation;
        self.replyViewRightTopToTranslation.active = isReply && hasTranslation;
    } else {
        self.replyViewLeftTopToBubble.active = !isReply || !hasTranslation;
        self.replyViewLeftTopToTranslation.active = isReply && hasTranslation;
    }
}

- (void)onTranslationLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan &&
        [self.delegate respondsToSelector:@selector(didLongPressTranslationView:model:)]) {
        [self.delegate didLongPressTranslationView:self model:self.contentModel];
    }
}

- (void)onTranslationRetryTap:(UITapGestureRecognizer *)gesture {
    MessageTextModel *model = [self.contentModel isKindOfClass:[MessageTextModel class]] ? (MessageTextModel *)self.contentModel : nil;
    if (gesture.state == UIGestureRecognizerStateEnded && model.translationFailed &&
        [self.delegate respondsToSelector:@selector(didTapTranslationRetryView:model:)]) {
        [self.delegate didTapTranslationRetryView:self model:model];
    }
}

- (UIView *)translationBubbleLeft {
    if (!_translationBubbleLeft) _translationBubbleLeft = [self makeTranslationBubble:NO];
    return _translationBubbleLeft;
}

- (UIView *)translationBubbleRight {
    if (!_translationBubbleRight) _translationBubbleRight = [self makeTranslationBubble:YES];
    return _translationBubbleRight;
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
