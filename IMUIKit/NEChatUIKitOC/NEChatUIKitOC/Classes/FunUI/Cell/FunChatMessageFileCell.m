// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageFileCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatCellConstantValue.h"
#import "ChatMessageHelper.h"
#import "MessageFileModel.h"

@interface FunChatMessageFileCell ()
@property (nonatomic, weak) MessageFileModel *weakModel;
@end

@implementation FunChatMessageFileCell

- (void)commonUILeft {
    self.bubbleImageLeft.image = nil;
    self.bubbleImageLeft.backgroundColor = [UIColor whiteColor];
    self.bubbleImageLeft.layer.cornerRadius = 4;
    self.bubbleImageLeft.layer.borderColor = [UIColor ne_borderColor].CGColor;
    self.bubbleImageLeft.layer.borderWidth = 1;

    [self addSubview:self.imgViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.imgViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:10],
        [self.imgViewLeft.centerYAnchor constraintEqualToAnchor:self.bubbleImageLeft.centerYAnchor],
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

    [self addSubview:self.labelViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.labelViewLeft.leftAnchor constraintEqualToAnchor:self.imgViewLeft.rightAnchor constant:15],
        [self.labelViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:10],
        [self.labelViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-10],
        [self.labelViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:0],
    ]];
}

- (void)commonUIRight {
    self.bubbleImageRight.image = nil;
    self.bubbleImageRight.backgroundColor = [UIColor whiteColor];
    self.bubbleImageRight.layer.cornerRadius = 4;
    self.bubbleImageRight.layer.borderColor = [UIColor ne_borderColor].CGColor;
    self.bubbleImageRight.layer.borderWidth = 1;

    [self addSubview:self.imgViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.imgViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:10],
        [self.imgViewRight.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
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

    [self addSubview:self.labelViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.labelViewRight.leftAnchor constraintEqualToAnchor:self.imgViewRight.rightAnchor constant:15],
        [self.labelViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:10],
        [self.labelViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-10],
        [self.labelViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.imgViewLeft.hidden = showRight;
    self.stateViewLeft.hidden = showRight;
    self.labelViewLeft.hidden = showRight;
    self.imgViewRight.hidden = !showRight;
    self.stateViewRight.hidden = !showRight;
    self.labelViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    FileStateView *stateView = isSend ? self.stateViewRight : self.stateViewLeft;
    UIImageView *imgView = isSend ? self.imgViewRight : self.imgViewLeft;
    UILabel *titleLabel = isSend ? self.titleLabelRight : self.titleLabelLeft;
    UILabel *sizeLabel = isSend ? self.sizeLabelRight : self.sizeLabelLeft;
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;

    bubbleW.constant = kScreenWidth() <= 320 ? 222 : 242;

    V2NIMMessageFileAttachment *fileObject = (V2NIMMessageFileAttachment *)model.message.attachment;
    if (fileObject) {
        if ([model isKindOfClass:[MessageFileModel class]]) {
            MessageFileModel *fileModel = (MessageFileModel *)model;
            self.weakModel.cell = nil;
            self.weakModel = fileModel;
            fileModel.cell = self;
            fileModel.size = fileObject.size;
            if (fileModel.state == FileStateSuccess) {
                stateView.state = FileOpenState;
            } else {
                stateView.state = FileDownloadState;
                [stateView setProgress:(float)fileModel.progress / 100.0];
                if (fileModel.progress >= 100) {
                    fileModel.state = FileStateSuccess;
                }
            }
        }

        NSString *imageName = @"file_unknown";
        NSString *suffix = [fileObject.name.pathExtension lowercaseString];
        if (suffix.length == 0 && fileObject.ext.length > 1) {
            suffix = [fileObject.ext substringFromIndex:1].lowercaseString;
        }

        NSDictionary *fileTypeMap = @{
            @"doc": @"file_doc", @"docx": @"file_doc",
            @"xls": @"file_xls", @"xlsx": @"file_xls",
            @"jpg": @"file_img", @"jpeg": @"file_img", @"png": @"file_img", @"gif": @"file_img", @"bmp": @"file_img",
            @"ppt": @"file_ppt", @"pptx": @"file_ppt",
            @"txt": @"file_txt",
            @"mp3": @"file_audio", @"aac": @"file_audio", @"wav": @"file_audio",
            @"mp4": @"file_vedio", @"mov": @"file_vedio", @"avi": @"file_vedio",
            @"zip": @"file_zip", @"rar": @"file_zip", @"7z": @"file_zip",
            @"pdf": @"file_pdf",
            @"html": @"file_html", @"htm": @"file_html",
            @"key": @"file_keynote", @"keynote": @"file_keynote",
        };
        if (fileTypeMap[suffix]) {
            imageName = fileTypeMap[suffix];
        }

        imgView.image = [UIImage ne_imageNamed:imageName];
        titleLabel.text = fileObject.name;

        double size_B = fileObject.size;
        NSString *size_str;
        if (size_B > 1e9) {
            size_str = [NSString stringWithFormat:@"%.2f GB", size_B / 1e9];
        } else if (size_B > 1e6) {
            size_str = [NSString stringWithFormat:@"%.2f MB", size_B / 1e6];
        } else if (size_B > 1e3) {
            size_str = [NSString stringWithFormat:@"%.2f KB", size_B / 1e3];
        } else {
            size_str = [NSString stringWithFormat:@"%.2f B", size_B];
        }
        sizeLabel.text = size_str;
    }
}

- (void)uploadProgress:(NSUInteger)progress {
    BOOL isSend = [ChatMessageHelper isSelf:self.contentModel.message];
    FileStateView *stateView = isSend ? self.stateViewRight : self.stateViewLeft;
    stateView.state = FileDownloadState;
    [stateView setProgress:(float)progress / 100.0];
}

#pragma mark - Lazy Load

- (UIImageView *)imgViewLeft {
    if (!_imgViewLeft) {
        _imgViewLeft = [[UIImageView alloc] init];
        _imgViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _imgViewLeft.backgroundColor = [UIColor clearColor];
        _imgViewLeft.accessibilityIdentifier = @"id.fileType";
    }
    return _imgViewLeft;
}

- (FileStateView *)stateViewLeft {
    if (!_stateViewLeft) {
        _stateViewLeft = [[FileStateView alloc] init];
        _stateViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewLeft.backgroundColor = [UIColor clearColor];
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
        _titleLabelLeft.font = [UIFont systemFontOfSize:14];
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
        _sizeLabelLeft.font = [UIFont systemFontOfSize:10];
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

- (UIImageView *)imgViewRight {
    if (!_imgViewRight) {
        _imgViewRight = [[UIImageView alloc] init];
        _imgViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _imgViewRight.backgroundColor = [UIColor clearColor];
        _imgViewRight.accessibilityIdentifier = @"id.fileType";
    }
    return _imgViewRight;
}

- (FileStateView *)stateViewRight {
    if (!_stateViewRight) {
        _stateViewRight = [[FileStateView alloc] init];
        _stateViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewRight.backgroundColor = [UIColor clearColor];
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
        _titleLabelRight.font = [UIFont systemFontOfSize:14];
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
        _sizeLabelRight.font = [UIFont systemFontOfSize:10];
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

@end
