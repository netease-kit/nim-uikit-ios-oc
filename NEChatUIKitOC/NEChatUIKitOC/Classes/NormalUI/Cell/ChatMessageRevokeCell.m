// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageRevokeCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/UIColor+NECommon.h>

@implementation ChatMessageRevokeCell

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.contentModel) return;
    [self showLeftOrRight:[[IMKitClient instance] isMe:self.contentModel.message.senderId]];
}

- (UILabel *)revokeLabelLeft {
    if (!_revokeLabelLeft) {
        _revokeLabelLeft = [[UILabel alloc] init];
        _revokeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelLeft.text = chatLocalizable(@"message_recalled");
        _revokeLabelLeft.textAlignment = NSTextAlignmentLeft;
        _revokeLabelLeft.lineBreakMode = NSLineBreakByTruncatingTail;
        _revokeLabelLeft.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelLeft;
}

- (UILabel *)revokeLabelRight {
    if (!_revokeLabelRight) {
        _revokeLabelRight = [[UILabel alloc] init];
        _revokeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelRight.text = chatLocalizable(@"message_recalled");
        _revokeLabelRight.textAlignment = NSTextAlignmentLeft;
        _revokeLabelRight.lineBreakMode = NSLineBreakByTruncatingTail;
        _revokeLabelRight.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelRight;
}

- (UIButton *)reeditButton {
    if (!_reeditButton) {
        _reeditButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reeditButton.translatesAutoresizingMaskIntoConstraints = NO;
        _reeditButton.accessibilityIdentifier = @"id.reeditButton";
        [_reeditButton setImage:[UIImage ne_imageNamed:@"right_arrow"] forState:UIControlStateNormal];
        _reeditButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [_reeditButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
        _reeditButton.titleEdgeInsets = UIEdgeInsetsMake(0, -30, 0, 0);
        _reeditButton.imageEdgeInsets = UIEdgeInsetsMake(0, 70, 0, 0);
    }
    return _reeditButton;
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.revokeLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelLeft.leadingAnchor constraintEqualToAnchor:self.bubbleImageLeft.leadingAnchor constant:16],
        [self.revokeLabelLeft.trailingAnchor constraintEqualToAnchor:self.bubbleImageLeft.trailingAnchor constant:-16],
        [self.revokeLabelLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.revokeLabelLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.revokeLabelRight];
    [self.bubbleImageRight addSubview:self.reeditButton];
    self.reeditButtonW = [self.reeditButton.widthAnchor constraintEqualToConstant:86];
    self.reeditButtonW.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelRight.leadingAnchor constraintEqualToAnchor:self.bubbleImageRight.leadingAnchor constant:16],
        [self.revokeLabelRight.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
        [self.reeditButton.leadingAnchor constraintEqualToAnchor:self.revokeLabelRight.trailingAnchor constant:8],
        [self.reeditButton.trailingAnchor constraintEqualToAnchor:self.bubbleImageRight.trailingAnchor constant:-8],
        [self.reeditButton.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
    ]];
    [self.reeditButton addTarget:self action:@selector(reeditEvent:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];

    // Feishu revoke rows retain the ordinary directional message surface.
    self.replyViewLeftHeightAnchor.constant = 0;
    self.replyViewRightHeightAnchor.constant = 0;
    self.replyViewLeft.hidden = YES;
    self.replyViewRight.hidden = YES;
    self.replyLabelLeft.hidden = YES;
    self.replyLabelRight.hidden = YES;
    self.reactionViewLeft.hidden = YES;
    self.reactionViewRight.hidden = YES;
    self.reactionBackdropLeft.hidden = YES;
    self.reactionBackdropRight.hidden = YES;

    self.revokeLabelLeft.hidden = showRight;
    self.revokeLabelRight.hidden = !showRight;
    self.fullNameLabel.hidden = showRight || self.contentModel.fullNameHeight <= 0;
    self.activityView.hidden = YES;
    self.readView.hidden = YES;
    self.selectedButton.hidden = YES;
    self.pinLabelLeft.hidden = YES;
    self.pinImageLeft.hidden = YES;
    self.pinLabelRight.hidden = YES;
    self.pinImageRight.hidden = YES;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    BOOL isMe = [[IMKitClient instance] isMe:model.message.senderId];
    self.revokeLabelLeft.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.receiveMessageTextSize];
    self.revokeLabelRight.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.selfMessageTextSize];
    self.revokeLabelLeft.textColor = [ChatUIConfig shared].messageProperties.receiveMessageTextColor;
    self.revokeLabelRight.textColor = [ChatUIConfig shared].messageProperties.selfMessageTextColor;

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if ((NSInteger)(currentTime - model.revokeTime) >= [ChatUIConfig shared].revokeEditTimeGap * 60) {
        model.timeOut = YES;
    }

    BOOL showsReedit = isMe && model.isReedit && !model.timeOut;
    self.reeditButtonW.constant = showsReedit ? 86 : 0;
    self.reeditButton.hidden = !showsReedit;
    if (showsReedit) {
        [self.reeditButton setTitle:chatLocalizable(@"message_reedit") forState:UIControlStateNormal];
    }
    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    model.contentSize = CGSizeMake(isEnglish ? (showsReedit ? 248 : 160) : (showsReedit ? 218 : 130),
                                   chat_min_h);

    [super setModel:model isSend:isMe];
    [self resetReactionSurfaceForReuse];
    [self showLeftOrRight:isMe];
}

- (void)reeditEvent:(UIButton *)button {
    [self.delegate didTapReeditButton:self model:self.contentModel];
}

@end
