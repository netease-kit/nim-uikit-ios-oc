// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageVideoCell.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <SDWebImage/SDWebImage.h>
#import <NEChatKitOC/NECommonKitOC.h>
#import "MessageContentModel.h"
#import <NEChatKitOC/NSDate+NECommon.h>

@implementation NEBaseCollectionMessageVideoCell

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

- (VideoStateView *)collectionStateView {
    if (!_collectionStateView) {
        _collectionStateView = [[VideoStateView alloc] init];
        _collectionStateView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionStateView.backgroundColor = UIColor.clearColor;
    }
    return _collectionStateView;
}

- (UILabel *)collectionVideoTimeLabel {
    if (!_collectionVideoTimeLabel) {
        _collectionVideoTimeLabel = [[UILabel alloc] init];
        _collectionVideoTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionVideoTimeLabel.textColor = UIColor.whiteColor;
        _collectionVideoTimeLabel.font = [NEConstant defaultTextFont:10.0];
        _collectionVideoTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _collectionVideoTimeLabel;
}

- (UIView *)collectionTimeView {
    if (!_collectionTimeView) {
        _collectionTimeView = [[UIView alloc] init];
        _collectionTimeView.translatesAutoresizingMaskIntoConstraints = NO;
        [_collectionTimeView addSubview:self.collectionVideoTimeLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.collectionVideoTimeLabel.leftAnchor constraintEqualToAnchor:_collectionTimeView.leftAnchor constant:4],
            [self.collectionVideoTimeLabel.topAnchor constraintEqualToAnchor:_collectionTimeView.topAnchor constant:2],
            [self.collectionVideoTimeLabel.rightAnchor constraintEqualToAnchor:_collectionTimeView.rightAnchor constant:-4],
            [self.collectionVideoTimeLabel.bottomAnchor constraintEqualToAnchor:_collectionTimeView.bottomAnchor constant:-2],
        ]];
        _collectionTimeView.clipsToBounds = YES;
        _collectionTimeView.layer.cornerRadius = 4.0;
        _collectionTimeView.backgroundColor = [[NEConstant hexRGB:0x000000] colorWithAlphaComponent:0.6];
    }
    return _collectionTimeView;
}

- (void)setupCommonUI {
    [super setupCommonUI];
    [self.collectionContentImageView addSubview:self.collectionStateView];
    [self.collectionContentImageView addCustomCorner:UIRectCornerTopLeft radius:8 backcolor:UIColor.whiteColor];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionStateView.centerXAnchor constraintEqualToAnchor:self.collectionContentImageView.centerXAnchor],
        [self.collectionStateView.centerYAnchor constraintEqualToAnchor:self.collectionContentImageView.centerYAnchor],
        [self.collectionStateView.heightAnchor constraintEqualToConstant:60],
        [self.collectionStateView.widthAnchor constraintEqualToConstant:60],
    ]];

    [self.collectionContentImageView addSubview:self.collectionTimeView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionTimeView.rightAnchor constraintEqualToAnchor:self.collectionContentImageView.rightAnchor constant:-7],
        [self.collectionTimeView.bottomAnchor constraintEqualToAnchor:self.collectionContentImageView.bottomAnchor constant:-7],
    ]];

    self.collectionStateView.userInteractionEnabled = NO;
}

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    V2NIMMessageVideoAttachment *videoObject = (V2NIMMessageVideoAttachment *)model.chatmodel.message.attachment;
    if (![videoObject isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;

    NSString *videoUrl = videoObject.url ?: @"";
    NSString *thumbUrl = [V2NIMStorageUtil videoCoverUrl:videoUrl offset:0];
    [self.collectionContentImageView sd_setImageWithURL:[NSURL URLWithString:thumbUrl]
                                      placeholderImage:nil
                                               options:SDWebImageRetryFailed
                                              progress:nil
                                             completed:nil];

    if (videoObject.duration > 0) {
        self.collectionTimeView.hidden = NO;
        self.collectionVideoTimeLabel.text = [NSDate ne_getFormatPlayTime:(NSTimeInterval)(videoObject.duration / 1000)];
    } else {
        self.collectionTimeView.hidden = YES;
    }
}

@end
