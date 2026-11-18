// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "NEBaseTeamSettingCell.h"
#import "TeamSettingViewModel.h"
#import <NEBaseUIKitOC/ExpandButton.h>

NS_ASSUME_NONNULL_BEGIN

@class TeamDetailHeaderView;
@class SettingCellModel;

@interface NEBaseTeamSettingViewController : NETeamBaseViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, TeamSettingViewModelDelegate>

@property (nonatomic, strong, readonly) TeamSettingViewModel *viewModel;
@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, strong, nullable) NSLayoutConstraint *addButtonWidth;
@property (nonatomic, strong, nullable) NSLayoutConstraint *addButtonLeftMargin;
@property (nonatomic, assign) TeamSettingType teamSettingType;
@property (nonatomic, assign) BOOL isSeniorDiscuss;
@property (nonatomic, assign) BOOL isRequestingData;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellClassDic;
@property (nonatomic, strong) UITableView *contentTableView;
@property (nonatomic, strong) TeamDetailHeaderView *teamHeaderView;
@property (nonatomic, strong) UILabel *memberLabel;
@property (nonatomic, strong) UILabel *memberCountLabel;
@property (nonatomic, strong) UICollectionView *userinfoCollectionView;
@property (nonatomic, strong) ExpandButton *addButton;

- (void)reloadSectionData;
- (void)didRefreshUserinfoCollection;
- (void)setupUI;
- (void)setTeamHeaderInfo;
- (void)requestSettingData:(NSString *)teamId member:(V2NIMTeamMember *)member;
- (void)requestSettingData:(NSString *)teamId :(V2NIMTeamMember *)member;
- (void)resetupUI;
- (UIView *)getHeaderView;
- (nullable UIView *)getFooterView;
- (nullable NSString *)getBottomText;
- (void)setupUserInfoCollection:(UIView *)cornerView;
- (void)addUser;
- (void)removeTeamForMyself;
- (void)leaveDiscuss;
- (void)toInfoView;
- (void)toMemberList;
- (void)didAddUser:(NSArray<NSString *> *)accids teamId:(NSString *)teamId;
- (void)didAddUser:(NSArray<NSString *> *)accids :(NSString *)teamId;
- (void)dismissTeam;
- (void)refreshMemberCount;
- (void)leaveTeam;
- (void)didClickTeamManage;
- (void)checkoutAddShowOrHide;
- (void)updateInviteModeOwnerAction:(SettingCellModel *)model;
- (void)updateInviteModeAllAction:(SettingCellModel *)model;
- (void)didClickChangeNick;
- (NSArray<NETeamMemberInfoModel *> *)getManagerUsers;

@end

NS_ASSUME_NONNULL_END
