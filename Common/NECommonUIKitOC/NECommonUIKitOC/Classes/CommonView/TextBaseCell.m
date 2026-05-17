// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TextBaseCell.h"
#import "NEUserHeaderView.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@interface TextBaseCell ()

@property (nonatomic, strong, readwrite) NEUserHeaderView *headImageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subTitleLabel;

@end

@implementation TextBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupSubviews];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupSubviews];
  }
  return self;
}

- (void)setupSubviews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  [self.contentView addSubview:self.headImageView];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subTitleLabel];

  [NSLayoutConstraint activateConstraints:@[
    [self.headImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.headImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headImageView.widthAnchor constraintEqualToConstant:36.0],
    [self.headImageView.heightAnchor constraintEqualToConstant:36.0],
  ]];

  self.titleLabelTopAnchor = [self.titleLabel.topAnchor constraintEqualToAnchor:self.headImageView.topAnchor];
  self.titleLabelCenterYAnchor = [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.headImageView.centerYAnchor];
  self.titleLabelCenterYAnchor.active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.headImageView.rightAnchor constant:12.0],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4.0],
  ]];
}

- (NEUserHeaderView *)headImageView {
  if (!_headImageView) {
    _headImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _headImageView.titleLabel.textColor = UIColor.whiteColor;
    _headImageView.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _headImageView.layer.cornerRadius = 18.0;
    _headImageView.clipsToBounds = YES;
  }
  return _headImageView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = UIColor.ne_darkText;
    _titleLabel.font = [UIFont systemFontOfSize:14.0];
    _titleLabel.accessibilityIdentifier = @"id.nickName";
  }
  return _titleLabel;
}

- (UILabel *)subTitleLabel {
  if (!_subTitleLabel) {
    _subTitleLabel = [[UILabel alloc] init];
    _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subTitleLabel.textColor = UIColor.ne_greyText;
    _subTitleLabel.font = [UIFont systemFontOfSize:12.0];
    _subTitleLabel.hidden = YES;
    _subTitleLabel.accessibilityIdentifier = @"id.name";
  }
  return _subTitleLabel;
}

@end
