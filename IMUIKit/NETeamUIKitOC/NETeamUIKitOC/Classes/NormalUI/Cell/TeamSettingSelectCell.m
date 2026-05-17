// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingSelectCell.h"

@implementation TeamSettingSelectCell

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
  ]];
}

@end
