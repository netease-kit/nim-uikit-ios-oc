// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamTableViewCell.h"

@implementation TeamTableViewCell

- (void)commonUI {
  [super commonUI];
  self.userHeaderView.layer.cornerRadius = 21;

  self.titleLabel.font = [UIFont systemFontOfSize:16];
  self.titleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
}

@end
