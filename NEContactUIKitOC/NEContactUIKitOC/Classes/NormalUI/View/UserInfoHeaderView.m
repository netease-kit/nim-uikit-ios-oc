// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserInfoHeaderView.h"

@implementation UserInfoHeaderView

- (void)commonUI {
  [super commonUI];
  self.userHeaderView.layer.cornerRadius = 30;

  [NSLayoutConstraint activateConstraints:@[
    [self.lineView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.lineView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.lineView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.lineView.heightAnchor constraintEqualToConstant:6],
  ]];
}

@end
