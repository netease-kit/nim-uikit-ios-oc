// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTableViewController.h"

@implementation NEBaseTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)setupTable {
  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

#pragma mark - Lazy Getters

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.sectionFooterHeight = 0;
    _tableView.sectionHeaderHeight = 0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
    _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    headerView.backgroundColor = [UIColor clearColor];
    _tableView.tableHeaderView = headerView;
  }
  return _tableView;
}

@end