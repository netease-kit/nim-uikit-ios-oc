// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamSettingSubtitleSwitchCell.h"
#import "FunTeamUIColor.h"
#import <NEChatUIKitOC/ChatCellConstantValue.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

@implementation FunTeamSettingSubtitleSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.edgeInset = UIEdgeInsetsZero;
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeLeft constant:16.0];
  [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeRight constant:0.0];

  self.tSwitch.onTintColor = UIColor.funTeamThemeColor;
  [NSLayoutConstraint activateConstraints:@[
    [self.tSwitch.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12.0],
    [self.tSwitch.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-14.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.tSwitch.leftAnchor constant:-chat_cell_margin],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4.0],
  ]];
}

@end
