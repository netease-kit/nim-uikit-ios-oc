// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamUserCell.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation FunTeamUserCell

- (void)setupUI {
  [super setupUI];
  self.userHeaderView.layer.cornerRadius = 4.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36.0],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36.0],
  ]];
}

@end
