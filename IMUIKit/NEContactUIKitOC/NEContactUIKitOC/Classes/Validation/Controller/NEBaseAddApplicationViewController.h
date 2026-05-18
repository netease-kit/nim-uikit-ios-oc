// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "AddApplicationViewModel.h"
#import "NEBaseValidationCell.h"
#import "NEBaseSystemNotificationCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAddApplicationViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource, AddApplicationViewModelDelegate, SystemNotificationCellDelegate>

@property (nonatomic, strong, readonly) AddApplicationViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

- (void)loadData;
- (void)setupUI;
- (void)tableviewReload;

@end

NS_ASSUME_NONNULL_END
