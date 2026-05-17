// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamManagerController.h"
#import "FunTeamManagerListController.h"
#import "SettingSectionModel.h"
#import "FunTeamSettingLabelArrowCell.h"
#import "FunTeamSettingSelectCell.h"
#import "FunTeamSettingSubtitleSwitchCell.h"
#import "FunTeamSettingSwitchCell.h"
#import <NEChatKitOC/TeamInfoModel.h>
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation FunTeamManagerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.cellClassDic[@(SettingCellTypeSettingArrowCell)] = FunTeamSettingLabelArrowCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSwitchCell)] = FunTeamSettingSwitchCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSelectCell)] = FunTeamSettingSelectCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSubtitleSelectCell)] = FunTeamSettingSubtitleSwitchCell.class;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
}

- (void)reloadSectionData {
  for (SettingSectionModel *sectionModel in self.viewModel.sectionData) {
    for (SettingCellModel *cellModel in sectionModel.cellModels) {
      cellModel.cornerType = CornerTypeNone;
      cellModel.rowHeight = cellModel.rowHeight > 70.0 ? 78.0 : 56.0;
    }
  }
}

- (void)didManagerClick {
  FunTeamManagerListController *controller = [[FunTeamManagerListController alloc] init];
  controller.teamId = self.viewModel.teamInfoModel.team.teamId;
  [self.navigationController pushViewController:controller animated:YES];
}

@end
