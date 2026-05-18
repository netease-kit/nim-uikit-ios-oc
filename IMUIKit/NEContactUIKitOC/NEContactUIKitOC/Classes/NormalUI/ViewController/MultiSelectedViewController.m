// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiSelectedViewController.h"
#import "SelectedListCell.h"
#import <NECommonUIKitOC/CommonUIConfig.h>

@implementation MultiSelectedViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.cancelButton setTitle:nil forState:UIControlStateNormal];
  [self.cancelButton setImage:[CommonUIConfig shared].backArrowImage forState:UIControlStateNormal];
  self.tableView.rowHeight = 62.0;
  [self.tableView registerClass:[SelectedListCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseSelectedListCell class])];
}

@end
