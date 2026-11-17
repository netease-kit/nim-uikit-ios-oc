// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamArrowSettingCell.h"

@implementation TeamArrowSettingCell

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
  ]];
}

@end
