// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamSettingHeaderCell.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>

@implementation FunTeamSettingHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.edgeInset = UIEdgeInsetsZero;
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  self.headerView.layer.cornerRadius = 3.36;
  [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeLeft constant:16.0];
  [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeRight constant:0.0];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.arrowView.centerYAnchor],
    [self.headerView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-44.0],
    [self.headerView.widthAnchor constraintEqualToConstant:42.0],
    [self.headerView.heightAnchor constraintEqualToConstant:42.0],
  ]];
}

@end
