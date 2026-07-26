// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamInfoViewModel.h"
#import "TeamConstant.h"
#import "SettingCellModel.h"
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/NEALog.h>

@implementation TeamInfoViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _cellDatas = [NSMutableArray array];
    _teamRepo = [TeamRepo shared];
    [_teamRepo addTeamListener:self];
  }
  return self;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
}

- (void)getData:(V2NIMTeam *)team {
  self.v2Team = team;
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, teamId:%@", NSStringFromSelector(_cmd), team.teamId ?: @"nil"]];

  [self.cellDatas removeAllObjects];

  SettingCellModel *headerCell = [[SettingCellModel alloc] init];
  headerCell.cornerType = CornerTypeTopLeft | CornerTypeTopRight;
  headerCell.type = SettingCellTypeSettingHeaderCell;
  headerCell.headerUrl = team.avatar;
  headerCell.rowHeight = 74.0;

  SettingCellModel *nameCell = [[SettingCellModel alloc] init];
  nameCell.type = SettingCellTypeSettingArrowCell;

  SettingCellModel *intrCell = [[SettingCellModel alloc] init];
  intrCell.type = SettingCellTypeSettingArrowCell;
  intrCell.cornerType = CornerTypeBottomLeft | CornerTypeBottomRight;

  if (team && [team ne_isDisscuss]) {
    headerCell.cellName = NETeamUIKitLocalizable(@"discuss_avatar");
    nameCell.cellName = NETeamUIKitLocalizable(@"discuss_name");
    intrCell.cellName = NETeamUIKitLocalizable(@"discuss_intro");
    [self.cellDatas addObjectsFromArray:@[ headerCell, nameCell ]];
    nameCell.cornerType = CornerTypeBottomLeft | CornerTypeBottomRight;
  } else {
    [self.cellDatas addObjectsFromArray:@[ headerCell, nameCell, intrCell ]];
    headerCell.cellName = NETeamUIKitLocalizable(@"team_header");
    nameCell.cellName = NETeamUIKitLocalizable(@"team_name");
    intrCell.cellName = NETeamUIKitLocalizable(@"team_intr");
  }
}

- (void)onTeamInfoUpdated:(V2NIMTeam *)team {
  if (self.v2Team.teamId.length > 0 && [self.v2Team.teamId isEqualToString:team.teamId]) {
    [self getData:team];
    [self.delegate teamInfoDidUpdate:team];
  }
}

@end
