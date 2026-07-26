// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageRevokeCell.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatUIConstant.h"
#import "FunChatUIColor.h"

@implementation FunChatMessageRevokeCell

- (void)commonUILeft {
    [super commonUILeft];
    [self.contentView addSubview:self.revokeLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelLeft.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.revokeLabelLeft.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
        [self.revokeLabelLeft.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:6],
        [self.revokeLabelLeft.heightAnchor constraintEqualToConstant:16],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.contentView addSubview:self.revokeLabelRight];
    self.revokeLabelRightXAnchor = [self.revokeLabelRight.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor constant:0];
    self.revokeLabelRightXAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelRight.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.revokeLabelRight.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:6],
        [self.revokeLabelRight.heightAnchor constraintEqualToConstant:16],
    ]];

    [self.contentView addSubview:self.reeditButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.reeditButton.leftAnchor constraintEqualToAnchor:self.revokeLabelRight.rightAnchor constant:8],
        [self.reeditButton.widthAnchor constraintEqualToConstant:58],
        [self.reeditButton.topAnchor constraintEqualToAnchor:self.revokeLabelRight.topAnchor],
        [self.reeditButton.bottomAnchor constraintEqualToAnchor:self.revokeLabelRight.bottomAnchor],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    self.userHeaderViewLeft.hidden = YES;
    self.bubbleImageLeft.hidden = YES;
    self.pinImageLeft.hidden = YES;
    self.pinLabelLeft.hidden = YES;
    self.fullNameLabel.hidden = YES;

    self.userHeaderViewRight.hidden = YES;
    self.bubbleImageRight.hidden = YES;
    self.pinImageRight.hidden = YES;
    self.pinLabelRight.hidden = YES;
    self.activityView.hidden = YES;
    self.readView.hidden = YES;
    self.selectedButton.hidden = YES;

    self.revokeLabelLeft.hidden = showRight;
    self.revokeLabelRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    BOOL isMyMsg = [[IMKitClient instance] isMe:model.message.senderId];
    UILabel *revokeLabel = isMyMsg ? self.revokeLabelRight : self.revokeLabelLeft;

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if ((NSInteger)(currentTime - model.revokeTime) >= [ChatUIConfig shared].revokeEditTimeGap * 60) {
        model.timeOut = YES;
    }

    model.contentSize = CGSizeMake(kScreenWidth(), 0);
    [super setModel:model isSend:isMyMsg];
    [self showLeftOrRight:isMyMsg];

    revokeLabel.textColor = [UIColor funChatInputViewPlaceholderTextColor];
    if (isMyMsg) {
        revokeLabel.text = [NSString stringWithFormat:@"%@%@", chatLocalizable(@"You"), chatLocalizable(@"withdrew_message")];
    } else {
        revokeLabel.text = [NSString stringWithFormat:@"%@ %@", model.fullName ?: @"", chatLocalizable(@"withdrew_message")];
    }

    if (isMyMsg && model.isReedit) {
        if (model.timeOut) {
            self.reeditButton.hidden = YES;
            self.revokeLabelRightXAnchor.constant = 0;
        } else {
            self.reeditButton.hidden = NO;
            [self.reeditButton setTitle:chatLocalizable(@"message_reedit") forState:UIControlStateNormal];
            self.revokeLabelRightXAnchor.constant = -32;
        }
    } else {
        self.reeditButton.hidden = YES;
        self.revokeLabelRightXAnchor.constant = 0;
    }
}

- (void)reeditEvent:(UIButton *)button {
    [self.delegate didTapReeditButton:self model:self.contentModel];
}

#pragma mark - Lazy Load

- (UILabel *)revokeLabelLeft {
    if (!_revokeLabelLeft) {
        _revokeLabelLeft = [[UILabel alloc] init];
        _revokeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelLeft.textColor = [UIColor ne_greyText];
        _revokeLabelLeft.textAlignment = NSTextAlignmentCenter;
        _revokeLabelLeft.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _revokeLabelLeft.font = [UIFont systemFontOfSize:14.0];
        _revokeLabelLeft.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelLeft;
}

- (UILabel *)revokeLabelRight {
    if (!_revokeLabelRight) {
        _revokeLabelRight = [[UILabel alloc] init];
        _revokeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelRight.textColor = [UIColor ne_greyText];
        _revokeLabelRight.textAlignment = NSTextAlignmentCenter;
        _revokeLabelRight.font = [UIFont systemFontOfSize:14.0];
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
