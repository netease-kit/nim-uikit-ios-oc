// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageRevokeCell.h"
#import <NEChatKit/UIColor+NECommon.h>

#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatKit.h>

@interface FunChatMessageRevokeCell ()
@property (nonatomic, strong, nullable) NSLayoutConstraint *revokeLabelLeftCenterY;
@property (nonatomic, strong, nullable) NSLayoutConstraint *revokeLabelRightCenterY;
@end

@implementation FunChatMessageRevokeCell

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.contentModel) return;
    [self showLeftOrRight:[[IMKitClient instance] isMe:self.contentModel.message.senderId]];
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.contentView addSubview:self.revokeLabelLeft];
    self.revokeLabelLeftCenterY = [self.revokeLabelLeft.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor];
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelLeft.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        self.revokeLabelLeftCenterY,
        [self.revokeLabelLeft.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.revokeLabelLeft.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-16],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.contentView addSubview:self.revokeLabelRight];
    self.revokeLabelRightXAnchor = [self.revokeLabelRight.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor];
    self.revokeLabelRightXAnchor.active = YES;
    self.revokeLabelRightCenterY = [self.revokeLabelRight.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor];
    [NSLayoutConstraint activateConstraints:@[
        self.revokeLabelRightCenterY,
        [self.revokeLabelRight.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.revokeLabelRight.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-16],
    ]];

    [self.contentView addSubview:self.reeditButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.reeditButton.leftAnchor constraintEqualToAnchor:self.revokeLabelRight.rightAnchor constant:8],
        [self.reeditButton.widthAnchor constraintEqualToConstant:58],
        [self.reeditButton.centerYAnchor constraintEqualToAnchor:self.revokeLabelRight.centerYAnchor],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];

    // WeChat renders revoke rows like system tips: only centered text remains.
    self.replyViewLeftHeightAnchor.constant = 0;
    self.replyViewRightHeightAnchor.constant = 0;
    self.replyViewLeft.hidden = YES;
    self.replyTextViewLeft.hidden = YES;
    self.replyLabelLeft.hidden = YES;
    self.replyViewRight.hidden = YES;
    self.replyTextViewRight.hidden = YES;
    self.replyLabelRight.hidden = YES;
    self.reactionViewLeft.hidden = YES;
    self.reactionViewRight.hidden = YES;
    self.reactionBackdropLeft.hidden = YES;
    self.reactionBackdropRight.hidden = YES;
    self.reactionBackdropLeft.alpha = 0.0;
    self.reactionBackdropRight.alpha = 0.0;

    self.revokeLabelLeft.hidden = showRight;
    self.revokeLabelRight.hidden = !showRight;
    self.bubbleImageLeft.hidden = YES;
    self.bubbleImageRight.hidden = YES;
    self.userHeaderViewLeft.hidden = YES;
    self.userHeaderViewRight.hidden = YES;
    self.fullNameLabel.hidden = YES;
    self.pinImageLeft.hidden = YES;
    self.pinLabelLeft.hidden = YES;
    self.pinImageRight.hidden = YES;
    self.pinLabelRight.hidden = YES;
    self.activityView.hidden = YES;
    self.readView.hidden = YES;
    self.selectedButton.hidden = YES;
    self.contentView.backgroundColor = UIColor.clearColor;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    BOOL isMyMsg = [[IMKitClient instance] isMe:model.message.senderId];
    UILabel *revokeLabel = isMyMsg ? self.revokeLabelRight : self.revokeLabelLeft;
    UIFont *tipFont = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.timeTextSize];
    self.revokeLabelLeft.font = tipFont;
    self.revokeLabelRight.font = tipFont;
    self.revokeLabelLeft.textColor = [ChatUIConfig shared].messageProperties.timeTextColor;
    self.revokeLabelRight.textColor = [ChatUIConfig shared].messageProperties.timeTextColor;

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if ((NSInteger)(currentTime - model.revokeTime) >= [ChatUIConfig shared].revokeEditTimeGap * 60) {
        model.timeOut = YES;
    }

    NSString *text = isMyMsg
        ? [NSString stringWithFormat:@"%@%@", chatLocalizable(@"You"), chatLocalizable(@"withdrew_message")]
        : [NSString stringWithFormat:@"%@ %@", model.fullName ?: @"", chatLocalizable(@"withdrew_message")];
    CGFloat textWidth = ceil([text sizeWithAttributes:@{NSFontAttributeName : tipFont}].width);
    model.contentSize = CGSizeMake(MIN(self.chatContentMaxW, MAX(90.0, textWidth)), fun_chat_min_h);

    BOOL showsReedit = isMyMsg && model.isReedit && !model.timeOut;
    self.reeditButton.hidden = !showsReedit;
    if (showsReedit) {
        [self.reeditButton setTitle:chatLocalizable(@"message_reedit") forState:UIControlStateNormal];
    }
    self.revokeLabelRightXAnchor.constant = showsReedit ? -33.0 : 0.0;

    [super setModel:model isSend:isMyMsg];
    [self resetReactionSurfaceForReuse];
    revokeLabel.text = text;
    [self showLeftOrRight:isMyMsg];

    CGFloat timeOffset = model.timeContent.length > 0 ? chat_timeCellH / 2.0 : 0.0;
    self.revokeLabelLeftCenterY.constant = timeOffset;
    self.revokeLabelRightCenterY.constant = timeOffset;
}

- (void)reeditEvent:(UIButton *)button {
    [self.delegate didTapReeditButton:self model:self.contentModel];
}

#pragma mark - Lazy Load

- (UILabel *)revokeLabelLeft {
    if (!_revokeLabelLeft) {
        _revokeLabelLeft = [[UILabel alloc] init];
        _revokeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelLeft.textAlignment = NSTextAlignmentCenter;
        _revokeLabelLeft.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _revokeLabelLeft.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelLeft;
}

- (UILabel *)revokeLabelRight {
    if (!_revokeLabelRight) {
        _revokeLabelRight = [[UILabel alloc] init];
        _revokeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelRight.textAlignment = NSTextAlignmentCenter;
        _revokeLabelRight.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _revokeLabelRight.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelRight;
}

- (UIButton *)reeditButton {
    if (!_reeditButton) {
        _reeditButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reeditButton.translatesAutoresizingMaskIntoConstraints = NO;
        _reeditButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_reeditButton setTitleColor:[UIColor ne_normalTheme] forState:UIControlStateNormal];
        [_reeditButton addTarget:self action:@selector(reeditEvent:) forControlEvents:UIControlEventTouchUpInside];
        _reeditButton.accessibilityIdentifier = @"id.reeditButton";
    }
    return _reeditButton;
}

@end
