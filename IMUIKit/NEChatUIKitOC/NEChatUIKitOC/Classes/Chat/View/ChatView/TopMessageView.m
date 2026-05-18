// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TopMessageView.h"
#import "NEChatUIConstant.h"
#import "ChatCellConstantValue.h"
#import "UIImage+Chat.h"
#import "NEEmotionTool.h"
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <SDWebImage/SDWebImage.h>

@implementation TopMessageView

- (UIImageView *)topImageView {
    if (!_topImageView) {
        _topImageView = [[UIImageView alloc] init];
        _topImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _topImageView;
}

- (UIImageView *)playIcon {
    if (!_playIcon) {
        _playIcon = [[UIImageView alloc] init];
        _playIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _playIcon.image = [coreLoader() loadImage:@"video_play"];
    }
    return _playIcon;
}

- (UIImageView *)thumbImageView {
    if (!_thumbImageView) {
        _thumbImageView = [[UIImageView alloc] init];
        _thumbImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_thumbImageView addSubview:self.playIcon];
        [NSLayoutConstraint activateConstraints:@[
            [self.playIcon.centerXAnchor constraintEqualToAnchor:_thumbImageView.centerXAnchor],
            [self.playIcon.centerYAnchor constraintEqualToAnchor:_thumbImageView.centerYAnchor],
            [self.playIcon.widthAnchor constraintEqualToConstant:16],
            [self.playIcon.heightAnchor constraintEqualToConstant:16],
        ]];
    }
    return _thumbImageView;
}

- (UILabel *)topContentLabel {
    if (!_topContentLabel) {
        _topContentLabel = [[UILabel alloc] init];
        _topContentLabel.font = [UIFont systemFontOfSize:12];
        _topContentLabel.textColor = UIColor.ne_darkText;
        _topContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _topContentLabel.accessibilityIdentifier = @"id.topContent";
    }
    return _topContentLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[coreLoader() loadImage:@"remove"] forState:UIControlStateNormal];
        _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        _closeButton.accessibilityIdentifier = @"id.topClose";
        [_closeButton addTarget:self action:@selector(didClickCloseButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 8;

        [self addSubview:self.topImageView];
        [NSLayoutConstraint activateConstraints:@[
            [self.topImageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:chat_content_margin],
            [self.topImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.topImageView.widthAnchor constraintEqualToConstant:18],
            [self.topImageView.heightAnchor constraintEqualToConstant:18],
        ]];

        [self addSubview:self.thumbImageView];
        [NSLayoutConstraint activateConstraints:@[
            [self.thumbImageView.leftAnchor constraintEqualToAnchor:self.topImageView.rightAnchor constant:chat_content_margin],
            [self.thumbImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.thumbImageView.widthAnchor constraintEqualToConstant:28],
            [self.thumbImageView.heightAnchor constraintEqualToConstant:28],
        ]];

        [self addSubview:self.topContentLabel];
        self.topContentLabelLeftAnchor = [self.topContentLabel.leftAnchor constraintEqualToAnchor:self.topImageView.rightAnchor constant:chat_content_margin];
        self.topContentLabelLeftAnchor.active = YES;
        [NSLayoutConstraint activateConstraints:@[
            [self.topContentLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-44],
            [self.topContentLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];

        [self addSubview:self.closeButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.closeButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-chat_content_margin],
            [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.closeButton.widthAnchor constraintEqualToConstant:30],
            [self.closeButton.heightAnchor constraintEqualToConstant:30],
        ]];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTopMessageView)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setTopContentWithName:(nullable NSString *)name content:(nullable NSString *)content url:(nullable NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose {
    self.content = content;
    [self updateTopName:name];

    if (url) {
        self.thumbImageView.hidden = NO;
        [self.thumbImageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil];
        self.playIcon.hidden = !isVideo;
        self.topContentLabelLeftAnchor.constant = chat_content_margin + 32;
    } else {
        self.thumbImageView.hidden = YES;
        self.topContentLabelLeftAnchor.constant = chat_content_margin;
    }
    self.closeButton.hidden = hideClose;
}

- (void)updateTopName:(nullable NSString *)name {
    NSString *text = @"";
    if (name.length > 0) {
        NSString *cutName = [NEFriendUserCache getCutName:name];
        text = [cutName stringByAppendingString:@"："];
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    if (self.content) {
        NSAttributedString *emojiAttr = [NEEmotionTool getAttWithStr:self.content font:self.topContentLabel.font color:UIColor.ne_darkText offset:CGPointMake(0, -4)];
        [attributedString appendAttributedString:emojiAttr];
    }
    self.topContentLabel.attributedText = attributedString;
}

- (void)didClickCloseButton {
    [self.delegate didClickCloseButton];
}

- (void)tapTopMessageView {
    [self.delegate didTapTopMessageView];
}

@end
