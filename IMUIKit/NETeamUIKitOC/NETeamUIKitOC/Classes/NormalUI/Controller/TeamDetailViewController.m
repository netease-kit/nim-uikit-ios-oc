// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDetailViewController.h"
#import "TeamDetailHeaderView.h"

@implementation TeamDetailViewController

- (instancetype)initWithNimTeam:(V2NIMTeam *)nimTeam {
  self = [super initWithNimTeam:nimTeam];
  if (self) {
    self.className = @"TeamDetailViewController";
  }
  return self;
}

- (void)commonUI {
  [super commonUI];
  self.tableView.estimatedRowHeight = 66.0;
  [self.headerView setCornerRadius:30.0];
}

@end
