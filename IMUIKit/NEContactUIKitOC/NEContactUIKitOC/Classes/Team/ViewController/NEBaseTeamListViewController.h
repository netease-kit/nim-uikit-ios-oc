// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "TeamListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamListViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) BOOL isClickCallBack;
@property (nonatomic, strong) TeamListViewModel *viewModel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property (nonatomic, strong) UITableView *tableView;

- (void)initNav;
- (void)commonUI;
- (void)loadData;

@end

NS_ASSUME_NONNULL_END
