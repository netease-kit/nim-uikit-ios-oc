// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageRevokeCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation ChatMessageRevokeCell

- (UILabel *)revokeLabelLeft {
    if (!_revokeLabelLeft) {
        _revokeLabelLeft = [[UILabel alloc] init];
        _revokeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelLeft.text = chatLocalizable(@"message_recalled");
        _revokeLabelLeft.textColor = UIColor.ne_greyText;
        _revokeLabelLeft.font = [UIFont systemFontOfSize:16.0];
        _revokeLabelLeft.accessibilityIdentifier = @"id.messageText";
    }
    return _revokeLabelLeft;
}

- (UILabel *)revokeLabelRight {
    if (!_revokeLabelRight) {
        _revokeLabelRight = [[UILabel alloc] init];
        _revokeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _revokeLabelRight.text = chatLocalizable(@"message_recalled");
        _revokeLabelRight.textColor = UIColor.ne_greyText;
        _revokeLabelRight.font = [UIFont systemFontOfSize:16.0];
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
    [self.bubbleImageLeft addSubview:self.revokeLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:16],
        [self.revokeLabelLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:0],
        [self.revokeLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-16],
        [self.revokeLabelLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:0],
    ]];
}

- (void)commonUIRight {
    [self.bubbleImageRight addSubview:self.revokeLabelRight];
    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    [NSLayoutConstraint activateConstraints:@[
        [self.revokeLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:16],
        [self.revokeLabelRight.widthAnchor constraintEqualToConstant:isEnglish ? 130 : 100],
        [self.revokeLabelRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:0],
        [self.revokeLabelRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
    ]];

    [self.bubbleImageRight addSubview:self.reeditButton];
    self.reeditButtonW = [self.reeditButton.widthAnchor constraintEqualToConstant:86];
    self.reeditButtonW.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.reeditButton.leftAnchor constraintEqualToAnchor:self.revokeLabelRight.rightAnchor constant:8],
        [self.reeditButton.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:0],
        [self.reeditButton.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
    ]];
    [self.reeditButton addTarget:self action:@selector(reeditEvent:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.revokeLabelLeft.hidden = showRight;
    self.revokeLabelRight.hidden = !showRight;

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

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if ((NSInteger)(currentTime - model.revokeTime) >= [ChatUIConfig shared].revokeEditTimeGap * 60) {
        model.timeOut = YES;
    }

    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    if (isMe && model.isReedit && !model.timeOut) {
        self.reeditButtonW.constant = 86;
        self.reeditButton.hidden = NO;
        [self.reeditButton setTitle:chatLocalizable(@"message_reedit") forState:UIControlStateNormal];
        model.contentSize = CGSizeMake(isEnglish ? 248 : 218, chat_min_h);
    } else {
        self.reeditButtonW.constant = 0;
        self.reeditButton.hidden = YES;
        model.contentSize = CGSizeMake(isEnglish ? 160 : 130, chat_min_h);
    }

    [super setModel:model isSend:isMe];
}

- (void)reeditEvent:(UIButton *)button {
    [self.delegate didTapReeditButton:self model:self.contentModel];
}

@end
