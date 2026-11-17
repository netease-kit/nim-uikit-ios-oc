// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEHistorySearchFileCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NIMSDK/NIMSDK.h>
#import "FunChatUIColor.h"
#import "ChatMessageHelper.h"

@implementation NEHistorySearchFileCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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

- (NEUserHeaderView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarImageView.layer.cornerRadius = 12;
        _avatarImageView.clipsToBounds = YES;
    }
    return _avatarImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = UIColor.ne_darkText;
    }
    return _nameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = UIColor.ne_greyText;
    }
    return _timeLabel;
}

- (UIView *)fileBackView {
    if (!_fileBackView) {
        _fileBackView = [[UIView alloc] init];
        _fileBackView.translatesAutoresizingMaskIntoConstraints = NO;
        _fileBackView.backgroundColor = [UIColor ne_colorWithHexString:@"#F4F4F4"];
        _fileBackView.layer.cornerRadius = 4;
    }
    return _fileBackView;
}

- (UIImageView *)fileIconImageView {
    if (!_fileIconImageView) {
        _fileIconImageView = [[UIImageView alloc] init];
        _fileIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _fileIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _fileIconImageView;
}

- (UILabel *)fileNameLabel {
    if (!_fileNameLabel) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _fileNameLabel.textColor = UIColor.ne_greyText;
        _fileNameLabel.numberOfLines = 1;
        _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _fileNameLabel;
}

- (UILabel *)fileSizeLabel {
    if (!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc] init];
        _fileSizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _fileSizeLabel.font = [UIFont systemFontOfSize:12];
        _fileSizeLabel.textColor = UIColor.ne_greyText;
    }
    return _fileSizeLabel;
}

- (ExpandButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [[ExpandButton alloc] init];
        _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_moreButton setImage:[UIImage ne_imageNamed:@"history_file_more"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIView *)lineBottom {
    if (!_lineBottom) {
        _lineBottom = [[UIView alloc] init];
        _lineBottom.translatesAutoresizingMaskIntoConstraints = NO;
        _lineBottom.backgroundColor = [UIColor.ne_defaultLineColor colorWithAlphaComponent:0.5];
    }
    return _lineBottom;
}

- (FileStateView *)stateView {
    if (!_stateView) {
        _stateView = [[FileStateView alloc] init];
        _stateView.translatesAutoresizingMaskIntoConstraints = NO;
        _stateView.backgroundColor = UIColor.clearColor;
    }
    return _stateView;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.whiteColor;

    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.fileBackView];
    [self.contentView addSubview:self.fileIconImageView];
    [self.contentView addSubview:self.stateView];
    [self.contentView addSubview:self.fileNameLabel];
    [self.contentView addSubview:self.fileSizeLabel];
    [self.contentView addSubview:self.moreButton];
    [self.contentView addSubview:self.lineBottom];

    [NSLayoutConstraint activateConstraints:@[
        // 头像
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:24],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:24],

        // 发送者姓名
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:12],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.timeLabel.leadingAnchor constant:-8],

        // 发送时间
        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],

        // 文件背景
        [self.fileBackView.leadingAnchor constraintEqualToAnchor:self.avatarImageView.leadingAnchor constant:0],
        [self.fileBackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.fileBackView.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:16],
        [self.fileBackView.heightAnchor constraintEqualToConstant:60],

        // 文件图标
        [self.fileIconImageView.leadingAnchor constraintEqualToAnchor:self.fileBackView.leadingAnchor constant:10],
        [self.fileIconImageView.centerYAnchor constraintEqualToAnchor:self.fileBackView.centerYAnchor constant:0],
        [self.fileIconImageView.widthAnchor constraintEqualToConstant:48],
        [self.fileIconImageView.heightAnchor constraintEqualToConstant:48],

        [self.stateView.centerXAnchor constraintEqualToAnchor:self.fileIconImageView.centerXAnchor constant:0],
        [self.stateView.centerYAnchor constraintEqualToAnchor:self.fileIconImageView.centerYAnchor constant:0],
        [self.stateView.widthAnchor constraintEqualToConstant:32],
        [self.stateView.heightAnchor constraintEqualToConstant:32],

        // 文件名
        [self.fileNameLabel.leadingAnchor constraintEqualToAnchor:self.fileIconImageView.trailingAnchor constant:12],
        [self.fileNameLabel.topAnchor constraintEqualToAnchor:self.fileIconImageView.topAnchor constant:2],
        [self.fileNameLabel.trailingAnchor constraintEqualToAnchor:self.moreButton.leadingAnchor constant:-12],

        // 文件大小
        [self.fileSizeLabel.leadingAnchor constraintEqualToAnchor:self.fileNameLabel.leadingAnchor],
        [self.fileSizeLabel.bottomAnchor constraintEqualToAnchor:self.fileIconImageView.bottomAnchor constant:-2],
        [self.fileSizeLabel.trailingAnchor constraintEqualToAnchor:self.fileNameLabel.trailingAnchor],

        // 更多按钮
        [self.moreButton.trailingAnchor constraintEqualToAnchor:self.fileBackView.trailingAnchor constant:-8],
        [self.moreButton.centerYAnchor constraintEqualToAnchor:self.fileIconImageView.centerYAnchor],
        [self.moreButton.widthAnchor constraintEqualToConstant:24],
        [self.moreButton.heightAnchor constraintEqualToConstant:24],

        [self.lineBottom.leadingAnchor constraintEqualToAnchor:self.fileBackView.leadingAnchor constant:0],
        [self.lineBottom.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:0],
        [self.lineBottom.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0],
        [self.lineBottom.heightAnchor constraintEqualToConstant:1],
    ]];
}

- (void)configureWithModel:(MessageFileModel *)model {
    if (!model.message) return;
    V2NIMMessageFileAttachment *attachment = (V2NIMMessageFileAttachment *)model.message.attachment;
    if (!attachment) return;

    self.currentModel = model;
    self.currentModel.cell = self;

    self.nameLabel.text = model.fullName;
    [self.avatarImageView configHeadData:model.avatar
                                   name:model.shortName ?: @""
                                    uid:[ChatMessageHelper getSenderId:model.message] ?: @""];

    self.timeLabel.text = [self formatMessageTime:(uint64_t)model.message.createTime];
    self.fileNameLabel.text = attachment.name;
    self.fileSizeLabel.text = [self formatFileSize:attachment.size];
    self.fileIconImageView.image = [self getFileIconForAttachment:attachment];
}

- (NSString *)formatMessageTime:(uint64_t)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"M月d日";
    return [formatter stringFromDate:date];
}

- (NSString *)formatFileSize:(NSUInteger)bytes {
    double size_B = (double)bytes;
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
    return size_str;
}

- (nullable UIImage *)getFileIconForAttachment:(V2NIMMessageFileAttachment *)fileObject {
    NSString *imageName = @"file_unknown";
    NSString *suffix = [((NSString *)fileObject.name).pathExtension lowercaseString];
    if (suffix.length == 0 && fileObject.ext.length > 1) {
        suffix = [[fileObject.ext substringFromIndex:1] lowercaseString];
    }

    if ([file_doc_support() containsObject:suffix]) {
        imageName = @"file_doc";
    } else if ([file_xls_support() containsObject:suffix]) {
        imageName = @"file_xls";
    } else if ([file_img_support() containsObject:suffix]) {
        imageName = @"file_img";
    } else if ([file_ppt_support() containsObject:suffix]) {
        imageName = @"file_ppt";
    } else if ([file_txt_support() containsObject:suffix]) {
        imageName = @"file_txt";
    } else if ([file_audio_support() containsObject:suffix]) {
        imageName = @"file_audio";
    } else if ([file_video_support() containsObject:suffix]) {
        imageName = @"file_vedio";
    } else if ([file_zip_support() containsObject:suffix]) {
        imageName = @"file_zip";
    } else if ([file_pdf_support() containsObject:suffix]) {
        imageName = @"file_pdf";
    } else if ([file_html_support() containsObject:suffix]) {
        imageName = @"file_html";
    } else if ([suffix isEqualToString:@"key"] || [suffix isEqualToString:@"keynote"]) {
        imageName = @"file_keynote";
    }

    return [UIImage ne_imageNamed:imageName];
}

- (void)uploadProgress:(NSUInteger)progress {
    MessageFileModel *model = self.currentModel;
    if (!model) return;

    if (model.state == DownloadStateSuccess) {
        self.stateView.state = FileStateViewStateFileOpen;
        self.stateView.hidden = YES;
    } else {
        self.stateView.state = FileStateViewStateFileDownload;
        self.stateView.hidden = NO;
        [self.stateView setProgress:(float)model.progress / 100.0f];
    }
}

- (void)moreButtonAction {
    [self.delegate didClickMoreAction:self model:self.currentModel];
}

@end
