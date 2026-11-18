// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatActivityIndicatorView.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>

@interface ChatActivityIndicatorView ()
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

@implementation ChatActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIButton *)failButton {
    if (!_failButton) {
        _failButton = [[UIButton alloc] init];
        _failButton.translatesAutoresizingMaskIntoConstraints = NO;
        _failButton.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *originalImage = [UIImage ne_imageNamed:@"sendMessage_failed"];
        UIImage *templateImage = [originalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_failButton setImage:templateImage forState:UIControlStateNormal];
        _failButton.accessibilityIdentifier = @"id.sendMessageFailed";
    }
    return _failButton;
}

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] init];
        _activityView.translatesAutoresizingMaskIntoConstraints = NO;
        _activityView.color = UIColor.grayColor;
    }
    return _activityView;
}

- (void)setMessageStatus:(ChatSendMessageStatus)messageStatus {
    _messageStatus = messageStatus;
    self.failButton.hidden = YES;
    self.activityView.hidden = YES;
    [self.activityView stopAnimating];

    switch (messageStatus) {
        case ChatSendMessageStatusSending:
            self.hidden = NO;
            self.activityView.hidden = NO;
            self.failButton.hidden = YES;
            [self.activityView startAnimating];
            break;
        case ChatSendMessageStatusFailed:
            self.hidden = NO;
            self.activityView.hidden = YES;
            self.failButton.hidden = NO;
            self.failButton.enabled = YES;
            self.failButton.tintColor = [UIColor ne_colorWithHexString:@"#FB5A6A"];
            break;
        case ChatSendMessageStatusSendingFailed:
            self.hidden = NO;
            self.activityView.hidden = YES;
            self.failButton.hidden = NO;
            self.failButton.enabled = NO;
            self.failButton.tintColor = UIColor.grayColor;
            break;
        case ChatSendMessageStatusSuccessed:
            self.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)commonUI {
    self.backgroundColor = UIColor.clearColor;
    [self addSubview:self.failButton];
    [self addSubview:self.activityView];
    [NSLayoutConstraint activateConstraints:@[
        [self.failButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.failButton.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.failButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.failButton.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.activityView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.activityView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.activityView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.activityView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
}

@end
