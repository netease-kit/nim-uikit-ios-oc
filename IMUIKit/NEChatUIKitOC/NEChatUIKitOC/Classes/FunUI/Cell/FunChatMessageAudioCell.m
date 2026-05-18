// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageAudioCell.h"
#import <NEChatKitOC/NSString+NECommon.h>
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatCellConstantValue.h"
#import "MessageAudioModel.h"
#import "NSString+Chat.h"
#import "FunChatUIColor.h"

@implementation FunChatMessageAudioCell

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.audioImageViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.audioImageViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:16],
        [self.audioImageViewLeft.centerYAnchor constraintEqualToAnchor:self.bubbleImageLeft.centerYAnchor],
        [self.audioImageViewLeft.widthAnchor constraintEqualToConstant:28],
        [self.audioImageViewLeft.heightAnchor constraintEqualToConstant:28],
    ]];

    [self.bubbleImageLeft addSubview:self.timeLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabelLeft.leftAnchor constraintEqualToAnchor:self.audioImageViewLeft.rightAnchor constant:12],
        [self.timeLabelLeft.centerYAnchor constraintEqualToAnchor:self.bubbleImageLeft.centerYAnchor],
        [self.timeLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-12],
        [self.timeLabelLeft.heightAnchor constraintEqualToConstant:28],
    ]];
    self.audioImageViewLeft.animationDuration = 1;
    UIImage *leftImage1 = [UIImage ne_imageNamed:@"left_play_1"];
    UIImage *leftImage2 = [UIImage ne_imageNamed:@"left_play_2"];
    UIImage *leftImage3 = [UIImage ne_imageNamed:@"left_play_3"];
    if (leftImage1 && leftImage2 && leftImage3) {
        self.audioImageViewLeft.animationImages = @[leftImage1, leftImage2, leftImage3];
    }

    [self.contentView addSubview:self.contentLabelLeftView];
    self.contentLabelLeftViewWidthAnchor = [self.contentLabelLeftView.widthAnchor constraintEqualToConstant:chat_content_maxW];
    self.contentLabelLeftViewWidthAnchor.active = YES;
    self.contentLabelLeftViewHeightAnchor = [self.contentLabelLeftView.heightAnchor constraintEqualToConstant:fun_chat_min_h];
    self.contentLabelLeftViewHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeftView.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:self.funMargin],
        [self.contentLabelLeftView.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:4],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.audioImageViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.audioImageViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-16],
        [self.audioImageViewRight.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
        [self.audioImageViewRight.widthAnchor constraintEqualToConstant:28],
        [self.audioImageViewRight.heightAnchor constraintEqualToConstant:28],
    ]];

    [self.bubbleImageRight addSubview:self.timeLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabelRight.rightAnchor constraintEqualToAnchor:self.audioImageViewRight.leftAnchor constant:-12],
        [self.timeLabelRight.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
        [self.timeLabelRight.heightAnchor constraintEqualToConstant:28],
    ]];

    self.audioImageViewRight.animationDuration = 1;
    UIImage *image1 = [UIImage ne_imageNamed:@"play_1"];
    UIImage *image2 = [UIImage ne_imageNamed:@"play_2"];
    UIImage *image3 = [UIImage ne_imageNamed:@"play_3"];
    if (image1 && image2 && image3) {
        self.audioImageViewRight.animationImages = @[image1, image2, image3];
    }

    [self.contentView addSubview:self.contentLabelRightView];
    self.contentLabelRightViewWidthAnchor = [self.contentLabelRightView.widthAnchor constraintEqualToConstant:chat_content_maxW];
    self.contentLabelRightViewWidthAnchor.active = YES;
    self.contentLabelRightViewHeightAnchor = [self.contentLabelRightView.heightAnchor constraintEqualToConstant:fun_chat_min_h];
    self.contentLabelRightViewHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRightView.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-self.funMargin],
        [self.contentLabelRightView.topAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:4],
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
        self.contentModel = model;
        MessageAudioModel *m = (MessageAudioModel *)model;
        UILabel *timeLabel = isSend ? self.timeLabelRight : self.timeLabelLeft;
        timeLabel.text = [NSString stringWithFormat:@"%ld″", (long)m.duration];
        m.isPlaying ? [self startAnimation:isSend] : [self stopAnimation:isSend];
        self.messageId = m.message.messageClientId;

        self.contentLabelRightView.hidden = YES;
        self.contentLabelLeftView.hidden = YES;
        if (m.text.length > 0) {
            UILabel *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;
            UIView *contentLabelView = isSend ? self.contentLabelRightView : self.contentLabelLeftView;
            contentLabel.text = m.text;
            contentLabelView.hidden = NO;

            CGFloat maxWidth = audio_max_width - (chat_cell_margin * 2 + self.funMargin);
            CGSize textSize = [NSString getRealSize:m.text font:self.messageTextFont maxSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
            CGFloat contentWidth = ceil(textSize.width) + chat_cell_margin * 2 + self.funMargin;
            CGFloat contentHeight = ceil(textSize.height) + chat_content_margin * 2;
            NSLayoutConstraint *widthAnchor = isSend ? self.contentLabelRightViewWidthAnchor : self.contentLabelLeftViewWidthAnchor;
            NSLayoutConstraint *heightAnchor = isSend ? self.contentLabelRightViewHeightAnchor : self.contentLabelLeftViewHeightAnchor;
            widthAnchor.constant = contentWidth;
            heightAnchor.constant = contentHeight;
            model.height = fun_chat_min_h + contentHeight + chat_content_margin * 2 + model.fullNameHeight + chat_pin_height;
            if (model.timeContent.length > 0) {
                model.height += chat_timeCellH;
            }
        }
    }
    [super setModel:model isSend:isSend];
}

#pragma mark - Lazy Load

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
        _timeLabelLeft.textColor = [UIColor ne_darkText];
        _timeLabelLeft.textAlignment = NSTextAlignmentLeft;
        _timeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelLeft.accessibilityIdentifier = @"id.time";
    }
    return _timeLabelLeft;
}

- (UILabel *)contentLabelLeft {
    if (!_contentLabelLeft) {
        _contentLabelLeft = [[UILabel alloc] init];
        _contentLabelLeft.font = self.messageTextFont;
        _contentLabelLeft.textColor = [UIColor ne_darkText];
        _contentLabelLeft.textAlignment = NSTextAlignmentJustified;
        _contentLabelLeft.numberOfLines = 0;
        _contentLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft.accessibilityIdentifier = @"id.voiceToText";
    }
    return _contentLabelLeft;
}

- (UIView *)contentLabelLeftView {
    if (!_contentLabelLeftView) {
        _contentLabelLeftView = [[UIView alloc] init];
        _contentLabelLeftView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeftView.backgroundColor = [UIColor whiteColor];
        _contentLabelLeftView.layer.cornerRadius = 4;
        _contentLabelLeftView.accessibilityIdentifier = @"id.voiceToTextView";

        [_contentLabelLeftView addSubview:self.contentLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:_contentLabelLeftView.rightAnchor constant:-chat_content_margin],
            [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:_contentLabelLeftView.leftAnchor constant:chat_content_margin + self.funMargin],
            [self.contentLabelLeft.topAnchor constraintEqualToAnchor:_contentLabelLeftView.topAnchor constant:chat_content_margin],
            [self.contentLabelLeft.bottomAnchor constraintEqualToAnchor:_contentLabelLeftView.bottomAnchor constant:-chat_content_margin],
        ]];
    }
    return _contentLabelLeftView;
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
        _timeLabelRight.textColor = [UIColor ne_darkText];
        _timeLabelRight.textAlignment = NSTextAlignmentRight;
        _timeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelRight.accessibilityIdentifier = @"id.time";
    }
    return _timeLabelRight;
}

- (UILabel *)contentLabelRight {
    if (!_contentLabelRight) {
        _contentLabelRight = [[UILabel alloc] init];
        _contentLabelRight.font = self.messageTextFont;
        _contentLabelRight.textColor = [UIColor ne_darkText];
        _contentLabelRight.textAlignment = NSTextAlignmentJustified;
        _contentLabelRight.numberOfLines = 0;
        _contentLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight.accessibilityIdentifier = @"id.voiceToText";
    }
    return _contentLabelRight;
}

- (UIView *)contentLabelRightView {
    if (!_contentLabelRightView) {
        _contentLabelRightView = [[UIView alloc] init];
        _contentLabelRightView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRightView.backgroundColor = [UIColor funRecordAudioProgressNormalColor];
        _contentLabelRightView.layer.cornerRadius = 4;
        _contentLabelRightView.accessibilityIdentifier = @"id.voiceToTextView";

        [_contentLabelRightView addSubview:self.contentLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.contentLabelRight.rightAnchor constraintEqualToAnchor:_contentLabelRightView.rightAnchor constant:-chat_content_margin - self.funMargin],
            [self.contentLabelRight.leftAnchor constraintEqualToAnchor:_contentLabelRightView.leftAnchor constant:chat_content_margin],
            [self.contentLabelRight.topAnchor constraintEqualToAnchor:_contentLabelRightView.topAnchor constant:chat_content_margin],
            [self.contentLabelRight.bottomAnchor constraintEqualToAnchor:_contentLabelRightView.bottomAnchor constant:-chat_content_margin],
        ]];
    }
    return _contentLabelRightView;
}

@end
