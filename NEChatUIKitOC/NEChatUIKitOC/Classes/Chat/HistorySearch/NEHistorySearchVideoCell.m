// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistorySearchVideoCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageVideoModel.h"
#import <NEBaseUIKitOC/VideoStateView.h>
#import <NEChatKit/NSDate+NECommon.h>

@interface NEHistorySearchVideoCell ()
@property(nonatomic, weak) MessageVideoModel *currentModel;
@property(nonatomic, strong) VideoStateView *stateView;
@end

@implementation NEHistorySearchVideoCell

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
    }
    return self;
}

- (VideoStateView *)stateView {
    if (!_stateView) {
        _stateView = [[VideoStateView alloc] init];
        _stateView.translatesAutoresizingMaskIntoConstraints = NO;
        _stateView.backgroundColor = UIColor.clearColor;
    }
    return _stateView;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.image = [UIImage ne_imageNamed:@"history_search_video"];
    }
    return _iconImageView;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.textColor = UIColor.whiteColor;
        _timeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _timeLabel;
}

- (void)setupUI {
    [super setupUI];

    [self.contentView addSubview:self.stateView];
    self.stateView.hidden = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.stateView.centerXAnchor constraintEqualToAnchor:self.imageView.centerXAnchor],
        [self.stateView.centerYAnchor constraintEqualToAnchor:self.imageView.centerYAnchor],
        [self.stateView.heightAnchor constraintEqualToConstant:60],
        [self.stateView.widthAnchor constraintEqualToConstant:60],
    ]];

    [self.contentView addSubview:self.iconImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:4],
        [self.iconImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.iconImageView.widthAnchor constraintEqualToConstant:24],
        [self.iconImageView.heightAnchor constraintEqualToConstant:24],
    ]];

    [self.contentView addSubview:self.timeLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.iconImageView.centerYAnchor],
        [self.timeLabel.leftAnchor constraintEqualToAnchor:self.iconImageView.rightAnchor constant:4],
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.currentModel = nil;
}

- (void)configureWithModel:(id)model {
    if (![model isKindOfClass:[MessageVideoModel class]]) {
        return;
    }
    MessageVideoModel *videoModel = (MessageVideoModel *)model;
    V2NIMMessageVideoAttachment *videoObject = (V2NIMMessageVideoAttachment *)videoModel.message.attachment;
    if (!videoObject) {
        return;
    }

    self.currentModel = videoModel;
    self.currentModel.historyVideoCell = self;

    NSString *videoUrl = videoObject.url ?: @"";
    NSString *thumbUrl = [V2NIMStorageUtil videoCoverUrl:videoUrl offset:0];
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:thumbUrl]
                      placeholderImage:nil
                               options:SDWebImageRetryFailed
                              progress:nil
                             completed:nil];

    if (videoObject.duration > 0) {
        self.timeLabel.hidden = NO;
        self.timeLabel.text = [NSDate ne_getFormatPlayTime:videoObject.duration / 1000.0];
    } else {
        self.timeLabel.hidden = YES;
    }
}

- (void)uploadProgress:(NSUInteger)progress {
    MessageVideoModel *model = self.currentModel;
    if (!model) return;

    if (model.state == DownloadStateSuccess) {
        self.stateView.state = VideoStateViewStateVideoPlay;
        self.stateView.hidden = YES;
    } else {
        self.stateView.state = VideoStateViewStateVideoDownload;
        self.stateView.hidden = NO;
        [self.stateView setProgress:(float)model.progress / 100.0f];
    }
}

@end
