// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "BlackListViewModel.h"
#import "NEBaseBlackListCell.h"

@class NEBaseContactSelectedViewController;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseBlackListViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource, BlackListCellDelegate, BlackListViewModelDelegate>

@property (nonatomic, strong) BlackListViewModel *viewModel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property (nonatomic, strong) UIView *headView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UITableView *tableView;

- (void)initNav;
- (void)commonUI;
- (void)loadData;
- (NEBaseContactSelectedViewController *)getContactSelectVC;
- (void)addBlackUsersWithUsers:(NSArray<NEUserWithFriend *> *)users;

@end

NS_ASSUME_NONNULL_END
