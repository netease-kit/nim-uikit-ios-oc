// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunRecentSelectCell.h"
#import "MultiSelectModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunRecentSelectCell

/// 重写布局方法
- (void)setupUI {
  self.avatarImageView.layer.cornerRadius = 4;
  [self.contentView addSubview:self.avatarImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:56],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:56],
  ]];

  self.titleLabel.font = [UIFont systemFontOfSize:12];
  self.titleLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:8],
    [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.avatarImageView.centerXAnchor],
    [self.titleLabel.widthAnchor constraintEqualToConstant:64],
    [self.titleLabel.heightAnchor constraintEqualToConstant:16],
  ]];

  [self.contentView addSubview:self.selectImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectImageView.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor constant:4],
    [self.selectImageView.rightAnchor constraintEqualToAnchor:self.avatarImageView.rightAnchor constant:-4],
    [self.selectImageView.widthAnchor constraintEqualToConstant:18],
    [self.selectImageView.heightAnchor constraintEqualToConstant:18],
  ]];
}

/// 重写控件赋值方法
- (void)configure:(id)model {
  if (![model isKindOfClass:[MultiSelectModel class]]) return;
  MultiSelectModel *selectModel = (MultiSelectModel *)model;

  [super configure:selectModel];
  self.selectImageView.image = selectModel.isSelected ? [coreLoader() loadImage:@"fun_select"] : [coreLoader() loadImage:@"fun_unselect"];
}

@end
