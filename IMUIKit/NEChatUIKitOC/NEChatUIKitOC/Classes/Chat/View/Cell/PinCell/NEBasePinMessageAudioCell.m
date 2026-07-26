// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageAudioCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "MessageContentModel.h"
#import "MessageAudioModel.h"
#import "NEChatUIConstant.h"

@implementation NEBasePinMessageAudioCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIImageView *)audioImageView {
    if (!_audioImageView) {
        _audioImageView = [[UIImageView alloc] initWithImage:chatLoadImage(@"left_play_3")];
        _audioImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _audioImageView.contentMode = UIViewContentModeCenter;
        _audioImageView.animationDuration = 1;
        UIImage *img1 = chatLoadImage(@"left_play_1");
        UIImage *img2 = chatLoadImage(@"left_play_2");
        UIImage *img3 = chatLoadImage(@"left_play_3");
        if (img1 && img2 && img3) {
            _audioImageView.animationImages = @[img1, img2, img3];
        }
    }
    return _audioImageView;
}

- (void)setupUI {
    [super setupUI];

    UIImage *image = [ChatUIConfig shared].messageProperties.receiveMessageBgImage ?: chatLoadImage(@"chat_message_receive");
    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    _bubbleImage = [[UIImageView alloc] init];
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        _bubbleImage.image = [image resizableImageWithCapInsets:capInsets];
    } else {
        _bubbleImage.image = image;
        _bubbleImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    _bubbleImage.translatesAutoresizingMaskIntoConstraints = NO;
    _bubbleImage.userInteractionEnabled = YES;
    [self.backView addSubview:_bubbleImage];
    self.contentWidth = [_bubbleImage.widthAnchor constraintEqualToConstant:chat_content_maxW()];
    self.contentHeight = [_bubbleImage.heightAnchor constraintEqualToConstant:chat_content_maxW()];
    [NSLayoutConstraint activateConstraints:@[
        self.contentHeight,
        self.contentWidth,
        [_bubbleImage.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16],
        [_bubbleImage.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
    ]];

    [_bubbleImage addSubview:self.audioImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.audioImageView.leftAnchor constraintEqualToAnchor:_bubbleImage.leftAnchor constant:16],
        [self.audioImageView.centerYAnchor constraintEqualToAnchor:_bubbleImage.centerYAnchor],
        [self.audioImageView.widthAnchor constraintEqualToConstant:28],
        [self.audioImageView.heightAnchor constraintEqualToConstant:28],
    ]];

    _audioTimeLabel = [[UILabel alloc] init];
    _audioTimeLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.pinMessageTextSize];
    _audioTimeLabel.textColor = UIColor.ne_darkText;
    _audioTimeLabel.textAlignment = NSTextAlignmentLeft;
    _audioTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_bubbleImage addSubview:_audioTimeLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_audioTimeLabel.leftAnchor constraintEqualToAnchor:self.audioImageView.rightAnchor constant:12],
        [_audioTimeLabel.centerYAnchor constraintEqualToAnchor:_bubbleImage.centerYAnchor],
        [_audioTimeLabel.rightAnchor constraintEqualToAnchor:_bubbleImage.rightAnchor constant:-12],
        [_audioTimeLabel.heightAnchor constraintEqualToConstant:28],
    ]];

    if (self.contentGesture) {
        [_bubbleImage addGestureRecognizer:self.contentGesture];
    }
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    if ([item.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)item.chatmodel;
        self.audioTimeLabel.text = [NSString stringWithFormat:@"%lus", (unsigned long)m.duration];
        m.isPlaying ? [self startAnimation] : [self stopAnimation];
    }
}

- (void)startAnimation {
    if (!self.audioImageView.isAnimating) {
        [self.audioImageView startAnimating];
    }
    if ([self.pinModel.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)self.pinModel.chatmodel;
        m.isPlaying = YES;
        self.isPlaying = YES;
    }
}

- (void)stopAnimation {
    if (self.audioImageView.isAnimating) {
        [self.audioImageView stopAnimating];
    }
    if ([self.pinModel.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)self.pinModel.chatmodel;
        m.isPlaying = NO;
        self.isPlaying = NO;
    }
}

@end
