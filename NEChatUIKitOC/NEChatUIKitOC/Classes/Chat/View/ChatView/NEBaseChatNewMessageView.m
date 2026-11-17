// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseChatNewMessageView.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation NEBaseChatNewMessageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIImageView *)jumpDownImageView {
    if (!_jumpDownImageView) {
        _jumpDownImageView = [[UIImageView alloc] init];
        _jumpDownImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _jumpDownImageView.image = [UIImage ne_imageNamed:@"chat_jump_to_new"];
    }
    return _jumpDownImageView;
}

- (UILabel *)messageCountLabel {
    if (!_messageCountLabel) {
        _messageCountLabel = [[UILabel alloc] init];
        _messageCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageCountLabel.font = DefaultTextFont(14);
        _messageCountLabel.textColor = UIColor.ne_defaultPrimaryColor;
        _messageCountLabel.textAlignment = NSTextAlignmentCenter;
        _messageCountLabel.hidden = YES;
    }
    return _messageCountLabel;
}

- (void)setupUI {
    self.backgroundColor = UIColor.whiteColor;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor.blackColor colorWithAlphaComponent:0.08].CGColor;
    self.layer.masksToBounds = YES;

    [self addSubview:self.jumpDownImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.jumpDownImageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:12],
        [self.jumpDownImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.jumpDownImageView.widthAnchor constraintEqualToConstant:16],
        [self.jumpDownImageView.heightAnchor constraintEqualToConstant:16],
    ]];

    [self addSubview:self.messageCountLabel];
    self.messageCountLabelRightAnchor = [self.messageCountLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-30];
    self.messageCountLabelRightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.messageCountLabel.leftAnchor constraintEqualToAnchor:self.jumpDownImageView.rightAnchor constant:0],
        [self.messageCountLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
}

- (void)updateMessageCount:(NSInteger)count {
    if (count > 0) {
        self.hidden = NO;
        self.messageCountLabel.hidden = NO;
        self.messageCountLabel.text = [NSString stringWithFormat:chatLocalizable(@"new_message_count"), (long)count];
        self.messageCountLabelRightAnchor.constant = -30;
    } else if (count == 0) {
        self.hidden = NO;
        self.messageCountLabel.hidden = YES;
        self.messageCountLabel.text = nil;
        self.messageCountLabelRightAnchor.constant = 0;
    } else {
        self.hidden = YES;
    }
}

@end
