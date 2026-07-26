// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NodeSelectCell.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation NodeSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (void)configureWithModel:(SettingCellModel *)cellModel {
  self.cornerType = cellModel.cornerType;
  self.stateImageView.highlighted = cellModel.switchOpen;
  self.titleLabel.text = cellModel.subTitle;
}

- (void)setupUI {
  [self.contentView addSubview:self.stateImageView];
  [self.contentView addSubview:self.titleLabel];

  [NSLayoutConstraint activateConstraints:@[
    [self.stateImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.stateImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:30.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.stateImageView.rightAnchor constant:10.0],
  ]];
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor ne_darkText];
    _titleLabel.font =
        [UIFont fontWithName:@"PingFangSC-Regular" size:14.0] ?: [UIFont systemFontOfSize:14.0];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _titleLabel;
}

- (UIImageView *)stateImageView {
  if (!_stateImageView) {
    _stateImageView = [[UIImageView alloc] init];
    _stateImageView.image = [UIImage imageNamed:@"unselect"];
    _stateImageView.highlightedImage = [UIImage imageNamed:@"select"];
    _stateImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _stateImageView;
}

@end
