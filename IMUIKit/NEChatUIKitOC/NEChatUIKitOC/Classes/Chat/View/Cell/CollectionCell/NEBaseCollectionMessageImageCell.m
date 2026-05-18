// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageImageCell.h"
#import "UIImage+Chat.h"
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageContentModel.h"
#import "MessageImageModel.h"

@implementation NEBaseCollectionMessageImageCell

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

- (UIImageView *)collectionContentImageView {
    if (!_collectionContentImageView) {
        _collectionContentImageView = [[UIImageView alloc] init];
        _collectionContentImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionContentImageView.contentMode = UIViewContentModeScaleAspectFill;
        _collectionContentImageView.clipsToBounds = YES;
        _collectionContentImageView.userInteractionEnabled = YES;
        _collectionContentImageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
    return _collectionContentImageView;
}

- (void)setupCommonUI {
    [super setupCommonUI];
    [self.collectionContentImageView addCustomCorner:UIRectCornerAllCorners radius:8 backcolor:UIColor.whiteColor];
    [self.backView addSubview:self.collectionContentImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionContentImageView.leftAnchor constraintEqualToAnchor:self.line.leftAnchor constant:0],
        [self.collectionContentImageView.bottomAnchor constraintEqualToAnchor:self.line.topAnchor constant:-12],
    ]];
    self.contentWidth = [self.collectionContentImageView.widthAnchor constraintEqualToConstant:0];
    self.contentWidth.active = YES;
    self.contentHeight = [self.collectionContentImageView.heightAnchor constraintEqualToConstant:0];
    self.contentHeight.active = YES;

    if (self.contentGesture) {
        [self.collectionContentImageView addGestureRecognizer:self.contentGesture];
    }
}

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    if ([model.chatmodel isKindOfClass:[MessageImageModel class]]) {
        MessageImageModel *m = (MessageImageModel *)model.chatmodel;
        NSString *imageUrl = m.urlString;
        if (imageUrl.length > 0) {
            SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;
            if ([imageUrl hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:imageUrl];
                __weak typeof(self) weakSelf = self;
                [self.collectionContentImageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    if (error) {
                        if (error.code == 2001) {
                            V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)model.message.attachment;
                            if ([imageObject isKindOfClass:[V2NIMMessageImageAttachment class]] && imageObject.url.length > 0) {
                                NSURL *retryUrl = [NSURL URLWithString:imageObject.url];
                                NSDictionary *context = @{SDWebImageContextImageThumbnailPixelSize: [NSValue valueWithCGSize:CGSizeMake(350, 350)]};
                                [weakSelf.collectionContentImageView sd_setImageWithURL:retryUrl
                                                                       placeholderImage:[UIImage imageWithContentsOfFile:imageObject.url]
                                                                                options:options
                                                                                context:context
                                                                               progress:nil
                                                                              completed:nil];
                            }
                        } else {
                            weakSelf.collectionContentImageView.image = [UIImage ne_imageNamed:@"default_image"];
                        }
                    }
                }];
            } else {
                NSURL *url = [NSURL fileURLWithPath:imageUrl];
                [self.collectionContentImageView sd_setImageWithURL:url placeholderImage:nil options:options context:nil];
            }
        } else {
            self.collectionContentImageView.image = [UIImage ne_imageNamed:@"default_image"];
        }
    } else {
        self.collectionContentImageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
}

@end
