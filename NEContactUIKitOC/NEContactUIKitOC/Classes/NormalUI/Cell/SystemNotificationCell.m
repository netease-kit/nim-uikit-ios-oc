// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SystemNotificationCell.h"

@implementation SystemNotificationCell

- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  self.userHeaderView.layer.cornerRadius = 18;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

@end
