// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageAudioCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "MessageContentModel.h"
#import "MessageAudioModel.h"
#import "NEChatUIConstant.h"

@implementation NEBaseCollectionMessageAudioCell

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

- (void)setupCommonUI {
    [super setupCommonUI];

    UIImage *receiveImage = [ChatUIConfig shared].messageProperties.receiveMessageBgImage ?: chatLoadImage(@"chat_message_receive");
    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    _bubbleImage = [[UIImageView alloc] init];
    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero)) {
        _bubbleImage.image = [receiveImage resizableImageWithCapInsets:capInsets];
    } else {
        _bubbleImage.image = receiveImage;
        _bubbleImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    _bubbleImage.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backView addSubview:_bubbleImage];
    self.contentWidth = [_bubbleImage.widthAnchor constraintEqualToConstant:chat_content_maxW()];
    self.contentHeight = [_bubbleImage.heightAnchor constraintEqualToConstant:chat_content_maxW()];
    _bubbleImage.userInteractionEnabled = YES;
    [NSLayoutConstraint activateConstraints:@[
        self.contentHeight,
        self.contentWidth,
        [_bubbleImage.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16],
        [_bubbleImage.bottomAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:-12],
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
    _audioTimeLabel.textAlignment = NSTextAlignmentLeft;
    _audioTimeLabel.textColor = UIColor.ne_darkText;
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

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    if ([model.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)model.chatmodel;
        self.audioTimeLabel.text = [NSString stringWithFormat:@"%lus", (unsigned long)m.duration];
        m.isPlaying ? [self startPlayAnimation] : [self stopPlayAnimation];
    }
}

- (void)startPlayAnimation {
    if (!self.audioImageView.isAnimating) {
        [self.audioImageView startAnimating];
    }
    if ([self.collectionModel.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)self.collectionModel.chatmodel;
        m.isPlaying = YES;
        self.isPlaying = YES;
    }
}

- (void)stopPlayAnimation {
    if (self.audioImageView.isAnimating) {
        [self.audioImageView stopAnimating];
    }
    if ([self.collectionModel.chatmodel isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)self.collectionModel.chatmodel;
        m.isPlaying = NO;
        self.isPlaying = NO;
    }
}

@end
