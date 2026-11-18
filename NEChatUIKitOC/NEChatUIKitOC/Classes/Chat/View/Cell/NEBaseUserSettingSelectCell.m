// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseUserSettingSelectCell.h"


@implementation NEBaseUserSettingSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.textColor = [NEConstant hexRGB:0x999999];
        _subTitleLabel.font = [NEConstant defaultTextFont:14.0];
        _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _subTitleLabel;
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.arrowImageView];
    [self.contentView addSubview:self.subTitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
        [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
        [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6.0],
    ]];
}

- (void)configure:(id)anyModel {
    [super configure:anyModel];
    if ([anyModel isKindOfClass:[UserSettingCellModel class]]) {
        UserSettingCellModel *model = (UserSettingCellModel *)anyModel;
        self.subTitleLabel.text = model.subTitle;
    }
}

@end
