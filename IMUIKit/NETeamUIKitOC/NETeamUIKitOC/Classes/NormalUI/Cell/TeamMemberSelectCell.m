// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberSelectCell.h"
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>

@implementation TeamMemberSelectCell

- (void)setupUI {
  [super setupUI];
  self.headerView.layer.cornerRadius = 18.0;
  self.checkImageView.highlightedImage = [coreLoader() loadImage:@"select"];

  [NSLayoutConstraint activateConstraints:@[
    [self.checkImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.checkImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:18.0],
    [self.checkImageView.widthAnchor constraintEqualToConstant:18.0],
    [self.checkImageView.heightAnchor constraintEqualToConstant:18.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:52.0],
    [self.headerView.widthAnchor constraintEqualToConstant:36.0],
    [self.headerView.heightAnchor constraintEqualToConstant:36.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.nameLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:102.0],
    [self.nameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-18.0],
  ]];
}

@end
