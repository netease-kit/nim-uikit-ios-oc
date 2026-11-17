// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamManagerController.h"
#import "TeamManagerListController.h"
#import "TeamSettingLabelArrowCell.h"
#import "TeamSettingSelectCell.h"
#import "TeamSettingSubtitleSwitchCell.h"
#import "TeamSettingSwitchCell.h"
#import <NEChatKit/TeamInfoModel.h>
#import <NEChatKit/UIColor+NECommon.h>

@implementation TeamManagerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.cellClassDic[@(SettingCellTypeSettingArrowCell)] = TeamSettingLabelArrowCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSwitchCell)] = TeamSettingSwitchCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSelectCell)] = TeamSettingSelectCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSubtitleSelectCell)] = TeamSettingSubtitleSwitchCell.class;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
}

- (void)didManagerClick {
  TeamManagerListController *controller = [[TeamManagerListController alloc] init];
  controller.teamId = self.viewModel.teamInfoModel.team.teamId;
  [self.navigationController pushViewController:controller animated:YES];
}

@end
