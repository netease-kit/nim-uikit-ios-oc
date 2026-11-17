// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageBaseCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEEmotionTool.h"
#import "FunChatUIColor.h"
#import "NEChatUIConstant.h"
#import <NEBaseUIKitOC/UIView+YXToast.h>

@implementation FunChatMessageBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _funMargin = 5.2;
        _replyHeight = 52;
        [self commonUI];
        [self addReplyGesture];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)commonUI {
    [self commonUIRight];
    [self commonUILeft];
}

- (void)commonUILeft {
    [self.contentView addSubview:self.replyViewLeft];
    self.replyViewLeftHeightAnchor = [self.replyViewLeft.heightAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.replyViewLeftHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewLeft.topAnchor constraintEqualToAnchor:self.reactionViewLeft.bottomAnchor constant:0],
        [self.replyViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:self.funMargin],
        [self messageWidthConstraint:self.replyViewLeft.widthAnchor inset:self.funMargin],
    ]];
}

- (void)commonUIRight {
    [self.contentView addSubview:self.replyViewRight];
    self.replyViewRightHeightAnchor = [self.replyViewRight.heightAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.replyViewRightHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewRight.topAnchor constraintEqualToAnchor:self.reactionViewRight.bottomAnchor constant:0],
        [self.replyViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-self.funMargin],
        [self messageWidthConstraint:self.replyViewRight.widthAnchor inset:self.funMargin],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.replyViewLeft.hidden = showRight;
    self.replyTextViewLeft.hidden = showRight;
    self.replyLabelLeft.hidden = showRight;
    self.replyViewRight.hidden = !showRight;
    self.replyTextViewRight.hidden = !showRight;
    self.replyLabelRight.hidden = !showRight;
}

- (void)addReplyGesture {
    UITapGestureRecognizer *replyViewTapLeft = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReplyView:)];
    replyViewTapLeft.cancelsTouchesInView = YES;
    [self.replyViewLeft addGestureRecognizer:replyViewTapLeft];

    UITapGestureRecognizer *replyViewTapRight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReplyView:)];
    replyViewTapRight.cancelsTouchesInView = YES;
    [self.replyViewRight addGestureRecognizer:replyViewTapRight];
}

- (void)tapReplyView:(UITapGestureRecognizer *)tap {
    [self.delegate didTapMessageView:self model:self.contentModel replyModel:self.contentModel.replyedModel];
}

- (void)showReplyView:(BOOL)isSend show:(BOOL)show {
    UILabel *replyLabel = isSend ? self.replyLabelRight : self.replyLabelLeft;
    UIView *replyTextView = isSend ? self.replyTextViewRight : self.replyTextViewLeft;
    UIView *replyView = isSend ? self.replyViewRight : self.replyViewLeft;
    NSLayoutConstraint *replyViewHeightAnchor = isSend ? self.replyViewRightHeightAnchor : self.replyViewLeftHeightAnchor;
    // Revoke rows clear this reusable view's background. Restore it whenever
    // a normal replied message is rendered after that cell is reused.
    replyTextView.backgroundColor = [UIColor funChatReplyViewBg];
    replyLabel.hidden = !show;
    replyTextView.hidden = !show;
    replyView.hidden = !show;
    replyViewHeightAnchor.constant = show ? self.replyHeight : 0;
}

- (void)setBubbleImage {
    // Fun cells share the reaction-aware base implementation, but their
    // directional bubble assets are skin-specific. Keep this override in
    // place for reuse paths that recreate the bubble after Reaction updates.
    UIImage *image = [ChatUIConfig shared].messageProperties.receiveMessageBgImage ?: chatLoadImage(@"chat_message_receive_fun");
    self.bubbleImageLeft.backgroundColor = [ChatUIConfig shared].messageProperties.receiveMessageBgColor;
    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        self.bubbleImageLeft.image = [image resizableImageWithCapInsets:capInsets];
        self.bubbleImageLeft.contentMode = UIViewContentModeScaleToFill;
    } else {
        self.bubbleImageLeft.image = image;
        self.bubbleImageLeft.contentMode = UIViewContentModeScaleAspectFill;
    }

    image = [ChatUIConfig shared].messageProperties.selfMessageBgImage ?: chatLoadImage(@"chat_message_send_fun");
    self.bubbleImageRight.backgroundColor = [ChatUIConfig shared].messageProperties.selfMessageBgColor;
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        self.bubbleImageRight.image = [image resizableImageWithCapInsets:capInsets];
        self.bubbleImageRight.contentMode = UIViewContentModeScaleToFill;
    } else {
        self.bubbleImageRight.image = image;
        self.bubbleImageRight.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (CGFloat)reactionLeadingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    if ([self usesFixedReactionSurfaceForModel:model]) {
        return 8.0 + (isOutgoing ? 0.0 :
            [self reactionBackdropTailInsetForModel:model isOutgoing:isOutgoing]) +
            [self reactionBodyPaddingForModel:model];
    }
    return chat_content_margin + (isOutgoing ? 0.0 : self.funMargin);
}

- (CGFloat)reactionTrailingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    if ([self usesFixedReactionSurfaceForModel:model]) {
        return 8.0 + (isOutgoing ?
            [self reactionBackdropTailInsetForModel:model isOutgoing:isOutgoing] : 0.0) +
            [self reactionBodyPaddingForModel:model];
    }
    return chat_content_margin + (isOutgoing ? self.funMargin : 0.0);
}

- (CGFloat)reactionBackdropTailInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    return [self usesFixedReactionSurfaceForModel:model] ? self.funMargin : 0.0;
}

- (CGFloat)reactionTopSpacingForModel:(MessageContentModel *)model {
    if (model.type == MessageTypeRichText ||
        model.type == MessageTypeMultiForward) {
        return 0.0;
    }
    return [super reactionTopSpacingForModel:model];
}

- (CGFloat)reactionBottomSpacingForModel:(MessageContentModel *)model {
    if (model.type == MessageTypeLocation) {
        return [super reactionTopSpacingForModel:model];
    }
    return [super reactionBottomSpacingForModel:model];
}

- (UIImage *)reactionBackdropImageForOutgoing:(BOOL)isOutgoing {
    MessageProperties *properties = [ChatUIConfig shared].messageProperties;
    UIImage *image = isOutgoing ? properties.selfMessageBgImage : properties.receiveMessageBgImage;
    if (!image) {
        image = chatLoadImage(isOutgoing ? @"chat_message_send_fun" : @"chat_message_receive_fun");
    }
    UIEdgeInsets capInsets = properties.backgroundImageCapInsets;
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        image = [image resizableImageWithCapInsets:capInsets];
    }
    return image;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UILabel *replyLabel = isSend ? self.replyLabelRight : self.replyLabelLeft;

    if (!model.isRevoked && model.replyText.length > 0 && replyLabel.font) {
        replyLabel.attributedText = [NEEmotionTool getAttWithStr:model.replyText font:replyLabel.font color:replyLabel.textColor offset:CGPointMake(0, -4)];
        replyLabel.accessibilityValue = model.replyText;
        [self showReplyView:isSend show:YES];
    } else {
        replyLabel.text = nil;
        [self showReplyView:isSend show:NO];
    }
}

- (void)initProperty {
    [super initProperty];

    self.readView.borderLayer.strokeColor = [UIColor funChatThemeColor].CGColor;
    self.readView.sectorLayer.fillColor = [UIColor funChatThemeColor].CGColor;

    UIImage *image = [ChatUIConfig shared].messageProperties.receiveMessageBgImage ?: chatLoadImage(@"chat_message_receive_fun");
    if ([ChatUIConfig shared].messageProperties.backgroundImageCapInsets.top != 0 ||
        [ChatUIConfig shared].messageProperties.backgroundImageCapInsets.left != 0) {
        self.bubbleImageLeft.image = [image resizableImageWithCapInsets:[ChatUIConfig shared].messageProperties.backgroundImageCapInsets];
    } else {
        self.bubbleImageLeft.image = image;
        self.bubbleImageLeft.contentMode = UIViewContentModeScaleAspectFill;
    }

    image = [ChatUIConfig shared].messageProperties.selfMessageBgImage ?: chatLoadImage(@"chat_message_send_fun");
    if ([ChatUIConfig shared].messageProperties.backgroundImageCapInsets.top != 0 ||
        [ChatUIConfig shared].messageProperties.backgroundImageCapInsets.left != 0) {
        self.bubbleImageRight.image = [image resizableImageWithCapInsets:[ChatUIConfig shared].messageProperties.backgroundImageCapInsets];
    } else {
        self.bubbleImageRight.image = image;
        self.bubbleImageRight.contentMode = UIViewContentModeScaleAspectFill;
    }

    [self.selectedButton setImage:[coreLoader() loadImage:@"fun_select"] forState:UIControlStateSelected];
}

- (void)baseCommonUI {
    [super baseCommonUI];

    [self.userHeaderViewLeft updateLayoutConstraintFirstItem:self.userHeaderViewLeft
                                                 secondItem:self.userHeaderViewLeft
                                                  attribute:NSLayoutAttributeWidth
                                                   constant:fun_chat_min_h];
    [self.userHeaderViewLeft updateLayoutConstraintFirstItem:self.userHeaderViewLeft
                                                 secondItem:self.userHeaderViewLeft
                                                  attribute:NSLayoutAttributeHeight
                                                   constant:fun_chat_min_h];

    [self.userHeaderViewRight updateLayoutConstraintFirstItem:self.userHeaderViewRight
                                                  secondItem:self.userHeaderViewRight
                                                   attribute:NSLayoutAttributeWidth
                                                    constant:fun_chat_min_h];
    [self.userHeaderViewRight updateLayoutConstraintFirstItem:self.userHeaderViewRight
                                                  secondItem:self.userHeaderViewRight
                                                   attribute:NSLayoutAttributeHeight
                                                    constant:fun_chat_min_h];

    [self.contentView updateLayoutConstraintFirstItem:self.fullNameLabel
                                          secondItem:self.userHeaderViewLeft
                                           attribute:NSLayoutAttributeLeft
                                            constant:8 + self.funMargin];
    [self.contentView updateLayoutConstraintFirstItem:self.fullNameLabel
                                          secondItem:self.userHeaderViewLeft
                                           attribute:NSLayoutAttributeTop
                                            constant:-4];

    [self.contentView updateLayoutConstraintFirstItem:self.pinLabelLeft
                                          secondItem:self.bubbleImageLeft
                                           attribute:NSLayoutAttributeLeft
                                            constant:14 + self.funMargin];
    [self.contentView updateLayoutConstraintFirstItem:self.pinLabelRight
                                          secondItem:self.bubbleImageRight
                                           attribute:NSLayoutAttributeRight
                                            constant:-self.funMargin];
}

- (void)initSubviewsLayout {
    if ([ChatUIConfig shared].messageProperties.avatarType == NEChatAvatarTypeCycle) {
        self.userHeaderViewRight.layer.cornerRadius = 21.0;
        self.userHeaderViewLeft.layer.cornerRadius = 21.0;
    } else if ([ChatUIConfig shared].messageProperties.avatarCornerRadius > 0) {
        self.userHeaderViewRight.layer.cornerRadius = [ChatUIConfig shared].messageProperties.avatarCornerRadius;
        self.userHeaderViewLeft.layer.cornerRadius = [ChatUIConfig shared].messageProperties.avatarCornerRadius;
    } else {
        self.userHeaderViewRight.layer.cornerRadius = 4;
        self.userHeaderViewLeft.layer.cornerRadius = 4;
    }
}

#pragma mark - Lazy Load

- (UILabel *)replyLabelLeft {
    if (!_replyLabelLeft) {
        _replyLabelLeft = [[UILabel alloc] init];
        _replyLabelLeft.numberOfLines = 2;
        _replyLabelLeft.textColor = [UIColor ne_greyText];
        _replyLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyLabelLeft.font = [UIFont systemFontOfSize:13];
        _replyLabelLeft.accessibilityIdentifier = @"id.messageReply";
    }
    return _replyLabelLeft;
}

- (UIView *)replyTextViewLeft {
    if (!_replyTextViewLeft) {
        _replyTextViewLeft = [[UIView alloc] init];
        _replyTextViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyTextViewLeft.backgroundColor = [UIColor funChatReplyViewBg];
        _replyTextViewLeft.layer.cornerRadius = 4;
        _replyTextViewLeft.accessibilityIdentifier = @"id.replyTextView";

        [_replyTextViewLeft addSubview:self.replyLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyLabelLeft.topAnchor constraintEqualToAnchor:_replyTextViewLeft.topAnchor constant:4],
            [self.replyLabelLeft.bottomAnchor constraintEqualToAnchor:_replyTextViewLeft.bottomAnchor constant:-4],
            [self.replyLabelLeft.leftAnchor constraintEqualToAnchor:_replyTextViewLeft.leftAnchor constant:12],
            [self.replyLabelLeft.rightAnchor constraintEqualToAnchor:_replyTextViewLeft.rightAnchor constant:-12],
        ]];
    }
    return _replyTextViewLeft;
}

- (UIView *)replyViewLeft {
    if (!_replyViewLeft) {
        _replyViewLeft = [[UIView alloc] init];
        _replyViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyViewLeft.backgroundColor = [UIColor clearColor];

        [_replyViewLeft addSubview:self.replyTextViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyTextViewLeft.topAnchor constraintEqualToAnchor:_replyViewLeft.topAnchor constant:chat_content_margin],
            [self.replyTextViewLeft.bottomAnchor constraintEqualToAnchor:_replyViewLeft.bottomAnchor constant:0],
            [self.replyTextViewLeft.leftAnchor constraintEqualToAnchor:_replyViewLeft.leftAnchor constant:0],
            [self.replyTextViewLeft.rightAnchor constraintEqualToAnchor:_replyViewLeft.rightAnchor constant:0],
        ]];
    }
    return _replyViewLeft;
}

- (UILabel *)replyLabelRight {
    if (!_replyLabelRight) {
        _replyLabelRight = [[UILabel alloc] init];
        _replyLabelRight.numberOfLines = 2;
        _replyLabelRight.textColor = [UIColor ne_greyText];
        _replyLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyLabelRight.font = [UIFont systemFontOfSize:13];
        _replyLabelRight.accessibilityIdentifier = @"id.messageReply";
    }
    return _replyLabelRight;
}

- (UIView *)replyTextViewRight {
    if (!_replyTextViewRight) {
        _replyTextViewRight = [[UIView alloc] init];
        _replyTextViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyTextViewRight.backgroundColor = [UIColor funChatReplyViewBg];
        _replyTextViewRight.layer.cornerRadius = 4;
        _replyTextViewRight.accessibilityIdentifier = @"id.replyTextView";

        [_replyTextViewRight addSubview:self.replyLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyLabelRight.topAnchor constraintEqualToAnchor:_replyTextViewRight.topAnchor constant:4],
            [self.replyLabelRight.bottomAnchor constraintEqualToAnchor:_replyTextViewRight.bottomAnchor constant:-4],
            [self.replyLabelRight.leftAnchor constraintEqualToAnchor:_replyTextViewRight.leftAnchor constant:12],
            [self.replyLabelRight.rightAnchor constraintEqualToAnchor:_replyTextViewRight.rightAnchor constant:-12],
        ]];
    }
    return _replyTextViewRight;
}

- (UIView *)replyViewRight {
    if (!_replyViewRight) {
        _replyViewRight = [[UIView alloc] init];
        _replyViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyViewRight.backgroundColor = [UIColor clearColor];

        [_replyViewRight addSubview:self.replyTextViewRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyTextViewRight.topAnchor constraintEqualToAnchor:_replyViewRight.topAnchor constant:chat_content_margin],
            [self.replyTextViewRight.bottomAnchor constraintEqualToAnchor:_replyViewRight.bottomAnchor constant:0],
            [self.replyTextViewRight.leftAnchor constraintEqualToAnchor:_replyViewRight.leftAnchor constant:0],
            [self.replyTextViewRight.rightAnchor constraintEqualToAnchor:_replyViewRight.rightAnchor constant:0],
        ]];
    }
    return _replyViewRight;
}

- (void)setReplyViewLeftHeight:(CGFloat)replyViewLeftHeight {
    _replyViewLeftHeight = replyViewLeftHeight;
    self.replyTextViewLeft.hidden = replyViewLeftHeight == 0;
    self.replyViewLeftHeightAnchor.constant = replyViewLeftHeight;
}

@end
