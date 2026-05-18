// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NodeViewModel.h"
#import "AppKey.h"
#import <NEChatKitOC/SettingRepo.h>
#import <NETeamUIKitOC/SettingCellModel.h>

@implementation NodeViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _sectionData = [NSMutableArray array];
  }
  return self;
}

- (void)getData {
  [self.sectionData removeAllObjects];
  [self.sectionData addObject:[self getSection]];
}

- (SettingSectionModel *)getSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];

  SettingCellModel *home = [[SettingCellModel alloc] init];
  home.subTitle = NELocalizable(@"domestic_node");
  home.rowHeight = 44.0;
  home.switchOpen = [[SettingRepo shared] getNodeValue];
  [model.cellModels addObject:home];

  SettingCellModel *overseas = [[SettingCellModel alloc] init];
  overseas.subTitle = NELocalizable(@"overseas_node");
  overseas.rowHeight = 44.0;
  overseas.switchOpen = ![[SettingRepo shared] getNodeValue];
  [model.cellModels addObject:overseas];

  [model setCornerType];
  return model;
}

@end
