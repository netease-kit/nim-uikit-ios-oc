// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectedListCell.h"

@implementation SelectedListCell

/// 重写设置头像方法
- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  self.userHeaderView.layer.cornerRadius = 21;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:42],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:42],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

/// 重写布局方法
- (void)commonUI {
  [super commonUI];
  self.bottomLineLeftConstraint.constant = 74;
}

@end
