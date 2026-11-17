// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"

@class V2NIMTeam;
@class TeamDetailViewModel;
@class TeamDetailHeaderView;
@class TeamDetailItem;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamDetailViewController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, strong, readonly) TeamDetailViewModel *viewModel;
@property (nonatomic, strong) TeamDetailHeaderView *headerView;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) NSMutableArray<NSArray<TeamDetailItem *> *> *data;

- (instancetype)initWithNimTeam:(V2NIMTeam *)nimTeam;
- (instancetype)initWithNim_team:(V2NIMTeam *)nimTeam;
- (void)commonUI;
- (void)loadData;
- (void)toChat;
- (void)joinTeam;

@end

NS_ASSUME_NONNULL_END
