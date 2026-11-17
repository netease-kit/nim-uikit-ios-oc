// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "NEBaseTeamMemberCell.h"
#import "TeamManagerListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamManagerListController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource, TeamMemberCellDelegate, TeamManagerListViewModelDelegate>

@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, strong, readonly) TeamManagerListViewModel *viewmodel;
@property (nonatomic, strong) UITableView *contentTableView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellClassDic;

- (void)didAddManagers:(NSArray<NETeamMemberInfoModel *> *)managers;
- (void)didClickRemoveButton:(nullable NETeamMemberInfoModel *)model :(NSInteger)index;
- (NSSet<NSString *> *)getFilters;
- (void)sortAndReloadData;

@end

NS_ASSUME_NONNULL_END
