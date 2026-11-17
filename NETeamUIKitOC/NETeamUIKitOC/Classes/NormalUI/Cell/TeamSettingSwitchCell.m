// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingSwitchCell.h"
#import <NEChatKit/NEConstant.h>

@implementation TeamSettingSwitchCell

- (void)setupUI {
  [super setupUI];
  self.tSwitch.onTintColor = [NEConstant hexRGB:0x337EFF];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.tSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.tSwitch.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
  ]];
}

@end
