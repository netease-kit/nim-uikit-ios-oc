// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingSubtitleCell.h"
#import <NEChatKitOC/NEConstant.h>

@implementation TeamSettingSubtitleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subTitleLabel];
  [self.contentView addSubview:self.arrowView];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
  self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
  self.titleWidthAnchor.active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
    [self.arrowView.widthAnchor constraintEqualToConstant:7.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor constant:10.0],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-10.0],
    [self.subTitleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if ([anyModel isKindOfClass:[SettingCellModel class]]) {
    SettingCellModel *model = (SettingCellModel *)anyModel;
    self.titleWidthAnchor.constant = model.titleWidth;
    self.subTitleLabel.text = model.subTitle;
  }
}

- (UILabel *)subTitleLabel {
  if (!_subTitleLabel) {
    _subTitleLabel = [[UILabel alloc] init];
    _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subTitleLabel.textColor = [NEConstant hexRGB:0xA6ADB6];
    _subTitleLabel.font = [NEConstant defaultTextFont:12.0];
    _subTitleLabel.textAlignment = NSTextAlignmentRight;
    _subTitleLabel.accessibilityIdentifier = @"id.subTitleLabel";
  }
  return _subTitleLabel;
}

@end
