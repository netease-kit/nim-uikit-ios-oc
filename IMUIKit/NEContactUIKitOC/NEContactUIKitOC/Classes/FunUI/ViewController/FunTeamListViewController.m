// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamListViewController.h"
#import "FunTeamTableViewCell.h"

@implementation FunTeamListViewController

- (void)commonUI {
  [super commonUI];
  [self.tableView registerClass:[FunTeamTableViewCell class]
         forCellReuseIdentifier:NSStringFromClass([FunTeamTableViewCell class])];
  self.tableView.rowHeight = 72;
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunTeamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FunTeamTableViewCell class])
                                                              forIndexPath:indexPath];
  [cell setModel:self.viewModel.teamList[indexPath.row]];
  return cell;
}

@end
