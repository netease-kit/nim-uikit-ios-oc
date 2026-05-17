// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NECommonKitOC.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"

@implementation NEBasePinMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentClick)];
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (NEUserHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _headerView.titleLabel.font = [NEConstant defaultTextFont:12];
        _headerView.titleLabel.textColor = UIColor.whiteColor;
        _headerView.layer.cornerRadius = 16;
        _headerView.clipsToBounds = YES;
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _headerView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:12.0];
        _nameLabel.textColor = UIColor.ne_darkText;
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.accessibilityIdentifier = @"id.name";
    }
    return _nameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12.0];
        _timeLabel.textColor = UIColor.ne_greyText;
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.accessibilityIdentifier = @"id.time";
    }
    return _timeLabel;
}

- (void)setupUI {
    self.contentView.backgroundColor = UIColor.clearColor;

    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = UIColor.whiteColor;
    _backView.clipsToBounds = YES;
    _backView.layer.cornerRadius = 8.0;
    [self.contentView addSubview:_backView];

    self.backLeftConstraint = [_backView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20];
    self.backLeftConstraint.active = YES;
    self.backRightConstraint = [_backView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20];
    self.backRightConstraint.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [_backView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [_backView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
    ]];

    [_backView addSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
        [self.headerView.topAnchor constraintEqualToAnchor:_backView.topAnchor constant:16],
        [self.headerView.widthAnchor constraintEqualToConstant:32],
        [self.headerView.heightAnchor constraintEqualToConstant:32],
    ]];

    UIImage *image = [coreLoader() loadImage:@"three_point"];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = image;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_backView addSubview:imageView];

    UIButton *moreButton = [[UIButton alloc] init];
    [moreButton addTarget:self action:@selector(moreClick) forControlEvents:UIControlEventTouchUpInside];
    moreButton.accessibilityIdentifier = @"id.moreAction";
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_backView addSubview:moreButton];
    [NSLayoutConstraint activateConstraints:@[
        [moreButton.rightAnchor constraintEqualToAnchor:_backView.rightAnchor],
        [moreButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [moreButton.widthAnchor constraintEqualToConstant:50],
        [moreButton.heightAnchor constraintEqualToConstant:40],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [imageView.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-20],
    ]];

    [_backView addSubview:self.nameLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:8],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.nameLabel.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-50],
    ]];

    [_backView addSubview:self.timeLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.leftAnchor constraintEqualToAnchor:self.nameLabel.leftAnchor],
        [self.timeLabel.rightAnchor constraintEqualToAnchor:self.nameLabel.rightAnchor],
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
    ]];

    _line = [[UIView alloc] init];
    [_backView addSubview:_line];
    _line.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_line.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
        [_line.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-16],
        [_line.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor constant:12],
        [_line.heightAnchor constraintEqualToConstant:1],
    ]];
    _line.backgroundColor = UIColor.ne_greyLine;
}

- (void)configure:(NEPinMessageModel *)item {
    self.pinModel = item;
    [self.headerView configHeadData:item.chatmodel.avatar
                               name:item.chatmodel.shortName ?: @""
                                uid:[ChatMessageHelper getSenderId:item.chatmodel.message] ?: @""];
    self.nameLabel.text = item.chatmodel.fullName;
    self.timeLabel.text = [ChatMessageHelper ne_stringFromDate:[NSDate dateWithTimeIntervalSince1970:item.message.createTime]];
    self.contentWidth.constant = item.chatmodel.contentSize.width;
    self.contentHeight.constant = item.chatmodel.contentSize.height;
}

- (void)moreClick {
    [self.delegate didClickMore:self.pinModel];
}

- (void)contentClick {
    [self.delegate didClickContent:self.pinModel cell:self];
}

@end
