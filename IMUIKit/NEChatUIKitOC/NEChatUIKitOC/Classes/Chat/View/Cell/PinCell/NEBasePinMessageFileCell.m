// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageFileCell.h"
#import "UIImage+Chat.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NECommonKitOC.h>
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"
#import "MessageContentModel.h"

@implementation NEBasePinMessageFileCell

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

- (FileStateView *)stateView {
    if (!_stateView) {
        _stateView = [[FileStateView alloc] init];
        _stateView.translatesAutoresizingMaskIntoConstraints = NO;
        _stateView.backgroundColor = UIColor.clearColor;
    }
    return _stateView;
}

- (UIImageView *)imgView {
    if (!_imgView) {
        _imgView = [[UIImageView alloc] init];
        _imgView.translatesAutoresizingMaskIntoConstraints = NO;
        _imgView.backgroundColor = UIColor.clearColor;
    }
    return _imgView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.userInteractionEnabled = NO;
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _titleLabel.font = DefaultTextFont(14);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _sizeLabel.textColor = [UIColor ne_colorWithHexString:@"#999999"];
        _sizeLabel.font = [NEConstant defaultTextFont:10.0];
        _sizeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _sizeLabel;
}

- (UIView *)labelView {
    if (!_labelView) {
        _labelView = [[UIView alloc] init];
        _labelView.translatesAutoresizingMaskIntoConstraints = NO;
        _labelView.userInteractionEnabled = NO;
        [_labelView addSubview:self.titleLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabel.leftAnchor constraintEqualToAnchor:_labelView.leftAnchor],
            [self.titleLabel.topAnchor constraintEqualToAnchor:_labelView.topAnchor],
            [self.titleLabel.rightAnchor constraintEqualToAnchor:_labelView.rightAnchor],
            [self.titleLabel.heightAnchor constraintEqualToConstant:18],
        ]];
        [_labelView addSubview:self.sizeLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.sizeLabel.leftAnchor constraintEqualToAnchor:_labelView.leftAnchor],
            [self.sizeLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:5],
            [self.sizeLabel.rightAnchor constraintEqualToAnchor:_labelView.rightAnchor],
            [self.sizeLabel.heightAnchor constraintEqualToConstant:10],
        ]];
    }
    return _labelView;
}

- (void)setupUI {
    [super setupUI];

    _bubbleImage = [[UIImageView alloc] init];
    _bubbleImage.image = nil;
    _bubbleImage.layer.cornerRadius = 8;
    _bubbleImage.layer.borderColor = UIColor.ne_borderColor.CGColor;
    _bubbleImage.layer.borderWidth = 1;
    _bubbleImage.translatesAutoresizingMaskIntoConstraints = NO;
    _bubbleImage.userInteractionEnabled = YES;
    [self.backView addSubview:_bubbleImage];
    self.contentWidth = [_bubbleImage.widthAnchor constraintEqualToConstant:chat_content_maxW()];
    self.contentHeight = [_bubbleImage.heightAnchor constraintEqualToConstant:chat_content_maxW()];
    [NSLayoutConstraint activateConstraints:@[
        self.contentHeight,
        self.contentWidth,
        [_bubbleImage.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16],
        [_bubbleImage.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
    ]];

    [_bubbleImage addSubview:self.imgView];
    [NSLayoutConstraint activateConstraints:@[
        [self.imgView.leftAnchor constraintEqualToAnchor:_bubbleImage.leftAnchor constant:10],
        [self.imgView.topAnchor constraintEqualToAnchor:_bubbleImage.topAnchor constant:10],
        [self.imgView.widthAnchor constraintEqualToConstant:32],
        [self.imgView.heightAnchor constraintEqualToConstant:32],
    ]];

    [_bubbleImage addSubview:self.labelView];
    [NSLayoutConstraint activateConstraints:@[
        [self.labelView.leftAnchor constraintEqualToAnchor:self.imgView.rightAnchor constant:15],
        [self.labelView.topAnchor constraintEqualToAnchor:_bubbleImage.topAnchor constant:10],
        [self.labelView.rightAnchor constraintEqualToAnchor:_bubbleImage.rightAnchor constant:-10],
        [self.labelView.bottomAnchor constraintEqualToAnchor:_bubbleImage.bottomAnchor constant:0],
    ]];

    [_bubbleImage addSubview:self.stateView];
    [NSLayoutConstraint activateConstraints:@[
        [self.stateView.leftAnchor constraintEqualToAnchor:_bubbleImage.leftAnchor constant:10],
        [self.stateView.topAnchor constraintEqualToAnchor:_bubbleImage.topAnchor constant:10],
        [self.stateView.widthAnchor constraintEqualToConstant:32],
        [self.stateView.heightAnchor constraintEqualToConstant:32],
    ]];

    if (self.contentGesture) {
        [_bubbleImage addGestureRecognizer:self.contentGesture];
    }
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    V2NIMMessageFileAttachment *fileObject = (V2NIMMessageFileAttachment *)item.message.attachment;
    if (![fileObject isKindOfClass:[V2NIMMessageFileAttachment class]]) return;

    if (item.pinFileModel) {
        item.pinFileModel.cell = self;
        if (item.pinFileModel.state == DownloadStateSuccess) {
            self.stateView.state = FileStateOpen;
        } else {
            self.stateView.state = FileStateDownload;
            [self.stateView setProgress:(float)item.pinFileModel.progress];
            if (item.pinFileModel.progress >= 100) {
                item.pinFileModel.state = DownloadStateSuccess;
            }
        }
    }

    NSString *imageName = @"file_unknown";
    NSString *suffix = [((NSString *)fileObject.name).pathExtension lowercaseString];
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

    self.imgView.image = [UIImage ne_imageNamed:imageName];
    self.titleLabel.text = fileObject.name;

    double size_B = fileObject.size;
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
    self.sizeLabel.text = size_str;
}

- (void)uploadProgress:(NSUInteger)progress {
    [self.stateView setProgress:(float)progress];
}

@end
