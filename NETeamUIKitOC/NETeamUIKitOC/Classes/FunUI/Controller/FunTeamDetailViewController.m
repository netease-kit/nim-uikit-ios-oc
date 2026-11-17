// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamDetailViewController.h"
#import "FunTeamUIColor.h"
#import "TeamDetailHeaderView.h"
#import "TeamCenterTextCell.h"
#import "TeamDetailItem.h"

@implementation FunTeamDetailViewController

- (void)initFun {
  self.className = @"FunTeamDetailViewController";
}

- (instancetype)initWithNimTeam:(V2NIMTeam *)nimTeam {
  self = [super initWithNimTeam:nimTeam];
  if (self) {
    [self initFun];
  }
  return self;
}

- (void)commonUI {
  [super commonUI];
  self.tableView.estimatedRowHeight = 66.0;
  [self.headerView setCornerRadius:4.0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamDetailItem *item = self.data[indexPath.section][indexPath.row];
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  if ([cell isKindOfClass:TeamCenterTextCell.class] &&
      ([item.title isEqualToString:commonLocalizable(@"chat")] ||
       [item.title isEqualToString:commonLocalizable(@"join_team")])) {
    ((TeamCenterTextCell *)cell).titleLabel.textColor = UIColor.funTeamDetailTitleTextColor;
  }
  return cell;
}

@end
