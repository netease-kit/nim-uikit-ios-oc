// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSelectedCell.h"

@implementation FunSelectedCell

/// 重写布局方法
- (void)setupUI {
  [super setupUI];
  self.avatarImageView.layer.cornerRadius = 4;
}

@end
