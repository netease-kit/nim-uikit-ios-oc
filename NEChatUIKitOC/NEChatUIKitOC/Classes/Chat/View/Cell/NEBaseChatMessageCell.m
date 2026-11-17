// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatMessageCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/NEChatKit.h>

#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NSString+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "ChatMessageHelper.h"
#import "MessageContentModel.h"
#import "NEChatUIConstant.h"

static const CGFloat kPinLabelMaxWidth = 280.0;
static const CGFloat kReactionHorizontalPadding = 8.0;
// Media content is full-bleed, while the Reaction row keeps the 4pt design
// inset so both edges stay inside the image/card surface.
static const CGFloat kReactionMediaHorizontalPadding = 4.0;
// Keep a visible gap between fixed-format image/video/file bodies and the expanded
// Reaction surface without changing the measured body size.
static const CGFloat kReactionMediaBodyPadding = 4.0;
static const CGFloat kReactionBottomPadding = 8.0;

@interface NEBaseChatMessageCell ()
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelHLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelWLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelHRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelWRight;
@property (nonatomic, strong, nullable) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionWidthLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionHeightLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionWidthRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionHeightRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionLeadingLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionTrailingLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionLeadingRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionTrailingRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropLeadingLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropTrailingRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropTopAnchorLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropTopAnchorRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropWidthLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropHeightLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropWidthRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionBackdropHeightRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleLeadingLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleTrailingRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *readViewRightToBubbleAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *readViewRightToReactionBackdropAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *readViewBottomAnchor;
- (void)updateReadViewPositionForOutgoing:(BOOL)isOutgoing
                     usesReactionBackdrop:(BOOL)usesReactionBackdrop
                             bottomOffset:(CGFloat)bottomOffset;
- (BOOL)locksReactionSurfaceToMessageWidthForModel:(MessageContentModel *)model;
- (void)updateReactionSurfacePositionWithMessageWidth:(CGFloat)messageWidth
                                        backdropWidth:(CGFloat)backdropWidth
                                             tailInset:(CGFloat)tailInset
                                           bodyPadding:(CGFloat)bodyPadding
                                            isOutgoing:(BOOL)isOutgoing;
@end

@implementation NEBaseChatMessageCell

- (CGFloat)pinLabelMaxWidth {
    return kPinLabelMaxWidth;
}

- (BOOL)supportsReactionLongPress {
    return YES;
}

- (BOOL)usesInlineReactionSurface {
    return NO;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initProperty];
        [self baseCommonUI];
        [self addGesture];
        [self initSubviewsLayout];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)dealloc {
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        [self removeGestureRecognizer:gesture];
    }
}

- (void)layoutSubviews {
    // Resolve the supplemental surface before UIKit lays out this pass.
    [self updateReactionSurface:self.reactionViewLeft backdrop:self.reactionBackdropLeft bubble:self.bubbleImageLeft];
    [self updateReactionSurface:self.reactionViewRight backdrop:self.reactionBackdropRight bubble:self.bubbleImageRight];
    [super layoutSubviews];
    [self.contentView bringSubviewToFront:self.bubbleImageLeft];
    [self.contentView bringSubviewToFront:self.bubbleImageRight];
    [self.contentView bringSubviewToFront:self.reactionViewLeft];
    [self.contentView bringSubviewToFront:self.reactionViewRight];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // A cell can be reused by a revoke/media row immediately after a reacted
    // row. Remove the supplemental surface before Auto Layout renders the old
    // model for one frame.
    [self resetReactionSurfaceForReuse];
    self.contentModel = nil;
}

- (void)setBubbleImage {
    UIImage *image = [ChatUIConfig shared].messageProperties.receiveMessageBgImage
        ?: chatLoadImage(@"chat_message_receive");
    self.bubbleImageLeft.backgroundColor = [ChatUIConfig shared].messageProperties.receiveMessageBgColor;

    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        self.bubbleImageLeft.image = [image resizableImageWithCapInsets:capInsets];
    } else {
        self.bubbleImageLeft.image = image;
        self.bubbleImageLeft.contentMode = UIViewContentModeScaleAspectFill;
    }

    image = [ChatUIConfig shared].messageProperties.selfMessageBgImage
        ?: chatLoadImage(@"chat_message_send");
    self.bubbleImageRight.backgroundColor = [ChatUIConfig shared].messageProperties.selfMessageBgColor;

    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        self.bubbleImageRight.image = [image resizableImageWithCapInsets:capInsets];
    } else {
        self.bubbleImageRight.image = image;
        self.bubbleImageRight.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)initProperty {
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.timeTextSize];
    self.timeLabel.textColor = [ChatUIConfig shared].messageProperties.timeTextColor;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.accessibilityIdentifier = @"id.messageTimeText";
    self.timeLabel.backgroundColor = UIColor.clearColor;

    // avatar
    self.userHeaderViewLeft = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    self.userHeaderViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.userHeaderViewLeft.clipsToBounds = YES;
    self.userHeaderViewLeft.userInteractionEnabled = YES;
    self.userHeaderViewLeft.titleLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.userNickTextSize];
    self.userHeaderViewLeft.titleLabel.textColor = [ChatUIConfig shared].messageProperties.userNickColor;

    self.userHeaderViewRight = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    self.userHeaderViewRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.userHeaderViewRight.clipsToBounds = YES;
    self.userHeaderViewRight.userInteractionEnabled = YES;
    self.userHeaderViewRight.titleLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.userNickTextSize];
    self.userHeaderViewRight.titleLabel.textColor = [ChatUIConfig shared].messageProperties.userNickColor;

    // fullName
    self.fullNameLabel = [[UILabel alloc] init];
    self.fullNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fullNameLabel.font = [UIFont systemFontOfSize:12];
    self.fullNameLabel.textColor = UIColor.ne_lightText;
    self.fullNameLabel.accessibilityIdentifier = @"id.fullNameLabel";

    // bubbleImage
    self.bubbleImageLeft = [[UIImageView alloc] init];
    self.bubbleImageRight = [[UIImageView alloc] init];
    [self setBubbleImage];
    self.bubbleImageLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleImageLeft.userInteractionEnabled = YES;
    self.bubbleImageRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleImageRight.userInteractionEnabled = YES;

    self.reactionViewLeft = [[NEMessageReactionView alloc] initWithFrame:CGRectZero];
    self.reactionViewRight = [[NEMessageReactionView alloc] initWithFrame:CGRectZero];
    self.reactionViewLeft.delegate = self;
    self.reactionViewRight.delegate = self;
    self.reactionBackdropLeft = [[UIImageView alloc] init];
    self.reactionBackdropRight = [[UIImageView alloc] init];

    self.pinLabelLeft = [[UILabel alloc] init];
    self.pinLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.pinLabelLeft.textColor = UIColor.ne_greenText;
    self.pinLabelLeft.font = [UIFont systemFontOfSize:12];
    self.pinLabelLeft.textAlignment = NSTextAlignmentLeft;
    self.pinLabelLeft.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.pinLabelLeft.accessibilityIdentifier = @"id.signal";

    self.pinLabelRight = [[UILabel alloc] init];
    self.pinLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.pinLabelRight.textColor = UIColor.ne_greenText;
    self.pinLabelRight.font = [UIFont systemFontOfSize:12];
    self.pinLabelRight.textAlignment = NSTextAlignmentRight;
    self.pinLabelRight.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.pinLabelRight.accessibilityIdentifier = @"id.signal";

    self.pinImageLeft = [[UIImageView alloc] init];
    self.pinImageLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.pinImageLeft.contentMode = UIViewContentModeScaleAspectFit;

    self.pinImageRight = [[UIImageView alloc] init];
    self.pinImageRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.pinImageRight.contentMode = UIViewContentModeScaleAspectFit;

    self.readView = [[CirleProgressView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    self.readView.translatesAutoresizingMaskIntoConstraints = NO;
    self.readView.accessibilityIdentifier = @"id.readView";

    self.activityView = [[ChatActivityIndicatorView alloc] init];
    self.activityView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activityView.failButton addTarget:self action:@selector(resend:) forControlEvents:UIControlEventTouchUpInside];
    self.activityView.accessibilityIdentifier = @"id.status";

    self.selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.selectedButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectedButton setImage:[coreLoader() loadImage:@"unselect"] forState:UIControlStateNormal];
    [self.selectedButton setImage:[coreLoader() loadImage:@"select"] forState:UIControlStateSelected];
    [self.selectedButton addTarget:self action:@selector(selectButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    self.messageTextFont = [UIFont systemFontOfSize:16];
}

- (void)baseCommonUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;

    // time
    [self.contentView addSubview:self.timeLabel];
    self.timeLabelHeightAnchor = [self.timeLabel.heightAnchor constraintEqualToConstant:22];
    self.timeLabelHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [self.timeLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0],
        [self.timeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
    ]];

    [self baseCommonUILeft];
    [self baseCommonUIRight];
}

- (void)baseCommonUILeft {
    [self.contentView addSubview:self.userHeaderViewLeft];
    self.avatarImageLeftAnchor = [self.userHeaderViewLeft.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16];
    self.avatarImageLeftAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.userHeaderViewLeft.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:chat_content_margin],
        [self.userHeaderViewLeft.widthAnchor constraintEqualToConstant:32],
        [self.userHeaderViewLeft.heightAnchor constraintEqualToConstant:32],
    ]];

    [self.contentView addSubview:self.fullNameLabel];
    self.fullNameH = [self.fullNameLabel.heightAnchor constraintEqualToConstant:20];
    self.fullNameH.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.fullNameLabel.leftAnchor constraintEqualToAnchor:self.userHeaderViewLeft.rightAnchor constant:chat_content_margin],
        [self.fullNameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
        [self.fullNameLabel.topAnchor constraintEqualToAnchor:self.userHeaderViewLeft.topAnchor],
    ]];

    [self.contentView addSubview:self.bubbleImageLeft];
    self.bubbleTopAnchorLeft = [self.bubbleImageLeft.topAnchor constraintEqualToAnchor:self.fullNameLabel.bottomAnchor constant:0];
    self.bubbleTopAnchorLeft.active = YES;
    // Content cells assign the measured message width in setModel. A finite
    // zero default keeps the Reaction sibling from participating in an
    // unconstrained max-width pass during cell reuse.
    self.bubbleWLeft = [self.bubbleImageLeft.widthAnchor constraintEqualToConstant:0];
    self.bubbleWLeft.active = YES;
    self.bubbleHLeft = [self.bubbleImageLeft.heightAnchor constraintEqualToConstant:0];
    self.bubbleHLeft.active = YES;
    self.bubbleLeadingLeft = [self.bubbleImageLeft.leftAnchor constraintEqualToAnchor:self.userHeaderViewLeft.rightAnchor
                                                                              constant:chat_content_margin];
    self.bubbleLeadingLeft.active = YES;

    self.reactionBackdropLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.reactionBackdropLeft.image = self.bubbleImageLeft.image;
    self.reactionBackdropLeft.backgroundColor = self.bubbleImageLeft.backgroundColor;
    self.reactionBackdropLeft.contentMode = self.bubbleImageLeft.contentMode;
    self.reactionBackdropLeft.userInteractionEnabled = YES;
    self.reactionBackdropLeft.hidden = YES;
    [self.contentView insertSubview:self.reactionBackdropLeft belowSubview:self.bubbleImageLeft];
    self.reactionBackdropLeadingLeft = [self.reactionBackdropLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor];
    self.reactionBackdropTopAnchorLeft = [self.reactionBackdropLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor];
    self.reactionBackdropWidthLeft = [self.reactionBackdropLeft.widthAnchor constraintEqualToConstant:0];
    self.reactionBackdropHeightLeft = [self.reactionBackdropLeft.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        self.reactionBackdropLeadingLeft,
        self.reactionBackdropTopAnchorLeft,
        self.reactionBackdropWidthLeft,
        self.reactionBackdropHeightLeft,
    ]];

    self.reactionViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
    self.reactionViewLeft.hidden = YES;
    [self.contentView addSubview:self.reactionViewLeft];
    self.reactionWidthLeft = [self.reactionViewLeft.widthAnchor constraintEqualToConstant:0];
    self.reactionHeightLeft = [self.reactionViewLeft.heightAnchor constraintEqualToConstant:0];
    self.reactionTopAnchorLeft = [self.reactionViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor];
    self.reactionLeadingLeft = [self.reactionViewLeft.leftAnchor constraintEqualToAnchor:self.reactionBackdropLeft.leftAnchor
                                                                                 constant:kReactionHorizontalPadding];
    self.reactionTrailingLeft = [self.reactionViewLeft.rightAnchor constraintLessThanOrEqualToAnchor:self.reactionBackdropLeft.rightAnchor
                                                                                              constant:-kReactionHorizontalPadding];
    [NSLayoutConstraint activateConstraints:@[
        self.reactionLeadingLeft,
        self.reactionTrailingLeft,
        self.reactionTopAnchorLeft,
        self.reactionWidthLeft,
        self.reactionHeightLeft,
    ]];

    [self.contentView addSubview:self.pinLabelLeft];
    self.pinLabelHLeft = [self.pinLabelLeft.heightAnchor constraintEqualToConstant:16];
    self.pinLabelHLeft.active = YES;
    self.pinLabelWLeft = [self.pinLabelLeft.widthAnchor constraintEqualToConstant:kPinLabelMaxWidth];
    self.pinLabelWLeft.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.pinLabelLeft.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        [self.pinLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:14],
    ]];

    [self.contentView addSubview:self.pinImageLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.pinImageLeft.rightAnchor constraintEqualToAnchor:self.pinLabelLeft.leftAnchor constant:-2],
        [self.pinImageLeft.widthAnchor constraintEqualToConstant:10],
        [self.pinImageLeft.centerYAnchor constraintEqualToAnchor:self.pinLabelLeft.centerYAnchor],
    ]];
}

- (void)baseCommonUIRight {
    [self.contentView addSubview:self.userHeaderViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.userHeaderViewRight.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
        [self.userHeaderViewRight.widthAnchor constraintEqualToConstant:32],
        [self.userHeaderViewRight.heightAnchor constraintEqualToConstant:32],
        [self.userHeaderViewRight.topAnchor constraintEqualToAnchor:self.userHeaderViewLeft.topAnchor constant:0],
    ]];

    [self.contentView addSubview:self.bubbleImageRight];
    self.bubbleWRight = [self.bubbleImageRight.widthAnchor constraintEqualToConstant:0];
    self.bubbleWRight.active = YES;
    self.bubbleHRight = [self.bubbleImageRight.heightAnchor constraintEqualToConstant:0];
    self.bubbleHRight.active = YES;
    self.bubbleTrailingRight = [self.bubbleImageRight.rightAnchor constraintEqualToAnchor:self.userHeaderViewRight.leftAnchor
                                                                                   constant:-chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        [self.bubbleImageRight.topAnchor constraintEqualToAnchor:self.userHeaderViewRight.topAnchor constant:0],
        self.bubbleTrailingRight,
    ]];

    self.reactionBackdropRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.reactionBackdropRight.image = self.bubbleImageRight.image;
    self.reactionBackdropRight.backgroundColor = self.bubbleImageRight.backgroundColor;
    self.reactionBackdropRight.contentMode = self.bubbleImageRight.contentMode;
    self.reactionBackdropRight.userInteractionEnabled = YES;
    self.reactionBackdropRight.hidden = YES;
    [self.contentView insertSubview:self.reactionBackdropRight belowSubview:self.bubbleImageRight];
    self.reactionBackdropTrailingRight = [self.reactionBackdropRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor];
    self.reactionBackdropTopAnchorRight = [self.reactionBackdropRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor];
    self.reactionBackdropWidthRight = [self.reactionBackdropRight.widthAnchor constraintEqualToConstant:0];
    self.reactionBackdropHeightRight = [self.reactionBackdropRight.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        self.reactionBackdropTrailingRight,
        self.reactionBackdropTopAnchorRight,
        self.reactionBackdropWidthRight,
        self.reactionBackdropHeightRight,
    ]];

    self.reactionViewRight.translatesAutoresizingMaskIntoConstraints = NO;
    self.reactionViewRight.hidden = YES;
    [self.contentView addSubview:self.reactionViewRight];
    self.reactionWidthRight = [self.reactionViewRight.widthAnchor constraintEqualToConstant:0];
    self.reactionHeightRight = [self.reactionViewRight.heightAnchor constraintEqualToConstant:0];
    self.reactionTopAnchorRight = [self.reactionViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor];
    self.reactionLeadingRight = [self.reactionViewRight.leftAnchor constraintEqualToAnchor:self.reactionBackdropRight.leftAnchor
                                                                                   constant:kReactionHorizontalPadding];
    self.reactionTrailingRight = [self.reactionViewRight.rightAnchor constraintLessThanOrEqualToAnchor:self.reactionBackdropRight.rightAnchor
                                                                                                constant:-kReactionHorizontalPadding];
    [NSLayoutConstraint activateConstraints:@[
        // Both directions stay leading-aligned inside the combined surface.
        self.reactionLeadingRight,
        self.reactionTrailingRight,
        self.reactionTopAnchorRight,
        self.reactionWidthRight,
        self.reactionHeightRight,
    ]];

    [self.contentView addSubview:self.activityView];
    self.activityViewCenterYAnchor = [self.activityView.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor constant:0];
    self.activityViewCenterYAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.activityView.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:-chat_content_margin],
        [self.activityView.widthAnchor constraintEqualToConstant:22],
        [self.activityView.heightAnchor constraintEqualToConstant:22],
    ]];

    [self.contentView addSubview:self.readView];
    self.readViewBottomAnchor = [self.readView.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor
                                                                           constant:0];
    self.readViewRightToBubbleAnchor = [self.readView.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor
                                                                                  constant:-chat_content_margin];
    self.readViewRightToReactionBackdropAnchor = [self.readView.rightAnchor constraintEqualToAnchor:self.reactionBackdropRight.leftAnchor
                                                                                              constant:-chat_content_margin];
    [NSLayoutConstraint activateConstraints:@[
        self.readViewRightToBubbleAnchor,
        self.readViewBottomAnchor,
        [self.readView.widthAnchor constraintEqualToConstant:16],
        [self.readView.heightAnchor constraintEqualToConstant:16],
    ]];

    [self.contentView addSubview:self.selectedButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.selectedButton.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.selectedButton.widthAnchor constraintEqualToConstant:18],
        [self.selectedButton.heightAnchor constraintEqualToConstant:18],
    ]];

    [self.contentView addSubview:self.pinLabelRight];
    self.pinLabelHRight = [self.pinLabelRight.heightAnchor constraintEqualToConstant:16];
    self.pinLabelHRight.active = YES;
    self.pinLabelWRight = [self.pinLabelRight.widthAnchor constraintEqualToConstant:210];
    self.pinLabelWRight.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.pinLabelRight.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        [self.pinLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:0],
    ]];

    [self.contentView addSubview:self.pinImageRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.pinImageRight.rightAnchor constraintEqualToAnchor:self.pinLabelRight.leftAnchor constant:-2],
        [self.pinImageRight.centerYAnchor constraintEqualToAnchor:self.pinLabelRight.centerYAnchor],
        [self.pinImageRight.widthAnchor constraintEqualToConstant:10],
    ]];
}

- (void)addGesture {
    UITapGestureRecognizer *avatarTapRight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAvatar:)];
    avatarTapRight.cancelsTouchesInView = YES;
    [self.userHeaderViewRight addGestureRecognizer:avatarTapRight];

    UITapGestureRecognizer *avatarTapLeft = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAvatar:)];
    avatarTapLeft.cancelsTouchesInView = YES;
    [self.userHeaderViewLeft addGestureRecognizer:avatarTapLeft];

    UILongPressGestureRecognizer *avatarLongGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAvatar:)];
    avatarLongGesture.cancelsTouchesInView = NO;
    [self.userHeaderViewLeft addGestureRecognizer:avatarLongGesture];

    UITapGestureRecognizer *messageTapRight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    messageTapRight.cancelsTouchesInView = NO;

    UITapGestureRecognizer *messageTapLeft = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    messageTapLeft.cancelsTouchesInView = NO;

    UILongPressGestureRecognizer *messageLongPressRight = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    UILongPressGestureRecognizer *messageLongPressLeft = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [messageTapRight requireGestureRecognizerToFail:messageLongPressRight];
    [messageTapLeft requireGestureRecognizerToFail:messageLongPressLeft];
    [self.bubbleImageRight addGestureRecognizer:messageTapRight];
    [self.bubbleImageLeft addGestureRecognizer:messageTapLeft];
    [self.bubbleImageRight addGestureRecognizer:messageLongPressRight];
    [self.bubbleImageLeft addGestureRecognizer:messageLongPressLeft];
    if (self.supportsReactionLongPress) {
        [self.reactionViewRight addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
        [self.reactionViewLeft addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
        [self.reactionBackdropRight addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
        [self.reactionBackdropLeft addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    }

    UITapGestureRecognizer *tapReadView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReadView:)];
    tapReadView.cancelsTouchesInView = YES;
    [self.readView addGestureRecognizer:tapReadView];
    self.tapGesture = tapReadView;
}

- (void)initSubviewsLayout {
    NEChatAvatarType avatarType = [ChatUIConfig shared].messageProperties.avatarType;
    CGFloat avatarCornerRadius = [ChatUIConfig shared].messageProperties.avatarCornerRadius;
    if (avatarType == NEChatAvatarTypeCycle) {
        self.userHeaderViewRight.layer.cornerRadius = 16.0;
        self.userHeaderViewLeft.layer.cornerRadius = 16.0;
    } else if (avatarCornerRadius > 0) {
        self.userHeaderViewRight.layer.cornerRadius = avatarCornerRadius;
        self.userHeaderViewLeft.layer.cornerRadius = avatarCornerRadius;
    } else {
        self.userHeaderViewRight.layer.cornerRadius = 16.0;
        self.userHeaderViewLeft.layer.cornerRadius = 16.0;
    }
}

#pragma mark - event

- (void)tapAvatar:(UITapGestureRecognizer *)tap {
    [self.delegate didTapAvatarView:self model:self.contentModel];
}

- (void)tapMessage:(UITapGestureRecognizer *)tap {
    [self.delegate didTapMessageView:self model:self.contentModel replyModel:self.contentModel.replyedModel];
}

- (void)longPressAvatar:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongPressAvatar:self model:self.contentModel];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongPressMessageView:self model:self.contentModel];
    }
}

- (void)resend:(UIButton *)button {
    NSLog(@"state:default");
    [self.delegate didTapResendView:self model:self.contentModel];
}

- (void)tapReadView:(UITapGestureRecognizer *)tap {
    [self.delegate didTapReadView:self model:self.contentModel];
}

- (void)reactionView:(NEMessageReactionView *)view didSelectIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(didTapReaction:model:index:)]) {
        [self.delegate didTapReaction:self model:self.contentModel index:index];
    }
}

- (void)selectButtonClicked {
    self.selectedButton.selected = !self.selectedButton.selected;
    if (self.contentModel) {
        self.contentModel.isSelected = !self.contentModel.isSelected;
    }
    [self.delegate didTapSelectButton:self model:self.contentModel];
}

#pragma mark - set data

- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect {
    self.selectedButton.hidden = model.isRevoked || !enableSelect;
    self.selectedButton.selected = model.isSelected;
    self.avatarImageLeftAnchor.constant = enableSelect ? fun_chat_min_h : 16;
    self.activityViewCenterYAnchor.constant = enableSelect ? model.contentSize.height / 2 - 12 : 0;
}

- (void)setModel:(MessageContentModel *)model {
    [self setModel:model isSend:[ChatMessageHelper isSelf:model.message]];
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [self applyViewport:model.viewport];
    // Reaction expands the current bubble and must never replace its skin.
    // Clear only supplemental surfaces from the previous model; subclasses
    // may install a custom card image again after this call.
    self.reactionBackdropLeft.image = nil;
    self.reactionBackdropRight.image = nil;
    self.reactionBackdropLeft.backgroundColor = UIColor.clearColor;
    self.reactionBackdropRight.backgroundColor = UIColor.clearColor;
    self.reactionBackdropLeft.hidden = YES;
    self.reactionBackdropRight.hidden = YES;
    self.reactionBackdropLeft.alpha = 0.0;
    self.reactionBackdropRight.alpha = 0.0;
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;
    NSLayoutConstraint *bubbleH = isSend ? self.bubbleHRight : self.bubbleHLeft;
    NEUserHeaderView *userHeaderView = isSend ? self.userHeaderViewRight : self.userHeaderViewLeft;
    CGFloat textSize = isSend ? [ChatUIConfig shared].messageProperties.receiveMessageTextSize : [ChatUIConfig shared].messageProperties.selfMessageTextSize;
    self.messageTextFont = [UIFont systemFontOfSize:textSize];

    self.contentModel = model;
    self.contentModel.cell = self;
    // Reaction measurement can trigger layout while binding a reused cell.
    bubbleW.constant = model.contentSize.width;
    bubbleH.constant = model.contentSize.height;
    BOOL reactionEnabled = NO;
    [self.reactionViewLeft configureWithGroups:model.reactionGroups enabled:!isSend && reactionEnabled isOutgoing:NO];
    [self.reactionViewRight configureWithGroups:model.reactionGroups enabled:isSend && reactionEnabled isOutgoing:YES];
    NEMessageReactionView *reactionView = isSend ? self.reactionViewRight : self.reactionViewLeft;
    BOOL hasReaction = reactionEnabled && model.reactionGroups.count > 0;
    CGFloat reactionTopSpacing = hasReaction ? [self reactionTopSpacingForModel:model] : 0.0;
    CGFloat reactionBottomSpacing = hasReaction ? [self reactionBottomSpacingForModel:model] : 0.0;
    CGFloat reactionVerticalSpacing = reactionTopSpacing + reactionBottomSpacing;
    self.reactionTopAnchorLeft.constant = reactionTopSpacing;
    self.reactionTopAnchorRight.constant = reactionTopSpacing;
    CGFloat leadingInset = [self reactionLeadingInsetForModel:model isOutgoing:isSend];
    CGFloat trailingInset = [self reactionTrailingInsetForModel:model isOutgoing:isSend];
    self.reactionLeadingLeft.constant = leadingInset;
    self.reactionTrailingLeft.constant = -trailingInset;
    self.reactionLeadingRight.constant = leadingInset;
    self.reactionTrailingRight.constant = -trailingInset;
    [reactionView layoutIfNeeded];
    // Text reactions use the available message width rather than measured
    // glyph width. Short message bubbles otherwise collapse every
    // capsule onto a separate row because of their minimum bubble height.
    BOOL locksSurfaceWidth = [self locksReactionSurfaceToMessageWidthForModel:model];
    CGFloat tailInset = hasReaction
        ? [self reactionBackdropTailInsetForModel:model isOutgoing:isSend]
        : 0.0;
    CGFloat reactionMaxWidth = locksSurfaceWidth
        ? MAX(26.0, model.contentSize.width + tailInset - leadingInset - trailingInset)
        : MAX(26.0, self.chatContentMaxW - leadingInset - trailingInset);
    CGFloat bodyPadding = hasReaction ? [self reactionBodyPaddingForModel:model] : 0.0;
    CGFloat measuredReactionWidth = hasReaction ? [reactionView layoutWidthForMaxWidth:reactionMaxWidth] : 0;
    CGFloat reactionWidth = hasReaction
        ? MIN(reactionMaxWidth, MAX(measuredReactionWidth, 26.0))
        : 0;
    CGFloat reactionViewHeight = hasReaction ? [reactionView heightForWidth:reactionWidth] : 0;
    model.reactionHeight = hasReaction ? reactionViewHeight + reactionVerticalSpacing : 0;
    // The hidden backdrop remains the size of the primary message body. Fun
    // supplemental views can therefore use its bottom edge with or without a
    // visible Reaction row.
    CGFloat reactionBackdropWidth;
    if (hasReaction && locksSurfaceWidth) {
        reactionBackdropWidth = model.contentSize.width + tailInset + bodyPadding * 2.0;
    } else {
        reactionBackdropWidth = hasReaction
            ? MAX(model.contentSize.width + tailInset + bodyPadding * 2.0,
                  reactionWidth + leadingInset + trailingInset)
            : model.contentSize.width;
    }
    // The backdrop starts bodyPadding above the message body and needs the
    // same clearance below the Reaction row, so reserve both sides.
    CGFloat reactionBackdropHeight = model.contentSize.height + (hasReaction ? model.reactionHeight + bodyPadding * 2.0 : 0);
    if (isSend) {
        self.reactionWidthRight.constant = reactionWidth;
        self.reactionHeightRight.constant = reactionViewHeight;
        self.reactionBackdropWidthRight.constant = reactionBackdropWidth;
        self.reactionBackdropHeightRight.constant = reactionBackdropHeight;
    } else {
        self.reactionWidthLeft.constant = reactionWidth;
        self.reactionHeightLeft.constant = reactionViewHeight;
        self.reactionBackdropWidthLeft.constant = reactionBackdropWidth;
        self.reactionBackdropHeightLeft.constant = reactionBackdropHeight;
    }
    if (!self.usesInlineReactionSurface) {
        [self updateReactionSurfacePositionWithMessageWidth:model.contentSize.width
                                              backdropWidth:reactionBackdropWidth
                                                   tailInset:tailInset
                                                  bodyPadding:bodyPadding
                                                  isOutgoing:isSend];
    }
    [self updateReadViewPositionForOutgoing:isSend
                       usesReactionBackdrop:hasReaction && !self.usesInlineReactionSurface
                               bottomOffset:self.usesInlineReactionSurface ? 0.0 : model.reactionHeight + bodyPadding];
    self.tapGesture.enabled = YES;
    [self showLeftOrRight:isSend];
    if (hasReaction) {
        UIImageView *backdrop = isSend ? self.reactionBackdropRight : self.reactionBackdropLeft;
        UIImageView *bubble = isSend ? self.bubbleImageRight : self.bubbleImageLeft;
        [self applyReactionBackdropAppearance:backdrop bubble:bubble];
        if (!self.usesInlineReactionSurface) {
            backdrop.alpha = 1.0;
        }
    }
    [self updatePinStatus:model isSend:isSend];

    // time
    if (model.timeContent.length > 0) {
        self.timeLabelHeightAnchor.constant = chat_timeCellH;
        self.timeLabel.text = model.timeContent;
        self.timeLabel.hidden = NO;
    } else {
        self.timeLabelHeightAnchor.constant = 0;
        self.timeLabel.text = @"";
        self.timeLabel.hidden = YES;
    }

    UIImageView *bubbleAnchorView = isSend ? self.bubbleImageRight : self.bubbleImageLeft;
    self.selectedButtonCenterYAnchor = [self.selectedButton.centerYAnchor constraintEqualToAnchor:bubbleAnchorView.centerYAnchor];
    self.selectedButtonCenterYAnchor.priority = UILayoutPriorityDefaultHigh;
    self.selectedButtonCenterYAnchor.active = YES;

    // avatar
    NSString *url = model.avatar;
    NSString *name = model.shortName ?: @"";
    NSString *accountId = [ChatMessageHelper getSenderId:model.message] ?: @"";
    [userHeaderView configHeadData:url name:name uid:accountId];

    if (model.fullNameHeight > 0) {
        self.fullNameLabel.text = model.fullName;
        self.fullNameLabel.hidden = NO;
        self.bubbleTopAnchorLeft.constant = 0;
    } else {
        self.fullNameLabel.text = nil;
        self.fullNameLabel.hidden = YES;
        self.bubbleTopAnchorLeft.constant = 4;
    }
    self.fullNameH.constant = (CGFloat)model.fullNameHeight;

    if (isSend && model.message.sendingState == V2NIMMessageSendingStateSucceeded) {
        if (model.message.conversationType == V2NIMConversationTypeP2P) {
            BOOL receiptEnable = model.type != MessageTypeRtcCallRecord;
            if (receiptEnable && !model.isRevoked && [SettingRepo.shared getShowReadStatus] &&
                [ChatUIConfig shared].messageProperties.showP2PMessageStatus) {
                self.readView.hidden = NO;
                if (model.readCount == 1 && model.unreadCount == 0) {
                    self.readView.progress = 1;
                } else {
                    self.readView.progress = 0;
                }
            } else {
                self.readView.hidden = YES;
            }
        } else if (model.message.conversationType == V2NIMConversationTypeTeam) {
            BOOL receiptEnable = model.message.messageConfig.readReceiptEnabled;
            if (receiptEnable && !model.isRevoked && [SettingRepo.shared getShowReadStatus] &&
                [ChatUIConfig shared].messageProperties.showTeamMessageStatus) {
                self.readView.hidden = NO;
                NSInteger total = [NETeamUserManager.shared getTeamInfo].memberCount ?: 0;
                if (model.readCount + model.unreadCount != 0) {
                    total = model.readCount + model.unreadCount + 1;
                }
                if (total > [ChatUIConfig shared].maxReadingNum) {
                    self.readView.hidden = YES;
                } else {
                    if (total - 1 > 0) {
                        float progress = (float)model.readCount / (float)(total - 1);
                        self.readView.progress = progress;
                        if (progress >= 1.0) {
                            self.tapGesture.enabled = NO;
                        }
                    } else {
                        self.readView.progress = 0;
                    }
                }
            } else {
                self.readView.hidden = YES;
            }
        }
    } else {
        self.readView.hidden = YES;
    }

    if (isSend) {
        switch (model.message.sendingState) {
            case V2NIMMessageSendingStateSending:
                self.activityView.messageStatus = ChatMessageStatusSending;
                break;
            case V2NIMMessageSendingStateSucceeded:
                if (model.message.messageStatus.errorCode != operationSuccess) {
                    self.activityView.messageStatus = ChatMessageStatusSendingFailed;
                    self.readView.hidden = YES;
                } else {
                    self.activityView.messageStatus = ChatMessageStatusSuccessed;
                }
                break;
            case V2NIMMessageSendingStateFailed:
                self.activityView.messageStatus = ChatMessageStatusFailed;
                break;
            default:
                self.activityView.messageStatus = ChatMessageStatusSending;
                break;
        }
    } else {
        self.activityView.messageStatus = ChatMessageStatusSuccessed;
    }

    if ([self.delegate respondsToSelector:@selector(messageWillShow:model:)]) {
        [self.delegate messageWillShow:self model:model];
    }
}

- (void)showLeftOrRight:(BOOL)showRight {
    self.userHeaderViewLeft.hidden = showRight;
    self.bubbleImageLeft.hidden = showRight;
    self.reactionViewLeft.hidden = showRight || !self.reactionViewLeft.enabledForDisplay;
    self.reactionBackdropLeft.hidden = self.usesInlineReactionSurface || showRight || !self.reactionViewLeft.enabledForDisplay;
    self.pinImageLeft.hidden = showRight;
    self.pinLabelLeft.hidden = showRight;
    self.fullNameLabel.hidden = showRight;

    self.userHeaderViewRight.hidden = !showRight;
    self.bubbleImageRight.hidden = !showRight;
    self.reactionViewRight.hidden = !showRight || !self.reactionViewRight.enabledForDisplay;
    self.reactionBackdropRight.hidden = self.usesInlineReactionSurface || !showRight || !self.reactionViewRight.enabledForDisplay;
    self.pinImageRight.hidden = !showRight;
    self.pinLabelRight.hidden = !showRight;
    self.activityView.hidden = !showRight;
    self.readView.hidden = !showRight;
}

- (void)updateReactionSurface:(NEMessageReactionView *)reactionView
                      backdrop:(UIImageView *)backdrop
                        bubble:(UIImageView *)bubble {
    if (self.usesInlineReactionSurface) {
        backdrop.hidden = YES;
        backdrop.alpha = 0.0;
        backdrop.image = nil;
        backdrop.backgroundColor = UIColor.clearColor;
        return;
    }
    // Revoke rows are system notifications and never render a Reaction
    // surface. Stop before a reused backdrop can be restored during layout.
    if (self.contentModel.type == MessageTypeRevoke) {
        backdrop.hidden = YES;
        backdrop.alpha = 0.0;
        backdrop.image = nil;
        backdrop.backgroundColor = UIColor.clearColor;
        if (bubble == self.bubbleImageRight) {
            self.reactionWidthRight.constant = 0;
            self.reactionHeightRight.constant = 0;
            self.reactionBackdropWidthRight.constant = 0;
            self.reactionBackdropHeightRight.constant = 0;
        } else {
            self.reactionWidthLeft.constant = 0;
            self.reactionHeightLeft.constant = 0;
            self.reactionBackdropWidthLeft.constant = 0;
            self.reactionBackdropHeightLeft.constant = 0;
        }
        return;
    }
    if (!reactionView.enabledForDisplay) {
        backdrop.hidden = YES;
        backdrop.alpha = 0.0;
        backdrop.image = nil;
        backdrop.backgroundColor = UIColor.clearColor;
        return;
    }
    // Media subclasses restore their thumbnail/bubble surface during layout.
    // Reapply the direction-aware inset here as well so a reused WeChat media
    // cell never renders the add button flush against the surface edge.
    if (self.contentModel) {
        BOOL isOutgoing = bubble == self.bubbleImageRight;
        CGFloat leading = [self reactionLeadingInsetForModel:self.contentModel isOutgoing:isOutgoing];
        CGFloat trailing = [self reactionTrailingInsetForModel:self.contentModel isOutgoing:isOutgoing];
        if (isOutgoing) {
            self.reactionLeadingRight.constant = leading;
            self.reactionTrailingRight.constant = -trailing;
        } else {
            self.reactionLeadingLeft.constant = leading;
            self.reactionTrailingLeft.constant = -trailing;
        }
    }
    backdrop.alpha = 1.0;
    // Keep the directional surface visible only for the side currently bound
    // to this cell. This prevents a stale hidden-side backdrop from becoming
    // visible after a direction change during reuse.
    backdrop.hidden = bubble.hidden;
    [self applyReactionBackdropAppearance:backdrop bubble:bubble];
    // Keep the original bubble as the foreground surface. The backdrop is a
    // sibling used only to extend the skin behind the Reaction row; clearing
    // the foreground image makes reacted messages appear to use a different
    // bubble resource (and breaks custom/Fun skins).

    if (self.contentModel) {
        // Subclasses can resolve their final body width after the base model
        // pass. Reconcile the combined surface without stretching that body.
        BOOL isOutgoing = bubble == self.bubbleImageRight;
        CGFloat messageWidth = [self resolvedFixedFormatBubbleWidth:bubble];
        CGFloat leadingInset = [self reactionLeadingInsetForModel:self.contentModel isOutgoing:isOutgoing];
        CGFloat trailingInset = [self reactionTrailingInsetForModel:self.contentModel isOutgoing:isOutgoing];
        BOOL locksSurfaceWidth = [self locksReactionSurfaceToMessageWidthForModel:self.contentModel];
        CGFloat tailInset = [self reactionBackdropTailInsetForModel:self.contentModel isOutgoing:isOutgoing];
        CGFloat bodyPadding = reactionView.enabledForDisplay
            ? [self reactionBodyPaddingForModel:self.contentModel]
            : 0.0;
        CGFloat maxWidth = locksSurfaceWidth
            ? MAX(26.0, messageWidth + tailInset - leadingInset - trailingInset)
            : MAX(26.0, self.chatContentMaxW - leadingInset - trailingInset);
        CGFloat resolvedWidth = MIN(maxWidth,
                                    MAX([reactionView layoutWidthForMaxWidth:maxWidth], 26.0));
        CGFloat resolvedHeight = [reactionView heightForWidth:resolvedWidth];
        CGFloat topSpacing = [self reactionTopSpacingForModel:self.contentModel];
        CGFloat bottomSpacing = [self reactionBottomSpacingForModel:self.contentModel];
        if (isOutgoing) {
            self.reactionTopAnchorRight.constant = topSpacing;
        } else {
            self.reactionTopAnchorLeft.constant = topSpacing;
        }
        CGFloat width = locksSurfaceWidth
            ? messageWidth + tailInset + bodyPadding * 2.0
            : MAX(messageWidth + tailInset + bodyPadding * 2.0,
                  resolvedWidth + leadingInset + trailingInset);
        CGFloat resolvedReactionHeight = resolvedHeight + topSpacing + bottomSpacing;
        CGFloat height = MAX(0.0, [self resolvedBubbleHeight:bubble] + resolvedReactionHeight + bodyPadding * 2.0);
        if (bubble == self.bubbleImageRight) {
            self.reactionWidthRight.constant = resolvedWidth;
            self.reactionHeightRight.constant = resolvedHeight;
            self.reactionBackdropWidthRight.constant = width;
            self.reactionBackdropHeightRight.constant = height;
        } else {
            self.reactionWidthLeft.constant = resolvedWidth;
            self.reactionHeightLeft.constant = resolvedHeight;
            self.reactionBackdropWidthLeft.constant = width;
            self.reactionBackdropHeightLeft.constant = height;
        }
        if (fabs(self.contentModel.reactionHeight - resolvedReactionHeight) > 0.5) {
            self.contentModel.reactionHeight = resolvedReactionHeight;
        }
        [self updateReactionSurfacePositionWithMessageWidth:messageWidth
                                              backdropWidth:width
                                                   tailInset:tailInset
                                                  bodyPadding:bodyPadding
                                                  isOutgoing:isOutgoing];
        [self updateReadViewPositionForOutgoing:isOutgoing
                           usesReactionBackdrop:YES
                                   bottomOffset:resolvedReactionHeight + bodyPadding];
    }
}

- (void)updateReadViewPositionForOutgoing:(BOOL)isOutgoing
                     usesReactionBackdrop:(BOOL)usesReactionBackdrop
                             bottomOffset:(CGFloat)bottomOffset {
    BOOL anchorsToBackdrop = isOutgoing && usesReactionBackdrop;
    if (anchorsToBackdrop) {
        self.readViewRightToBubbleAnchor.active = NO;
        self.readViewRightToReactionBackdropAnchor.active = YES;
    } else {
        self.readViewRightToReactionBackdropAnchor.active = NO;
        self.readViewRightToBubbleAnchor.active = YES;
    }
    self.readViewBottomAnchor.constant = isOutgoing ? bottomOffset : 0.0;
}

- (void)updateReactionSurfacePositionWithMessageWidth:(CGFloat)messageWidth
                                        backdropWidth:(CGFloat)backdropWidth
                                             tailInset:(CGFloat)tailInset
                                           bodyPadding:(CGFloat)bodyPadding
                                            isOutgoing:(BOOL)isOutgoing {
    if (isOutgoing) {
        CGFloat totalExtension = MAX(0.0, backdropWidth - messageWidth);
        // Anchor the expanded surface at the original outgoing edge, then keep
        // the message body on its leading side. Media retains its 4pt body gap;
        // a Fun tail and any extra Reaction width remain on the trailing side.
        CGFloat bodyOffset = MAX(0.0, totalExtension - bodyPadding);
        self.bubbleTrailingRight.constant = -(chat_content_margin + bodyOffset);
        self.reactionBackdropTrailingRight.constant = bodyOffset;
    } else {
        self.bubbleLeadingLeft.constant = chat_content_margin + tailInset;
        self.reactionBackdropLeadingLeft.constant = -(tailInset + bodyPadding);
    }
    self.reactionBackdropTopAnchorLeft.constant = -bodyPadding;
    self.reactionBackdropTopAnchorRight.constant = -bodyPadding;
}

- (void)applyReactionBackdropAppearance:(UIImageView *)backdrop
                                  bubble:(UIImageView *)bubble {
    // Full-bleed media/card cells intentionally clear the foreground bubble
    // image. Preserve an installed surface, then fall back to the skin asset.
    if (bubble.image) {
        backdrop.image = bubble.image;
    } else if (!backdrop.image) {
        UIImage *fallback = [self reactionBackdropImageForOutgoing:(bubble == self.bubbleImageRight)];
        if (fallback) backdrop.image = fallback;
    }
    if ([self shouldCopyBubbleBackgroundToReactionBackdropForModel:self.contentModel]) {
        if (![bubble.backgroundColor isEqual:UIColor.clearColor]) {
            backdrop.backgroundColor = bubble.backgroundColor;
        }
    } else {
        backdrop.backgroundColor = UIColor.clearColor;
    }
    backdrop.contentMode = bubble.contentMode;
}

- (CGFloat)resolvedFixedFormatBubbleWidth:(UIImageView *)bubble {
    NSLayoutConstraint *constraint = bubble == self.bubbleImageRight ? self.bubbleWRight : self.bubbleWLeft;
    // The active width constraint is the model's authoritative media/card
    // size. Reused cells can expose the previous frame during the first
    // layout pass, so only fall back to that frame when no model width exists.
    CGFloat constrained = MAX(0.0, constraint.constant);
    if (constrained > 0.0) return constrained;
    return MAX(0.0, CGRectGetWidth(bubble.bounds));
}

- (CGFloat)resolvedBubbleHeight:(UIImageView *)bubble {
    NSLayoutConstraint *constraint = bubble == self.bubbleImageRight ? self.bubbleHRight : self.bubbleHLeft;
    CGFloat constrained = MAX(0.0, constraint.constant);
    return constrained > 0.0 ? constrained : MAX(0.0, CGRectGetHeight(bubble.bounds));
}

- (CGFloat)reactionHorizontalInsetForModel:(MessageContentModel *)model {
    return [self usesFixedReactionSurfaceForModel:model]
        ? kReactionMediaHorizontalPadding
        : kReactionHorizontalPadding;
}

- (CGFloat)reactionBodyPaddingForModel:(MessageContentModel *)model {
    return (model.type == MessageTypeImage ||
            model.type == MessageTypeVideo ||
            model.type == MessageTypeFile)
        ? kReactionMediaBodyPadding
        : 0.0;
}

- (CGFloat)reactionTopSpacingForModel:(MessageContentModel *)model {
    return kReactionBottomPadding;
}

- (CGFloat)reactionBottomSpacingForModel:(MessageContentModel *)model {
    // Preserve the existing total 8pt reserve for subclasses that move the
    // gap from above the Reaction row to below it.
    return MAX(0.0, kReactionBottomPadding - [self reactionTopSpacingForModel:model]);
}

- (CGFloat)reactionLeadingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    return [self reactionHorizontalInsetForModel:model] + [self reactionBodyPaddingForModel:model];
}

- (CGFloat)reactionTrailingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    return [self reactionHorizontalInsetForModel:model] + [self reactionBodyPaddingForModel:model];
}

- (CGFloat)reactionBackdropTailInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing {
    return 0.0;
}

- (UIImage *)reactionBackdropImageForOutgoing:(BOOL)isOutgoing {
    return nil;
}

- (BOOL)shouldCopyBubbleBackgroundToReactionBackdropForModel:(MessageContentModel *)model {
    return YES;
}

- (BOOL)usesFixedReactionSurfaceForModel:(MessageContentModel *)model {
    return model.type == MessageTypeImage ||
        model.type == MessageTypeVideo ||
        model.type == MessageTypeFile ||
        model.type == MessageTypeLocation ||
        model.type == MessageTypeMultiForward;
}

- (BOOL)locksReactionSurfaceToMessageWidthForModel:(MessageContentModel *)model {
    return [self usesFixedReactionSurfaceForModel:model] &&
        model.type != MessageTypeImage && model.type != MessageTypeVideo;
}

- (void)resetReactionSurfaceForReuse {
    self.reactionBackdropLeft.image = nil;
    self.reactionBackdropRight.image = nil;
    self.reactionBackdropLeft.backgroundColor = UIColor.clearColor;
    self.reactionBackdropRight.backgroundColor = UIColor.clearColor;
    [self.reactionViewLeft configureWithGroups:@[] enabled:NO isOutgoing:NO];
    [self.reactionViewRight configureWithGroups:@[] enabled:NO isOutgoing:YES];
    self.reactionWidthLeft.constant = 0;
    self.reactionHeightLeft.constant = 0;
    self.reactionWidthRight.constant = 0;
    self.reactionHeightRight.constant = 0;
    self.reactionBackdropWidthLeft.constant = 0;
    self.reactionBackdropHeightLeft.constant = 0;
    self.reactionBackdropWidthRight.constant = 0;
    self.reactionBackdropHeightRight.constant = 0;
    self.bubbleLeadingLeft.constant = chat_content_margin;
    self.bubbleTrailingRight.constant = -chat_content_margin;
    self.reactionBackdropLeadingLeft.constant = 0;
    self.reactionBackdropTrailingRight.constant = 0;
    self.reactionTopAnchorLeft.constant = 0;
    self.reactionTopAnchorRight.constant = 0;
    [self updateReadViewPositionForOutgoing:NO
                       usesReactionBackdrop:NO
                               bottomOffset:0.0];
    self.reactionBackdropLeft.hidden = YES;
    self.reactionBackdropRight.hidden = YES;
    self.reactionBackdropLeft.alpha = 0.0;
    self.reactionBackdropRight.alpha = 0.0;
}

- (void)resetSelectRange {}

- (void)selectAllRange {}

- (void)updatePinStatus:(MessageContentModel *)model isSend:(BOOL)isSend {
    UILabel *pinLabel = isSend ? self.pinLabelRight : self.pinLabelLeft;
    UIImageView *pinImage = isSend ? self.pinImageRight : self.pinImageLeft;
    NSLayoutConstraint *pinLabelH = isSend ? self.pinLabelHRight : self.pinLabelHLeft;
    NSLayoutConstraint *pinLabelW = isSend ? self.pinLabelWRight : self.pinLabelWLeft;

    pinLabel.hidden = !model.isPined;
    pinImage.hidden = !model.isPined;
    self.contentView.backgroundColor = model.isPined ? [ChatUIConfig shared].messageProperties.signalBgColor : UIColor.clearColor;

    if (model.isPined) {
        NSString *pinText = [NSString stringWithFormat:chatLocalizable(@"pin_text"), chatLocalizable(@"You")];
        if (!model.pinAccount) {
            pinLabel.text = pinText;
        } else if ([model.pinAccount isEqualToString:[IMKitClient instance].account]) {
            pinLabel.text = pinText;
        } else if (model.pinShowName) {
            pinLabel.text = [NSString stringWithFormat:chatLocalizable(@"pin_text"), model.pinShowName];
        }

        pinImage.image = [UIImage ne_imageNamed:@"msg_pin"];
        NSString *showText = pinLabel.text ?: pinText;
        CGSize size = [NSString getRealSize:showText font:[UIFont systemFontOfSize:12] maxSize:CGSizeMake(kPinLabelMaxWidth, CGFLOAT_MAX)];
        pinLabelH.constant = (CGFloat)chat_pin_height;
        pinLabelW.constant = MIN(size.width + 1, kPinLabelMaxWidth);
    } else {
        pinImage.image = nil;
        pinLabelH.constant = 0;
        pinLabelW.constant = 0;
    }
}

- (double)sizeWidthFromString:(NSAttributedString *)text font:(UIFont *)font {
    CGSize maxSize = CGSizeMake(self.chatContentMaxW, CGFLOAT_MAX);
    CGRect labelSize = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                         context:nil];
    return ceil(labelSize.size.width) + chat_content_margin * 2;
}

- (double)sizeHeightFromString:(NSAttributedString *)text font:(UIFont *)font {
    CGSize maxSize = CGSizeMake(self.chatContentMaxW, CGFLOAT_MAX);
    CGRect labelSize = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                         context:nil];
    return ceil(labelSize.size.height) + chat_content_margin * 2;
}

#pragma mark - Reedit / AI Stream / Link / Focus

- (void)tapReeditButton {
  [self.delegate didTapReeditButton:self model:self.contentModel];
}

- (void)didTextViewLoseFocus {
  [self.delegate didTextViewLoseFocus:self model:self.contentModel];
}

- (void)stopAIStreamMessage {
  [self.delegate stopAIStreamMessage:self model:self.contentModel];
}

- (void)regenAIStreamMessage {
  [self.delegate regenAIStreamMessage:self model:self.contentModel];
}

- (void)didTapDetectedLink:(NSURL *)url {
  [self.delegate didTapDetectedLink:self model:self.contentModel url:url];
}

@end
