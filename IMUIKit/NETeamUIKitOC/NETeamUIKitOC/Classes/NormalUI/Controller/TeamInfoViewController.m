// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamInfoViewController.h"
#import "TeamAvatarViewController.h"
#import "TeamIntroduceViewController.h"
#import "TeamNameViewController.h"
#import "TeamArrowSettingCell.h"
#import "TeamSettingHeaderCell.h"
#import "NEBaseTeamSettingCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation TeamInfoViewController

- (instancetype)initWithTeam:(V2NIMTeam *)team {
  self = [super initWithTeam:team];
  if (self) {
    self.registerCellDic[@(SettingCellTypeSettingArrowCell)] = TeamArrowSettingCell.class;
    self.registerCellDic[@(SettingCellTypeSettingHeaderCell)] = TeamSettingHeaderCell.class;
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
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
    TeamAvatarViewController *avatar = [[TeamAvatarViewController alloc] init];
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
    TeamNameViewController *nameController = [[TeamNameViewController alloc] init];
    nameController.team = self.team;
    nameController.title = model.cellName;
    [self.navigationController pushViewController:nameController animated:YES];
  } else if (indexPath.row == 2) {
    TeamIntroduceViewController *intr = [[TeamIntroduceViewController alloc] init];
    intr.team = self.team;
    intr.title = model.cellName;
    [self.navigationController pushViewController:intr animated:YES];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.cellDatas[indexPath.row];
  return model.rowHeight;
}

@end
