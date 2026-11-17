// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "NEChatBaseViewController.h"
#import "UserSettingViewModel.h"
#import "NEBaseUserSettingCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseUserSettingViewController : NEChatBaseViewController
    <UITableViewDataSource, UITableViewDelegate, UserSettingViewModelDelegate>

@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, assign) BOOL fromBotSubSession;
@property (nonatomic, strong, nullable) V2NIMTopic *botSubSessionTopic;
@property (nonatomic, strong) UserSettingViewModel *viewModel;
@property (nonatomic, strong) NEUserHeaderView *userHeaderView;
@property (nonatomic, strong) ExpandButton *addButton;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentTableTopAnchor;
@property (nonatomic, strong) UITableView *contentTable;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellClassDic;

- (instancetype)initWithUserId:(NSString *)userId;
- (void)setupUI;
- (void)didLoadData;
- (UIView *)headerView;
- (BOOL)shouldShowAddMemberButton;
- (NSArray<UIViewController *> *)filterStackViewController;
- (void)createDiscuss;
- (void)showUserInfo;

@end

NS_ASSUME_NONNULL_END
