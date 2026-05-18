// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamListViewController.h"
#import "TeamTableViewCell.h"

@implementation TeamListViewController

- (void)commonUI {
  [super commonUI];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
  [self.tableView registerClass:[TeamTableViewCell class]
         forCellReuseIdentifier:NSStringFromClass([TeamTableViewCell class])];
  self.tableView.rowHeight = 62;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TeamTableViewCell class])
                                                            forIndexPath:indexPath];
  [cell setModel:self.viewModel.teamList[indexPath.row]];
  return cell;
}

@end
