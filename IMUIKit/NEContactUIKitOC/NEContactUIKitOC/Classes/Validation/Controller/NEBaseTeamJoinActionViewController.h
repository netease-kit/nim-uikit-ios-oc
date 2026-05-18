// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "TeamJoinActionViewModel.h"
#import "NEBaseValidationCell.h"
#import "NEBaseSystemNotificationCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamJoinActionViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource, TeamJoinActionViewModelDelegate, SystemNotificationCellDelegate>

@property (nonatomic, strong, readonly) TeamJoinActionViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

- (void)loadData;
- (void)setupUI;
- (void)tableviewReload;

@end

NS_ASSUME_NONNULL_END
