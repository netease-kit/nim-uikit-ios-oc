// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotController.h"
#import "AIRobotViewModel.h"
#import "AIRobotListCell.h"

@implementation AIRobotController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
  [self.robotTableView registerClass:[AIRobotListCell class]
              forCellReuseIdentifier:NSStringFromClass([AIRobotListCell class])];
}

- (Class)robotCellClass {
  return [AIRobotListCell class];
}

- (CGFloat)robotCellHeight {
  return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  AIRobotListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AIRobotListCell class])
                                                          forIndexPath:indexPath];
  if (indexPath.row >= 0 && indexPath.row < self.viewModel.datas.count) {
    [cell configure:self.viewModel.datas[indexPath.row]];
    cell.dividerLine.hidden = [self isLastRobot:indexPath.row];
  }
  return cell;
}

@end
