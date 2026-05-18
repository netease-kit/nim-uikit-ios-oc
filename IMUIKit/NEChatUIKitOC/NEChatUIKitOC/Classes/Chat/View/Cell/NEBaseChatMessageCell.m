// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatMessageCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NSString+NECommon.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "ChatMessageHelper.h"
#import "MessageContentModel.h"
#import "NEChatUIConstant.h"

static const CGFloat kPinLabelMaxWidth = 280.0;

@interface NEBaseChatMessageCell ()
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelHLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelWLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelHRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pinLabelWRight;
@property (nonatomic, strong, nullable) UITapGestureRecognizer *tapGesture;
@end

@implementation NEBaseChatMessageCell

- (CGFloat)pinLabelMaxWidth {
    return kPinLabelMaxWidth;
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
    self.bubbleWLeft = [self.bubbleImageLeft.widthAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.bubbleWLeft.active = YES;
    self.bubbleHLeft = [self.bubbleImageLeft.heightAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.bubbleHLeft.active = YES;
    [[self.bubbleImageLeft.leftAnchor constraintEqualToAnchor:self.userHeaderViewLeft.rightAnchor constant:chat_content_margin] setActive:YES];

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
    self.bubbleWRight = [self.bubbleImageRight.widthAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.bubbleWRight.active = YES;
    self.bubbleHRight = [self.bubbleImageRight.heightAnchor constraintEqualToConstant:CGFLOAT_MAX];
    self.bubbleHRight.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.bubbleImageRight.topAnchor constraintEqualToAnchor:self.userHeaderViewRight.topAnchor constant:0],
        [self.bubbleImageRight.rightAnchor constraintEqualToAnchor:self.userHeaderViewRight.leftAnchor constant:-chat_content_margin],
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
    [NSLayoutConstraint activateConstraints:@[
        [self.readView.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:-chat_content_margin],
        [self.readView.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
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
    [self.bubbleImageRight addGestureRecognizer:messageTapRight];

    UITapGestureRecognizer *messageTapLeft = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    messageTapLeft.cancelsTouchesInView = NO;
    [self.bubbleImageLeft addGestureRecognizer:messageTapLeft];

    UILongPressGestureRecognizer *messageLongPressRight = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.bubbleImageRight addGestureRecognizer:messageLongPressRight];

    UILongPressGestureRecognizer *messageLongPressLeft = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.bubbleImageLeft addGestureRecognizer:messageLongPressLeft];

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
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;
    NSLayoutConstraint *bubbleH = isSend ? self.bubbleHRight : self.bubbleHLeft;
    NEUserHeaderView *userHeaderView = isSend ? self.userHeaderViewRight : self.userHeaderViewLeft;
    CGFloat textSize = isSend ? [ChatUIConfig shared].messageProperties.receiveMessageTextSize : [ChatUIConfig shared].messageProperties.selfMessageTextSize;
    self.messageTextFont = [UIFont systemFontOfSize:textSize];

    self.contentModel = model;
    self.contentModel.cell = self;
    self.tapGesture.enabled = YES;
    [self showLeftOrRight:isSend];
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

    bubbleW.constant = model.contentSize.width;
    bubbleH.constant = model.contentSize.height;

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
    self.pinImageLeft.hidden = showRight;
    self.pinLabelLeft.hidden = showRight;
    self.fullNameLabel.hidden = showRight;

    self.userHeaderViewRight.hidden = !showRight;
    self.bubbleImageRight.hidden = !showRight;
    self.pinImageRight.hidden = !showRight;
    self.pinLabelRight.hidden = !showRight;
    self.activityView.hidden = !showRight;
    self.readView.hidden = !showRight;
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
    CGSize maxSize = CGSizeMake(chat_content_maxW, CGFLOAT_MAX);
    CGRect labelSize = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                         context:nil];
    return ceil(labelSize.size.width) + chat_content_margin * 2;
}

- (double)sizeHeightFromString:(NSAttributedString *)text font:(UIFont *)font {
    CGSize maxSize = CGSizeMake(chat_content_maxW, CGFLOAT_MAX);
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
