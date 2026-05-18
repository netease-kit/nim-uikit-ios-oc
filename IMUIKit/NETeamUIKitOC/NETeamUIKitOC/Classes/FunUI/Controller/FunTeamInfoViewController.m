// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamInfoViewController.h"
#import "FunTeamAvatarViewController.h"
#import "FunTeamIntroduceViewController.h"
#import "FunTeamNameViewController.h"
#import "FunTeamArrowSettingCell.h"
#import "FunTeamSettingHeaderCell.h"
#import "FunTeamUIColor.h"
#import "NEBaseTeamSettingCell.h"

@implementation FunTeamInfoViewController

- (instancetype)initWithTeam:(V2NIMTeam *)team {
  self = [super initWithTeam:team];
  if (self) {
    self.registerCellDic[@(SettingCellTypeSettingArrowCell)] = FunTeamArrowSettingCell.class;
    self.registerCellDic[@(SettingCellTypeSettingHeaderCell)] = FunTeamSettingHeaderCell.class;
    self.view.backgroundColor = UIColor.funTeamBackgroundColor;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  for (SettingCellModel *cellModel in self.viewModel.cellDatas) {
    cellModel.cornerType = CornerTypeNone;
    if (cellModel.type == SettingCellTypeSettingArrowCell) {
      cellModel.rowHeight = 56.0;
    }
  }
}

- (void)setupUI {
  [super setupUI];
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.titleBarBottomLine.hidden = NO;
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.cellDatas[indexPath.row];
  NEBaseTeamSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                                                forIndexPath:indexPath];
  [cell configure:model];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.cellDatas[indexPath.row];
  if (indexPath.row == 0) {
    FunTeamAvatarViewController *avatar = [[FunTeamAvatarViewController alloc] init];
    avatar.team = self.team;
    __weak typeof(self) weakSelf = self;
    avatar.block = ^{
      if (weakSelf.team) {
        [weakSelf.viewModel getData:weakSelf.team];
        [weakSelf.contentTableView reloadData];
      }
    };
    [self.navigationController pushViewController:avatar animated:YES];
  } else if (indexPath.row == 1) {
    FunTeamNameViewController *nameController = [[FunTeamNameViewController alloc] init];
    nameController.team = self.team;
    nameController.title = model.cellName;
    [self.navigationController pushViewController:nameController animated:YES];
  } else if (indexPath.row == 2) {
    FunTeamIntroduceViewController *intr = [[FunTeamIntroduceViewController alloc] init];
    intr.team = self.team;
    intr.title = model.cellName;
    [self.navigationController pushViewController:intr animated:YES];
  }
}

@end
