// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamUserCell.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation TeamUserCell

- (void)setupUI {
  [super setupUI];
  self.userHeaderView.layer.cornerRadius = 16.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.userHeaderView.widthAnchor constraintEqualToConstant:32.0],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:32.0],
  ]];
}

@end
