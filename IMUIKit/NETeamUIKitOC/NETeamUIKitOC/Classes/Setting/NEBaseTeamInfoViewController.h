// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "TeamInfoViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class NEBaseTeamSettingCell;

@interface NEBaseTeamInfoViewController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource, NETeamInfoDelegate>

@property (nonatomic, strong, readonly) TeamInfoViewModel *viewModel;
@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *registerCellDic;
@property (nonatomic, strong, readonly) UITableView *contentTableView;

- (instancetype)initWithTeam:(nullable V2NIMTeam *)team;
- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
