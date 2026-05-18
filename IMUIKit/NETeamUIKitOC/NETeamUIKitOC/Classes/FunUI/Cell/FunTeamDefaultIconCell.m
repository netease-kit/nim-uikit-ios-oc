// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamDefaultIconCell.h"

@implementation FunTeamDefaultIconCell

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectBackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.selectBackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.selectBackView.widthAnchor constraintEqualToConstant:56.0],
    [self.selectBackView.heightAnchor constraintEqualToConstant:56.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.iconImageView.centerXAnchor constraintEqualToAnchor:self.selectBackView.centerXAnchor],
    [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.iconImageView.widthAnchor constraintEqualToConstant:40.0],
    [self.iconImageView.heightAnchor constraintEqualToConstant:40.0],
  ]];
}

@end
