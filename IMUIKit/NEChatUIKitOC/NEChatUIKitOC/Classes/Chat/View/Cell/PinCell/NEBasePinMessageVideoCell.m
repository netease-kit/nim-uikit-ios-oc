// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageVideoCell.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKitOC.h>
#import <SDWebImage/SDWebImage.h>
#import <NECommonUIKitOC/UIView+NECorner.h>
#import "MessageContentModel.h"

@implementation NEBasePinMessageVideoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
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

- (UILabel *)videoTimeLabel {
    if (!_videoTimeLabel) {
        _videoTimeLabel = [[UILabel alloc] init];
        _videoTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _videoTimeLabel.textColor = UIColor.whiteColor;
        _videoTimeLabel.font = [NEConstant defaultTextFont:10.0];
        _videoTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _videoTimeLabel;
}

- (UIView *)timeView {
    if (!_timeView) {
        _timeView = [[UIView alloc] init];
        _timeView.translatesAutoresizingMaskIntoConstraints = NO;
        [_timeView addSubview:self.videoTimeLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.videoTimeLabel.leftAnchor constraintEqualToAnchor:_timeView.leftAnchor constant:4],
            [self.videoTimeLabel.topAnchor constraintEqualToAnchor:_timeView.topAnchor constant:2],
            [self.videoTimeLabel.rightAnchor constraintEqualToAnchor:_timeView.rightAnchor constant:-4],
            [self.videoTimeLabel.bottomAnchor constraintEqualToAnchor:_timeView.bottomAnchor constant:-2],
        ]];
        _timeView.clipsToBounds = YES;
        _timeView.layer.cornerRadius = 4.0;
        _timeView.backgroundColor = [[NEConstant hexRGB:0x000000] colorWithAlphaComponent:0.6];
    }
    return _timeView;
}

- (void)setupUI {
    [super setupUI];
    [self.contentImageView addSubview:self.stateView];
    [self.contentImageView addCustomCorner:UIRectCornerTopLeft radius:8 backcolor:UIColor.whiteColor];
    [NSLayoutConstraint activateConstraints:@[
        [self.stateView.centerXAnchor constraintEqualToAnchor:self.contentImageView.centerXAnchor],
        [self.stateView.centerYAnchor constraintEqualToAnchor:self.contentImageView.centerYAnchor],
        [self.stateView.heightAnchor constraintEqualToConstant:60],
        [self.stateView.widthAnchor constraintEqualToConstant:60],
    ]];

    [self.contentImageView addSubview:self.timeView];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeView.rightAnchor constraintEqualToAnchor:self.contentImageView.rightAnchor constant:-7],
        [self.timeView.bottomAnchor constraintEqualToAnchor:self.contentImageView.bottomAnchor constant:-7],
    ]];

    self.stateView.userInteractionEnabled = NO;
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    V2NIMMessageVideoAttachment *videoObject = (V2NIMMessageVideoAttachment *)item.chatmodel.message.attachment;
    if (![videoObject isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;

    NSString *videoUrl = videoObject.url ?: @"";
    NSString *thumbUrl = [V2NIMStorageUtil videoCoverUrl:videoUrl offset:0];
    [self.contentImageView sd_setImageWithURL:[NSURL URLWithString:thumbUrl]
                             placeholderImage:nil
                                      options:SDWebImageRetryFailed
                                     progress:nil
                                    completed:nil];

    if (videoObject.duration > 0) {
        self.timeView.hidden = NO;
        self.videoTimeLabel.text = [NSDate ne_getFormatPlayTime:(NSTimeInterval)(videoObject.duration / 1000)];
    } else {
        self.timeView.hidden = YES;
    }
}

@end
