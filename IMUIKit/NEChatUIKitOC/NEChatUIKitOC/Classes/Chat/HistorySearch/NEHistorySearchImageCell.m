// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistorySearchImageCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageImageModel.h"

@implementation NEHistorySearchImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
    return _imageView;
}

- (void)setupUI {
    [self.contentView addSubview:self.imageView];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
}

- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[MessageImageModel class]]) {
        return;
    }
    MessageImageModel *imageModel = (MessageImageModel *)model;
    NSString *imageUrl = imageModel.urlString;

    if (imageUrl.length > 0) {
        SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;

        if ([imageUrl hasPrefix:@"http"]) {
            NSURL *url = [NSURL URLWithString:imageUrl];
            __weak typeof(self) weakSelf = self;
            [self.imageView sd_setImageWithURL:url completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error) {
                    NSError *err = error;
                    if (err.code == 2001) {
                        V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)imageModel.message.attachment;
                        if (imageObject.url.length > 0) {
                            NSURL *retryUrl = [NSURL URLWithString:imageObject.url];
                            NSDictionary *context = @{SDWebImageContextImageThumbnailPixelSize: [NSValue valueWithCGSize:CGSizeMake(350, 350)]};
                            [weakSelf.imageView sd_setImageWithURL:retryUrl
                                                 placeholderImage:[UIImage imageWithContentsOfFile:imageObject.url]
                                                          options:options
                                                          context:context
                                                         progress:nil
                                                        completed:nil];
                        } else {
                            weakSelf.imageView.image = [UIImage ne_imageNamed:@"default_image"];
                        }
                    } else {
                        weakSelf.imageView.image = [UIImage ne_imageNamed:@"default_image"];
                    }
                }
            }];
        } else {
            NSURL *url = [NSURL fileURLWithPath:imageUrl];
            [self.imageView sd_setImageWithURL:url placeholderImage:nil options:options context:nil progress:nil completed:nil];
        }
    } else {
        self.imageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
}

@end
