// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageImageCell.h"
#import "UIImage+Chat.h"
#import <SDWebImage/SDWebImage.h>
#import "MessageImageModel.h"

@implementation FunChatMessageImageCell

- (void)commonUILeft {
    [super commonUILeft];
    self.bubbleImageLeft.image = nil;
    [self.bubbleImageLeft addSubview:self.contentImageViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentImageViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor],
        [self.contentImageViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor],
        [self.contentImageViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.contentImageViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    self.bubbleImageRight.image = nil;
    [self.bubbleImageRight addSubview:self.contentImageViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentImageViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor],
        [self.contentImageViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor],
        [self.contentImageViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor],
        [self.contentImageViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentImageViewLeft.hidden = showRight;
    self.contentImageViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UIImageView *contentImageView = isSend ? self.contentImageViewRight : self.contentImageViewLeft;

    if ([model isKindOfClass:[MessageImageModel class]]) {
        MessageImageModel *m = (MessageImageModel *)model;
        NSString *imageUrl = m.urlString;
        if (imageUrl.length > 0) {
            SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;
            if ([imageUrl hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:imageUrl];
                __weak typeof(contentImageView) weakImageView = contentImageView;
                __weak typeof(model) weakModel = model;
                [contentImageView sd_setImageWithURL:url
                                   placeholderImage:nil
                                            options:options
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType type, NSURL *imageURL) {
                    if (error) {
                        if (error.code == 2001) {
                            V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)weakModel.message.attachment;
                            if (imageObject.url) {
                                NSURL *origUrl = [NSURL URLWithString:imageObject.url];
                                NSDictionary *context = @{SDWebImageContextImageThumbnailPixelSize: [NSValue valueWithCGSize:CGSizeMake(350, 350)]};
                                [weakImageView sd_setImageWithURL:origUrl
                                                placeholderImage:nil
                                                         options:options
                                                         context:context
                                                        progress:nil
                                                       completed:nil];
                            }
                        } else {
                            weakImageView.image = [UIImage ne_imageNamed:@"default_image"];
                        }
                    }
                }];
            } else {
                NSURL *url = [NSURL fileURLWithPath:imageUrl];
                [contentImageView sd_setImageWithURL:url placeholderImage:nil options:options context:nil];
            }
        } else {
            contentImageView.image = [UIImage ne_imageNamed:@"fun_default_image"];
        }
    }
}

#pragma mark - Lazy Load

- (UIImageView *)contentImageViewLeft {
    if (!_contentImageViewLeft) {
        _contentImageViewLeft = [[UIImageView alloc] init];
        _contentImageViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentImageViewLeft.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageViewLeft.clipsToBounds = YES;
        _contentImageViewLeft.layer.cornerRadius = 4;
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
        _contentImageViewRight.layer.cornerRadius = 4;
        _contentImageViewRight.image = [UIImage ne_imageNamed:@"fun_default_image"];
        _contentImageViewRight.accessibilityIdentifier = @"id.thumbnail";
    }
    return _contentImageViewRight;
}

@end
