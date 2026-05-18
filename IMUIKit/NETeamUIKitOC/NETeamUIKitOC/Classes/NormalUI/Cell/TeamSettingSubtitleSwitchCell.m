// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingSubtitleSwitchCell.h"
#import <NEChatUIKitOC/ChatCellConstantValue.h>
#import <NEChatKitOC/NEConstant.h>

@implementation TeamSettingSubtitleSwitchCell

- (void)setupUI {
  [super setupUI];
  self.tSwitch.onTintColor = [NEConstant hexRGB:0x337EFF];

  [NSLayoutConstraint activateConstraints:@[
    [self.tSwitch.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12.0],
    [self.tSwitch.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.tSwitch.leftAnchor constant:-chat_cell_margin],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6.0],
  ]];
}

@end
