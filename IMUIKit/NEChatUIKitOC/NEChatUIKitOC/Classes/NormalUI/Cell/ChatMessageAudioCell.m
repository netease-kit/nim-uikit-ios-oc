// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageAudioCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NSString+NECommon.h>

@implementation ChatMessageAudioCell

- (UIImageView *)audioImageViewLeft {
    if (!_audioImageViewLeft) {
        _audioImageViewLeft = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"left_play_3"]];
        _audioImageViewLeft.contentMode = UIViewContentModeCenter;
        _audioImageViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _audioImageViewLeft.accessibilityIdentifier = @"id.animation";
    }
    return _audioImageViewLeft;
}

- (UILabel *)timeLabelLeft {
    if (!_timeLabelLeft) {
        _timeLabelLeft = [[UILabel alloc] init];
        _timeLabelLeft.font = [UIFont systemFontOfSize:14];
        _timeLabelLeft.textColor = UIColor.ne_darkText;
        _timeLabelLeft.textAlignment = NSTextAlignmentLeft;
        _timeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelLeft.accessibilityIdentifier = @"id.time";
    }
    return _timeLabelLeft;
}

- (UILabel *)contentLabelLeft {
    if (!_contentLabelLeft) {
        _contentLabelLeft = [[UILabel alloc] init];
        _contentLabelLeft.hidden = YES;
        _contentLabelLeft.font = self.messageTextFont;
        _contentLabelLeft.textColor = UIColor.ne_darkText;
        _contentLabelLeft.textAlignment = NSTextAlignmentJustified;
        _contentLabelLeft.numberOfLines = 0;
        _contentLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft.accessibilityIdentifier = @"id.voiceToText";
    }
    return _contentLabelLeft;
}

- (UIView *)backViewLeft {
    if (!_backViewLeft) {
        _backViewLeft = [[UIView alloc] init];
        _backViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _backViewLeft.backgroundColor = UIColor.clearColor;

        [_backViewLeft addSubview:self.audioImageViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.audioImageViewLeft.leftAnchor constraintEqualToAnchor:_backViewLeft.leftAnchor constant:chat_cell_margin],
            [self.audioImageViewLeft.topAnchor constraintEqualToAnchor:_backViewLeft.topAnchor constant:6],
            [self.audioImageViewLeft.widthAnchor constraintEqualToConstant:28],
            [self.audioImageViewLeft.heightAnchor constraintEqualToConstant:28],
        ]];

        [_backViewLeft addSubview:self.timeLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.timeLabelLeft.leftAnchor constraintEqualToAnchor:self.audioImageViewLeft.rightAnchor constant:12],
            [self.timeLabelLeft.centerYAnchor constraintEqualToAnchor:self.audioImageViewLeft.centerYAnchor],
            [self.timeLabelLeft.rightAnchor constraintEqualToAnchor:_backViewLeft.rightAnchor constant:-12],
            [self.timeLabelLeft.heightAnchor constraintEqualToConstant:28],
        ]];

        self.audioImageViewLeft.animationDuration = 1;
        UIImage *leftImage1 = [UIImage ne_imageNamed:@"left_play_1"];
        UIImage *leftImage2 = [UIImage ne_imageNamed:@"left_play_2"];
        UIImage *leftImage3 = [UIImage ne_imageNamed:@"left_play_3"];
        if (leftImage1 && leftImage2 && leftImage3) {
            self.audioImageViewLeft.animationImages = @[leftImage1, leftImage2, leftImage3];
        }

        [_backViewLeft addSubview:self.contentLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:_backViewLeft.leftAnchor constant:chat_cell_margin],
            [self.contentLabelLeft.topAnchor constraintEqualToAnchor:self.audioImageViewLeft.bottomAnchor constant:4],
            [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:_backViewLeft.rightAnchor constant:-chat_cell_margin],
        ]];
    }
    return _backViewLeft;
}

- (UIImageView *)audioImageViewRight {
    if (!_audioImageViewRight) {
        _audioImageViewRight = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"audio_play"]];
        _audioImageViewRight.contentMode = UIViewContentModeCenter;
        _audioImageViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _audioImageViewRight.accessibilityIdentifier = @"id.animation";
    }
    return _audioImageViewRight;
}

- (UILabel *)timeLabelRight {
    if (!_timeLabelRight) {
        _timeLabelRight = [[UILabel alloc] init];
        _timeLabelRight.font = [UIFont systemFontOfSize:14];
        _timeLabelRight.textColor = UIColor.ne_darkText;
        _timeLabelRight.textAlignment = NSTextAlignmentRight;
        _timeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelRight.accessibilityIdentifier = @"id.time";
    }
    return _timeLabelRight;
}

- (UILabel *)contentLabelRight {
    if (!_contentLabelRight) {
        _contentLabelRight = [[UILabel alloc] init];
        _contentLabelRight.hidden = YES;
        _contentLabelRight.font = self.messageTextFont;
        _contentLabelRight.textColor = UIColor.ne_darkText;
        _contentLabelRight.textAlignment = NSTextAlignmentJustified;
        _contentLabelRight.numberOfLines = 0;
        _contentLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight.accessibilityIdentifier = @"id.voiceToText";
    }
    return _contentLabelRight;
}

- (UIView *)backViewRight {
    if (!_backViewRight) {
        _backViewRight = [[UIView alloc] init];
        _backViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _backViewRight.backgroundColor = UIColor.clearColor;

        [_backViewRight addSubview:self.audioImageViewRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.audioImageViewRight.rightAnchor constraintEqualToAnchor:_backViewRight.rightAnchor constant:-chat_cell_margin],
            [self.audioImageViewRight.topAnchor constraintEqualToAnchor:_backViewRight.topAnchor constant:6],
            [self.audioImageViewRight.widthAnchor constraintEqualToConstant:28],
            [self.audioImageViewRight.heightAnchor constraintEqualToConstant:28],
        ]];

        [_backViewRight addSubview:self.timeLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.timeLabelRight.rightAnchor constraintEqualToAnchor:self.audioImageViewRight.leftAnchor constant:-12],
            [self.timeLabelRight.centerYAnchor constraintEqualToAnchor:self.audioImageViewRight.centerYAnchor],
            [self.timeLabelRight.heightAnchor constraintEqualToConstant:28],
        ]];

        self.audioImageViewRight.animationDuration = 1;
        UIImage *image1 = [UIImage ne_imageNamed:@"play_1"];
        UIImage *image2 = [UIImage ne_imageNamed:@"play_2"];
        UIImage *image3 = [UIImage ne_imageNamed:@"play_3"];
        if (image1 && image2 && image3) {
            self.audioImageViewRight.animationImages = @[image1, image2, image3];
        }

        [_backViewRight addSubview:self.contentLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.contentLabelRight.leftAnchor constraintEqualToAnchor:_backViewRight.leftAnchor constant:chat_cell_margin],
            [self.contentLabelRight.topAnchor constraintEqualToAnchor:self.audioImageViewRight.bottomAnchor constant:4],
            [self.contentLabelRight.rightAnchor constraintEqualToAnchor:_backViewRight.rightAnchor constant:-chat_cell_margin],
        ]];
    }
    return _backViewRight;
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.backViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.backViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:0],
        [self.backViewLeft.topAnchor constraintEqualToAnchor:self.replyViewLeft.bottomAnchor constant:0],
        [self.backViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:0],
        [self.backViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:0],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.backViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.backViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:0],
        [self.backViewRight.topAnchor constraintEqualToAnchor:self.replyViewRight.bottomAnchor constant:0],
        [self.backViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:0],
        [self.backViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
    ]];
}

- (void)startAnimation:(BOOL)byRight {
    UIImageView *audioImageView = byRight ? self.audioImageViewRight : self.audioImageViewLeft;
    if (!audioImageView.isAnimating) {
        [audioImageView startAnimating];
    }
    if ([self.contentModel isKindOfClass:[MessageAudioModel class]]) {
        ((MessageAudioModel *)self.contentModel).isPlaying = YES;
        self.isPlaying = YES;
    }
}

- (void)stopAnimation:(BOOL)byRight {
    UIImageView *audioImageView = byRight ? self.audioImageViewRight : self.audioImageViewLeft;
    if (audioImageView.isAnimating) {
        [audioImageView stopAnimating];
    }
    if ([self.contentModel isKindOfClass:[MessageAudioModel class]]) {
        ((MessageAudioModel *)self.contentModel).isPlaying = NO;
        self.isPlaying = NO;
    }
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.audioImageViewLeft.hidden = showRight;
    self.timeLabelLeft.hidden = showRight;
    self.audioImageViewRight.hidden = !showRight;
    self.timeLabelRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    if ([model isKindOfClass:[MessageAudioModel class]]) {
        MessageAudioModel *m = (MessageAudioModel *)model;
        self.contentModel = m;
        UILabel *timeLabel = isSend ? self.timeLabelRight : self.timeLabelLeft;
        timeLabel.text = [NSString stringWithFormat:@"%lus", (unsigned long)m.duration];

        if (m.isPlaying) {
            [self startAnimation:isSend];
        } else {
            [self stopAnimation:isSend];
        }
        self.messageId = m.message.messageClientId;

        self.contentLabelRight.hidden = YES;
        self.contentLabelLeft.hidden = YES;
        if (m.text.length > 0) {
            UILabel *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;
            contentLabel.text = m.text;
            contentLabel.hidden = NO;

            CGFloat maxWidth = MAX(chat_text_maxW(), m.audioWidth) - chat_cell_margin * 2;
            CGSize textSize = [NSString getRealSize:m.text
                                               font:self.messageTextFont
                                            maxSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
            CGFloat contentWidth = MAX(m.audioWidth, ceil(textSize.width) + chat_cell_margin * 2);
            CGFloat contentHeight = chat_min_h + ceil(textSize.height) + chat_content_margin;
            model.contentSize = CGSizeMake(contentWidth, contentHeight);
            model.height = model.contentSize.height + chat_content_margin * 2 + model.fullNameHeight + chat_pin_height;
            if (model.timeContent.length > 0) {
                model.height += chat_timeCellH;
            }
        }
    }
    [super setModel:model isSend:isSend];
}

@end
