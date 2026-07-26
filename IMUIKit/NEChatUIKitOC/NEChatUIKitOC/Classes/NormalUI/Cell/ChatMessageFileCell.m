// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageFileCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatMessageHelper.h"
#import "NEChatUIConstant.h"

@implementation ChatMessageFileCell

- (UIImageView *)imgViewLeft {
    if (!_imgViewLeft) {
        _imgViewLeft = [[UIImageView alloc] init];
        _imgViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _imgViewLeft.backgroundColor = UIColor.clearColor;
        _imgViewLeft.accessibilityIdentifier = @"id.fileType";
    }
    return _imgViewLeft;
}

- (FileStateView *)stateViewLeft {
    if (!_stateViewLeft) {
        _stateViewLeft = [[FileStateView alloc] init];
        _stateViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewLeft.backgroundColor = UIColor.clearColor;
        _stateViewLeft.accessibilityIdentifier = @"id.fileStatus";
    }
    return _stateViewLeft;
}

- (UILabel *)titleLabelLeft {
    if (!_titleLabelLeft) {
        _titleLabelLeft = [[UILabel alloc] init];
        _titleLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft.userInteractionEnabled = NO;
        _titleLabelLeft.numberOfLines = 1;
        _titleLabelLeft.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _titleLabelLeft.font = DefaultTextFont(14);
        _titleLabelLeft.textAlignment = NSTextAlignmentLeft;
        _titleLabelLeft.accessibilityIdentifier = @"id.displayName";
    }
    return _titleLabelLeft;
}

- (UILabel *)sizeLabelLeft {
    if (!_sizeLabelLeft) {
        _sizeLabelLeft = [[UILabel alloc] init];
        _sizeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _sizeLabelLeft.textColor = [UIColor ne_colorWithHexString:@"#999999"];
        _sizeLabelLeft.font = [NEConstant defaultTextFont:10.0];
        _sizeLabelLeft.textAlignment = NSTextAlignmentLeft;
        _sizeLabelLeft.accessibilityIdentifier = @"id.displaySize";
    }
    return _sizeLabelLeft;
}

- (UIView *)labelViewLeft {
    if (!_labelViewLeft) {
        _labelViewLeft = [[UIView alloc] init];
        _labelViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _labelViewLeft.userInteractionEnabled = NO;
        [_labelViewLeft addSubview:self.titleLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabelLeft.leftAnchor constraintEqualToAnchor:_labelViewLeft.leftAnchor],
            [self.titleLabelLeft.topAnchor constraintEqualToAnchor:_labelViewLeft.topAnchor],
            [self.titleLabelLeft.rightAnchor constraintEqualToAnchor:_labelViewLeft.rightAnchor],
            [self.titleLabelLeft.heightAnchor constraintEqualToConstant:18],
        ]];
        [_labelViewLeft addSubview:self.sizeLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.sizeLabelLeft.leftAnchor constraintEqualToAnchor:_labelViewLeft.leftAnchor],
            [self.sizeLabelLeft.topAnchor constraintEqualToAnchor:self.titleLabelLeft.bottomAnchor constant:5],
            [self.sizeLabelLeft.rightAnchor constraintEqualToAnchor:_labelViewLeft.rightAnchor],
            [self.sizeLabelLeft.heightAnchor constraintEqualToConstant:10],
        ]];
    }
    return _labelViewLeft;
}

- (UIView *)backViewLeft {
    if (!_backViewLeft) {
        _backViewLeft = [[UIView alloc] init];
        _backViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _backViewLeft.backgroundColor = UIColor.whiteColor;
        _backViewLeft.layer.cornerRadius = 8;
        _backViewLeft.layer.borderColor = UIColor.ne_borderColor.CGColor;
        _backViewLeft.layer.borderWidth = 1;

        [_backViewLeft addSubview:self.imgViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.imgViewLeft.leftAnchor constraintEqualToAnchor:_backViewLeft.leftAnchor constant:10],
            [self.imgViewLeft.centerYAnchor constraintEqualToAnchor:_backViewLeft.centerYAnchor],
            [self.imgViewLeft.widthAnchor constraintEqualToConstant:32],
            [self.imgViewLeft.heightAnchor constraintEqualToConstant:32],
        ]];
        [self.imgViewLeft addSubview:self.stateViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.stateViewLeft.leftAnchor constraintEqualToAnchor:self.imgViewLeft.leftAnchor constant:0],
            [self.stateViewLeft.topAnchor constraintEqualToAnchor:self.imgViewLeft.topAnchor constant:0],
            [self.stateViewLeft.widthAnchor constraintEqualToConstant:32],
            [self.stateViewLeft.heightAnchor constraintEqualToConstant:32],
        ]];
        [_backViewLeft addSubview:self.labelViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.labelViewLeft.leftAnchor constraintEqualToAnchor:self.imgViewLeft.rightAnchor constant:15],
            [self.labelViewLeft.topAnchor constraintEqualToAnchor:_backViewLeft.topAnchor constant:10],
            [self.labelViewLeft.rightAnchor constraintEqualToAnchor:_backViewLeft.rightAnchor constant:-10],
            [self.labelViewLeft.bottomAnchor constraintEqualToAnchor:_backViewLeft.bottomAnchor constant:0],
        ]];
    }
    return _backViewLeft;
}

- (UIImageView *)imgViewRight {
    if (!_imgViewRight) {
        _imgViewRight = [[UIImageView alloc] init];
        _imgViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _imgViewRight.backgroundColor = UIColor.clearColor;
        _imgViewRight.accessibilityIdentifier = @"id.fileType";
    }
    return _imgViewRight;
}

- (FileStateView *)stateViewRight {
    if (!_stateViewRight) {
        _stateViewRight = [[FileStateView alloc] init];
        _stateViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewRight.backgroundColor = UIColor.clearColor;
        _stateViewRight.accessibilityIdentifier = @"id.fileStatus";
    }
    return _stateViewRight;
}

- (UILabel *)titleLabelRight {
    if (!_titleLabelRight) {
        _titleLabelRight = [[UILabel alloc] init];
        _titleLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelRight.userInteractionEnabled = NO;
        _titleLabelRight.numberOfLines = 1;
        _titleLabelRight.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _titleLabelRight.font = DefaultTextFont(14);
        _titleLabelRight.textAlignment = NSTextAlignmentLeft;
        _titleLabelRight.accessibilityIdentifier = @"id.displayName";
    }
    return _titleLabelRight;
}

- (UILabel *)sizeLabelRight {
    if (!_sizeLabelRight) {
        _sizeLabelRight = [[UILabel alloc] init];
        _sizeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _sizeLabelRight.textColor = [UIColor ne_colorWithHexString:@"#999999"];
        _sizeLabelRight.font = [NEConstant defaultTextFont:10.0];
        _sizeLabelRight.textAlignment = NSTextAlignmentLeft;
        _sizeLabelRight.accessibilityIdentifier = @"id.displaySize";
    }
    return _sizeLabelRight;
}

- (UIView *)labelViewRight {
    if (!_labelViewRight) {
        _labelViewRight = [[UIView alloc] init];
        _labelViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _labelViewRight.userInteractionEnabled = NO;
        [_labelViewRight addSubview:self.titleLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabelRight.leftAnchor constraintEqualToAnchor:_labelViewRight.leftAnchor],
            [self.titleLabelRight.topAnchor constraintEqualToAnchor:_labelViewRight.topAnchor],
            [self.titleLabelRight.rightAnchor constraintEqualToAnchor:_labelViewRight.rightAnchor],
            [self.titleLabelRight.heightAnchor constraintEqualToConstant:18],
        ]];
        [_labelViewRight addSubview:self.sizeLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.sizeLabelRight.leftAnchor constraintEqualToAnchor:_labelViewRight.leftAnchor],
            [self.sizeLabelRight.topAnchor constraintEqualToAnchor:self.titleLabelRight.bottomAnchor constant:5],
            [self.sizeLabelRight.rightAnchor constraintEqualToAnchor:_labelViewRight.rightAnchor],
            [self.sizeLabelRight.heightAnchor constraintEqualToConstant:10],
        ]];
    }
    return _labelViewRight;
}

- (UIView *)backViewRight {
    if (!_backViewRight) {
        _backViewRight = [[UIView alloc] init];
        _backViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _backViewRight.backgroundColor = UIColor.whiteColor;
        _backViewRight.layer.cornerRadius = 8;
        _backViewRight.layer.borderColor = UIColor.ne_borderColor.CGColor;
        _backViewRight.layer.borderWidth = 1;

        [_backViewRight addSubview:self.imgViewRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.imgViewRight.leftAnchor constraintEqualToAnchor:_backViewRight.leftAnchor constant:10],
            [self.imgViewRight.centerYAnchor constraintEqualToAnchor:_backViewRight.centerYAnchor],
            [self.imgViewRight.widthAnchor constraintEqualToConstant:32],
            [self.imgViewRight.heightAnchor constraintEqualToConstant:32],
        ]];
        [self.imgViewRight addSubview:self.stateViewRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.stateViewRight.leftAnchor constraintEqualToAnchor:self.imgViewRight.leftAnchor constant:0],
            [self.stateViewRight.topAnchor constraintEqualToAnchor:self.imgViewRight.topAnchor constant:0],
            [self.stateViewRight.widthAnchor constraintEqualToConstant:32],
            [self.stateViewRight.heightAnchor constraintEqualToConstant:32],
        ]];
        [_backViewRight addSubview:self.labelViewRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.labelViewRight.leftAnchor constraintEqualToAnchor:self.imgViewRight.rightAnchor constant:15],
            [self.labelViewRight.topAnchor constraintEqualToAnchor:_backViewRight.topAnchor constant:10],
            [self.labelViewRight.rightAnchor constraintEqualToAnchor:_backViewRight.rightAnchor constant:-10],
            [self.labelViewRight.bottomAnchor constraintEqualToAnchor:_backViewRight.bottomAnchor constant:0],
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

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.backViewLeft.hidden = showRight;
    self.backViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    FileStateView *stateView = isSend ? self.stateViewRight : self.stateViewLeft;
    UIImageView *imgView = isSend ? self.imgViewRight : self.imgViewLeft;
    UILabel *titleLabel = isSend ? self.titleLabelRight : self.titleLabelLeft;
    UILabel *sizeLabel = isSend ? self.sizeLabelRight : self.sizeLabelLeft;
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;
    UIImageView *bubble = isSend ? self.bubbleImageRight : self.bubbleImageLeft;

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    bubbleW.constant = screenWidth <= 320 ? 222 : 242;

    if (model.isReply) {
        [self setBubbleImage];
    } else {
        bubble.image = nil;
    }

    if ([model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) {
        V2NIMMessageFileAttachment *fileObject = (V2NIMMessageFileAttachment *)model.message.attachment;
        if ([model isKindOfClass:[MessageFileModel class]]) {
            MessageFileModel *fileModel = (MessageFileModel *)model;
            self.weakModel.cell = nil;
            self.weakModel = fileModel;
            fileModel.cell = self;
            fileModel.size = (float)fileObject.size;
            if (fileModel.state == FileStateSuccess) {
                stateView.state = FileOpenState;
            } else {
                stateView.state = FileDownloadState;
                [stateView setProgress:(float)fileModel.progress / 100];
                if (fileModel.progress >= 100) {
                    fileModel.state = FileStateSuccess;
                }
            }
        }

        NSString *imageName = @"file_unknown";
        NSString *suffix = [[fileObject.name pathExtension] lowercaseString];
        if (suffix.length == 0 && fileObject.ext.length > 1) {
            suffix = [[fileObject.ext substringFromIndex:1] lowercaseString];
        }

        if ([file_doc_support() containsObject:suffix]) imageName = @"file_doc";
        else if ([file_xls_support() containsObject:suffix]) imageName = @"file_xls";
        else if ([file_img_support() containsObject:suffix]) imageName = @"file_img";
        else if ([file_ppt_support() containsObject:suffix]) imageName = @"file_ppt";
        else if ([file_txt_support() containsObject:suffix]) imageName = @"file_txt";
        else if ([file_audio_support() containsObject:suffix]) imageName = @"file_audio";
        else if ([file_video_support() containsObject:suffix]) imageName = @"file_vedio";
        else if ([file_zip_support() containsObject:suffix]) imageName = @"file_zip";
        else if ([file_pdf_support() containsObject:suffix]) imageName = @"file_pdf";
        else if ([file_html_support() containsObject:suffix]) imageName = @"file_html";
        else if ([suffix isEqualToString:@"key"] || [suffix isEqualToString:@"keynote"]) imageName = @"file_keynote";

        imgView.image = [UIImage ne_imageNamed:imageName];
        titleLabel.text = fileObject.name;

        double size_B = (double)fileObject.size;
        NSString *size_str = [NSString stringWithFormat:@"%.2f B", size_B];
        if (size_B > 1e3) {
            double size_KB = size_B / 1e3;
            size_str = [NSString stringWithFormat:@"%.2f KB", size_KB];
            if (size_KB > 1e3) {
                double size_MB = size_KB / 1e3;
                size_str = [NSString stringWithFormat:@"%.2f MB", size_MB];
                if (size_MB > 1e3) {
                    double size_GB = size_KB / 1e6;
                    size_str = [NSString stringWithFormat:@"%.2f GB", size_GB];
                }
            }
        }
        sizeLabel.text = size_str;
    }
}

- (void)uploadProgress:(NSUInteger)progress {
    BOOL isSend = [ChatMessageHelper isSelf:self.contentModel.message];
    FileStateView *stateView = isSend ? self.stateViewRight : self.stateViewLeft;
    stateView.state = FileDownloadState;
    [stateView setProgress:(float)progress / 100];
}

@end
