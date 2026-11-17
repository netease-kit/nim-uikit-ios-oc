// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "NEBaseTeamMemberCell.h"
#import "TeamMembersViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamMembersController : NETeamBaseViewController <UITableViewDelegate, UITableViewDataSource, TeamMemberCellDelegate, TeamMembersViewModelDelegate>

@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, strong, nullable) NSArray<NETeamMemberInfoModel *> *memberDatas;
@property (nonatomic, copy, nullable) NSString *ownerId;
@property (nonatomic, assign) BOOL isSenior;
@property (nonatomic, strong, readonly) UIView *backView;
@property (nonatomic, strong, readonly) TeamMembersViewModel *viewModel;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *contentTableView;
@property (nonatomic, strong) UIImageView *searchIconImageView;

- (instancetype)initWithTeamId:(nullable NSString *)teamId;
- (void)setupUI;
- (void)addObserver;
- (BOOL)isOwner:(nullable NSString *)userId;
- (UIColor *)memberLoadStatusTintColor;
- (void)textChange;
- (nullable NETeamMemberInfoModel *)getRealModel:(NSInteger)index;
- (void)didClickRemoveButton:(nullable NETeamMemberInfoModel *)model :(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
