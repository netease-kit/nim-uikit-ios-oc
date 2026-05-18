// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"

@class AIRobotViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAIRobotController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) AIRobotViewModel *viewModel;
@property(nonatomic, strong) UITableView *robotTableView;
@property(nonatomic, strong) NEEmptyDataView *robotEmptyView;
@property(nonatomic, strong, nullable) NSLayoutConstraint *robotTableViewTopAnchor;

- (Class)robotCellClass;
- (CGFloat)robotCellHeight;
- (void)didTapCreateRobot;
- (void)setupRobotListUI;
- (BOOL)isLastRobot:(NSInteger)index;
- (void)refreshTableView;

@end

NS_ASSUME_NONNULL_END
