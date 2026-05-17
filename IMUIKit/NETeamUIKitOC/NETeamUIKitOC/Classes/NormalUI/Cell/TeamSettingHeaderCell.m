// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingHeaderCell.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>

@implementation TeamSettingHeaderCell

- (void)setupUI {
  [super setupUI];
  self.headerView.layer.cornerRadius = 21.0;

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.arrowView.centerYAnchor],
    [self.headerView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-64.0],
    [self.headerView.widthAnchor constraintEqualToConstant:42.0],
    [self.headerView.heightAnchor constraintEqualToConstant:42.0],
  ]];
}

@end
