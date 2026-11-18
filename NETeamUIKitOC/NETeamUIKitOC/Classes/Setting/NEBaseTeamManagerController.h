// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "TeamManagerViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class SettingCellModel;

@interface NEBaseTeamManagerController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource, TeamManagerViewModelDelegate>

@property (nonatomic, strong, readonly) TeamManagerViewModel *viewModel;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellClassDic;
@property (nonatomic, strong) UITableView *contentTableView;

- (void)reloadSectionData;
- (void)updateEditTeamInfoPermissionToEveryone:(SettingCellModel *)model;
- (void)updateEditTeamInfoPermissionToManager:(SettingCellModel *)model;
- (void)updateInvitePermissionToManager:(SettingCellModel *)model;
- (void)updateInvitePermissionToEveryone:(SettingCellModel *)model;
- (void)didJoinTeamNeedAgreeClick:(SettingCellModel *)model :(BOOL)isOpen;
- (void)didJoinTeamNeedVerificationClick:(SettingCellModel *)model :(BOOL)isOpen;

@end

NS_ASSUME_NONNULL_END
