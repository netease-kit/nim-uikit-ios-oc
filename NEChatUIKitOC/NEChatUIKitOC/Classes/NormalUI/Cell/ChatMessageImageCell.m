// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageImageCell.h"
#import "UIImage+Chat.h"
#import <SDWebImage/SDWebImage.h>

@implementation ChatMessageImageCell

- (UIImageView *)contentImageViewLeft {
    if (!_contentImageViewLeft) {
        _contentImageViewLeft = [[UIImageView alloc] init];
        _contentImageViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentImageViewLeft.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageViewLeft.clipsToBounds = YES;
        _contentImageViewLeft.image = [UIImage ne_imageNamed:@"fun_default_image"];
        _contentImageViewLeft.accessibilityIdentifier = @"id.thumbnail";
    }
    return _contentImageViewLeft;
}

- (UIImageView *)contentImageViewRight {
    if (!_contentImageViewRight) {
        _contentImageViewRight = [[UIImageView alloc] init];
        _contentImageViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentImageViewRight.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageViewRight.clipsToBounds = YES;
        _contentImageViewRight.image = [UIImage ne_imageNamed:@"fun_default_image"];
        _contentImageViewRight.accessibilityIdentifier = @"id.thumbnail";
    }
    return _contentImageViewRight;
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.contentImageViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentImageViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:0],
        [self.contentImageViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:0],
        [self.contentImageViewLeft.topAnchor constraintEqualToAnchor:self.replyViewLeft.bottomAnchor constant:0],
        [self.contentImageViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:0],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.contentImageViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentImageViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:0],
        [self.contentImageViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:0],
        [self.contentImageViewRight.topAnchor constraintEqualToAnchor:self.replyViewRight.bottomAnchor constant:0],
        [self.contentImageViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentImageViewLeft.hidden = showRight;
    self.contentImageViewRight.hidden = !showRight;
}

- (void)setCustomCorner:(BOOL)hasReply {
    if (hasReply) {
        [self setBubbleImage];
        [self.contentImageViewRight removeAllCustomCorner];
        [self.contentImageViewLeft removeAllCustomCorner];
        self.contentImageViewRight.layer.cornerRadius = 8;
        self.contentImageViewLeft.layer.cornerRadius = 8;
    } else {
        self.bubbleImageRight.image = nil;
        self.bubbleImageLeft.image = nil;
        self.bubbleImageRight.backgroundColor = UIColor.clearColor;
        self.bubbleImageLeft.backgroundColor = UIColor.clearColor;
        [self.contentImageViewRight addCustomCornerWithConrners:UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight radius:8 backcolor:UIColor.whiteColor];
        [self.contentImageViewLeft addCustomCornerWithConrners:UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight radius:8 backcolor:UIColor.whiteColor];
    }
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UIImageView *contentImageView = isSend ? self.contentImageViewRight : self.contentImageViewLeft;

    BOOL hasReaction = [IMKitConfigCenter shared].enableEmojiReaction &&
        !model.isRevoked &&
        model.message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED &&
        model.reactionGroups.count > 0;
    [self setCustomCorner:model.isReply || hasReaction];

    if ([model isKindOfClass:[MessageImageModel class]]) {
        MessageImageModel *m = (MessageImageModel *)model;
        NSString *imageUrl = m.urlString;
        if (imageUrl.length > 0) {
            SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;
            if ([imageUrl hasPrefix:@"http"]) {
                __weak typeof(contentImageView) weakImageView = contentImageView;
                [contentImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if (error) {
                        if (error.code == 2001 && [model.message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) {
                            V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)model.message.attachment;
                            if (imageObject.url.length > 0) {
                                SDWebImageContext *context = @{SDWebImageContextImageThumbnailPixelSize: [NSValue valueWithCGSize:CGSizeMake(350, 350)]};
                                [weakImageView sd_setImageWithURL:[NSURL URLWithString:imageObject.url]
                                                placeholderImage:[UIImage imageWithContentsOfFile:imageObject.url]
                                                         options:options
                                                         context:context
                                                        progress:nil
                                                       completed:nil];
                            } else {
                                weakImageView.image = [UIImage ne_imageNamed:@"default_image"];
                            }
                        } else {
                            weakImageView.image = [UIImage ne_imageNamed:@"default_image"];
                        }
                    }
                }];
            } else {
                [contentImageView sd_setImageWithURL:[NSURL fileURLWithPath:imageUrl] placeholderImage:nil options:options context:nil];
            }
        } else {
            contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
        }
    } else {
        contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
}

@end
