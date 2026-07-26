// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageReplyCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/NSString+NECommon.h>
#import "MessageImageModel.h"
#import <SDWebImage/SDWebImage.h>

@implementation ChatMessageReplyCell

- (UIImageView *)replyImageViewLeft {
    if (!_replyImageViewLeft) {
        _replyImageViewLeft = [[UIImageView alloc] init];
        _replyImageViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyImageViewLeft.contentMode = UIViewContentModeScaleAspectFill;
        _replyImageViewLeft.clipsToBounds = YES;
        _replyImageViewLeft.accessibilityIdentifier = @"id.thumbnail";
        _replyImageViewLeft.layer.cornerRadius = 8;
    }
    return _replyImageViewLeft;
}

- (UIImageView *)replyImageViewRight {
    if (!_replyImageViewRight) {
        _replyImageViewRight = [[UIImageView alloc] init];
        _replyImageViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyImageViewRight.contentMode = UIViewContentModeScaleAspectFill;
        _replyImageViewRight.clipsToBounds = YES;
        _replyImageViewRight.accessibilityIdentifier = @"id.thumbnail";
        _replyImageViewRight.layer.cornerRadius = 8;
    }
    return _replyImageViewRight;
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.replyLabelLeft.hidden = showRight;
    self.replyImageViewLeft.hidden = showRight;
    self.replyLabelRight.hidden = !showRight;
    self.replyImageViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    UILabel *replyLabel = isSend ? self.replyLabelRight : self.replyLabelLeft;

    if (model.replyText.length > 0 && replyLabel.font) {
        NSString *text = model.replyText;
        if (![text isEqualToString:chatLocalizable(@"message_not_found")]) {
            text = [@"| " stringByAppendingString:text];
        }
        replyLabel.attributedText = [NEEmotionTool getAttWithStr:text font:replyLabel.font color:replyLabel.textColor offset:CGPointMake(0, -4)];
        replyLabel.accessibilityValue = text;

        if (replyLabel.attributedText) {
            CGSize textSize = [NSAttributedString ne_getRealLabelSize:replyLabel.attributedText font:replyLabel.font size:CGSizeMake(chat_text_maxW, CGFLOAT_MAX) numberOfLines:0];
            model.contentSize = CGSizeMake(MAX(textSize.width, model.textWidth) + chat_content_margin * 2, model.contentSize.height);
        }
    }

    [super setModel:model isSend:isSend];

    UIImageView *replyImageView = isSend ? self.replyImageViewRight : self.replyImageViewLeft;
    if ([model isKindOfClass:[MessageImageModel class]]) {
        MessageImageModel *m = (MessageImageModel *)model;
        NSString *imageUrl = m.urlString;
        if (imageUrl.length > 0) {
            SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageAllowInvalidSSLCertificates;
            if ([imageUrl hasPrefix:@"http"]) {
                __weak typeof(replyImageView) weakImageView = replyImageView;
                [replyImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
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
                [replyImageView sd_setImageWithURL:[NSURL fileURLWithPath:imageUrl] placeholderImage:nil options:options context:nil];
            }
        } else {
            replyImageView.image = [UIImage ne_imageNamed:@"default_image"];
        }
    } else {
        replyImageView.image = [UIImage ne_imageNamed:@"default_image"];
    }
}

@end
