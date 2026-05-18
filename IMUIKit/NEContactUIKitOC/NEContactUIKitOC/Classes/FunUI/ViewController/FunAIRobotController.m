// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotController.h"
#import "AIRobotViewModel.h"
#import "ContactConst.h"
#import "FunAIRobotListCell.h"
#import "FunContactUIColor.h"

@implementation FunAIRobotController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor funContactNavigationBackgroundColor];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  [self.robotTableView registerClass:[FunAIRobotListCell class]
              forCellReuseIdentifier:NSStringFromClass([FunAIRobotListCell class])];
  [self.robotEmptyView setEmptyImageName:@"fun_user_empty"];
}

- (Class)robotCellClass {
  return [FunAIRobotListCell class];
}

- (CGFloat)robotCellHeight {
  return 74.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunAIRobotListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FunAIRobotListCell class])
                                                             forIndexPath:indexPath];
  if (indexPath.row >= 0 && indexPath.row < self.viewModel.datas.count) {
    [cell configure:self.viewModel.datas[indexPath.row]];
    cell.dividerLine.hidden = [self isLastRobot:indexPath.row];
  }
  return cell;
}

@end
