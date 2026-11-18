// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageLocationCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKit.h>
#import <SDWebImage/SDWebImage.h>
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"
#import "MessageContentModel.h"
#import "MessageLocationModel.h"

@interface NEBasePinMessageLocationCell ()
@property (nonatomic, strong) UILabel *locationTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *pointImageView;
@end

@implementation NEBasePinMessageLocationCell

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

- (UILabel *)locationTitleLabel {
    if (!_locationTitleLabel) {
        _locationTitleLabel = [[UILabel alloc] init];
        _locationTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _locationTitleLabel.textColor = UIColor.ne_darkText;
        _locationTitleLabel.font = [UIFont systemFontOfSize:16.0];
    }
    return _locationTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subTitleLabel.textColor = UIColor.ne_lightText;
        _subTitleLabel.font = [UIFont systemFontOfSize:12.0];
    }
    return _subTitleLabel;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _emptyLabel.font = [UIFont systemFontOfSize:16];
        _emptyLabel.text = chatLocalizable(@"no_map_plugin");
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.textColor = UIColor.ne_greyText;
        _emptyLabel.hidden = YES;
    }
    return _emptyLabel;
}

- (UIImageView *)mapImageView {
    if (!_mapImageView) {
        _mapImageView = [[UIImageView alloc] init];
        _mapImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _mapImageView;
}

- (UIImageView *)pointImageView {
    if (!_pointImageView) {
        _pointImageView = [[UIImageView alloc] init];
        _pointImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _pointImageView.image = chatLoadImage(@"location_point");
    }
    return _pointImageView;
}

- (void)setupUI {
    [super setupUI];

    UIView *contentBackView = [[UIView alloc] init];
    contentBackView.backgroundColor = UIColor.whiteColor;
    contentBackView.translatesAutoresizingMaskIntoConstraints = NO;
    contentBackView.clipsToBounds = YES;
    contentBackView.layer.cornerRadius = 4;
    contentBackView.layer.borderWidth = 1;
    contentBackView.layer.borderColor = UIColor.ne_outlineColor.CGColor;

    [self.backView addSubview:contentBackView];
    self.contentWidth = [contentBackView.widthAnchor constraintEqualToConstant:chat_content_maxW()];
    self.contentHeight = [contentBackView.heightAnchor constraintEqualToConstant:chat_content_maxW()];
    [NSLayoutConstraint activateConstraints:@[
        self.contentWidth,
        self.contentHeight,
        [contentBackView.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor],
        [contentBackView.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
    ]];

    [contentBackView addSubview:self.locationTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.locationTitleLabel.leftAnchor constraintEqualToAnchor:contentBackView.leftAnchor constant:16],
        [self.locationTitleLabel.rightAnchor constraintEqualToAnchor:contentBackView.rightAnchor constant:-16],
        [self.locationTitleLabel.topAnchor constraintEqualToAnchor:contentBackView.topAnchor constant:10],
    ]];

    [contentBackView addSubview:self.subTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.locationTitleLabel.leftAnchor],
        [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.locationTitleLabel.rightAnchor],
        [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.locationTitleLabel.bottomAnchor constant:4],
    ]];

    [contentBackView addSubview:self.mapImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapImageView.leftAnchor constraintEqualToAnchor:contentBackView.leftAnchor],
        [self.mapImageView.bottomAnchor constraintEqualToAnchor:contentBackView.bottomAnchor],
        [self.mapImageView.rightAnchor constraintEqualToAnchor:contentBackView.rightAnchor],
        [self.mapImageView.topAnchor constraintEqualToAnchor:self.subTitleLabel.bottomAnchor constant:4],
    ]];

    [self.mapImageView addSubview:self.pointImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.pointImageView.centerXAnchor constraintEqualToAnchor:self.mapImageView.centerXAnchor],
        [self.pointImageView.bottomAnchor constraintEqualToAnchor:self.mapImageView.bottomAnchor constant:-30],
    ]];

    [contentBackView addSubview:self.emptyLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.leftAnchor constraintEqualToAnchor:contentBackView.leftAnchor],
        [self.emptyLabel.rightAnchor constraintEqualToAnchor:contentBackView.rightAnchor],
        [self.emptyLabel.bottomAnchor constraintEqualToAnchor:contentBackView.bottomAnchor constant:-40],
    ]];

    if (self.contentGesture) {
        [contentBackView addGestureRecognizer:self.contentGesture];
    }
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    if ([item.chatmodel isKindOfClass:[MessageLocationModel class]]) {
        MessageLocationModel *m = (MessageLocationModel *)item.chatmodel;
        self.locationTitleLabel.text = m.title;
        self.subTitleLabel.text = m.subTitle;
        if (m.lat && m.lng) {
            NSString *url = [NEChatKitClient.instance.delegate getMapImageUrl:m.lat.doubleValue lng:m.lng.doubleValue];
            if (url) {
                [self.mapImageView sd_setImageWithURL:[NSURL URLWithString:url]
                                    placeholderImage:[UIImage ne_imageNamed:@"map_placeholder_image"]
                                             options:SDWebImageRetryFailed];
                self.emptyLabel.hidden = YES;
                self.pointImageView.hidden = NO;
            } else {
                self.mapImageView.image = [UIImage ne_imageNamed:@"map_placeholder_image"];
                self.emptyLabel.hidden = NO;
                self.pointImageView.hidden = YES;
            }
        }
    }
}

@end
