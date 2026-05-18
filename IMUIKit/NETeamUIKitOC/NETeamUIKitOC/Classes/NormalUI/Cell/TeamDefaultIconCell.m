// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDefaultIconCell.h"

@implementation TeamDefaultIconCell

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectBackView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.selectBackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.selectBackView.widthAnchor constraintEqualToConstant:48.0],
    [self.selectBackView.heightAnchor constraintEqualToConstant:48.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.iconImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.iconImageView.widthAnchor constraintEqualToConstant:32.0],
    [self.iconImageView.heightAnchor constraintEqualToConstant:32.0],
  ]];
}

@end
