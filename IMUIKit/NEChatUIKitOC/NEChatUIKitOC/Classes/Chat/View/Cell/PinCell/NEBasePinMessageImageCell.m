// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageImageCell.h"
#import "UIImage+Chat.h"
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageContentModel.h"
#import "MessageImageModel.h"

@implementation NEBasePinMessageImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupUI {
    [super setupUI];
    _contentImageView = [[UIImageView alloc] init];
    _contentImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    _contentImageView.clipsToBounds = YES;
    _contentImageView.userInteractionEnabled = YES;
    _contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
    [_contentImageView addCustomCorner:UIRectCornerAllCorners radius:8 backcolor:UIColor.whiteColor];
    [self.backView addSubview:_contentImageView];
    [NSLayoutConstraint activateConstraints:@[
        [_contentImageView.leftAnchor constraintEqualToAnchor:self.line.leftAnchor constant:0],
        [_contentImageView.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
    ]];
    self.contentWidth = [_contentImageView.widthAnchor constraintEqualToConstant:0];
    self.contentWidth.active = YES;
    self.contentHeight = [_contentImageView.heightAnchor constraintEqualToConstant:0];
    self.contentHeight.active = YES;

    if (self.contentGesture) {
        [_contentImageView addGestureRecognizer:self.contentGesture];
    }
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    if ([item.chatmodel isKindOfClass:[MessageImageModel class]]) {
        MessageImageModel *m = (MessageImageModel *)item.chatmodel;
        NSString *imageUrl = m.urlString;
        if (imageUrl.length > 0) {
            SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;
            if ([imageUrl hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:imageUrl];
                __weak typeof(self) weakSelf = self;
                [self.contentImageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if (error) {
                        if (error.code == 2001) {
                            V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)item.message.attachment;
                            if ([imageObject isKindOfClass:[V2NIMMessageImageAttachment class]] && imageObject.url.length > 0) {
                                NSURL *retryUrl = [NSURL URLWithString:imageObject.url];
                                NSDictionary *context = @{SDWebImageContextImageThumbnailPixelSize: [NSValue valueWithCGSize:CGSizeMake(350, 350)]};
                                [weakSelf.contentImageView sd_setImageWithURL:retryUrl
                                                             placeholderImage:[UIImage imageWithContentsOfFile:imageObject.url]
                                                                      options:options
                                                                      context:context
                                                                     progress:nil
                                                                    completed:nil];
                            }
                        } else {
                            weakSelf.contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
                        }
                    }
                }];
            } else {
                NSURL *url = [NSURL fileURLWithPath:imageUrl];
                [self.contentImageView sd_setImageWithURL:url placeholderImage:nil options:options context:nil];
            }
        } else {
            self.contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
        }
    } else {
        self.contentImageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
}

@end
