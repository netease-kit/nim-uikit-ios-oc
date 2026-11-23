// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

#import "ContactViewModel.h"
#import <NEChatKit/NEChatKit.h>

@class NEBaseContactTableViewCell;
@class NEBaseFindFriendViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol NEBaseContactViewControllerDelegate <NSObject>
@optional
- (void)onDataLoaded;
@end

/// 通讯录页面 - 基类
@interface NEBaseContactViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, TabNavigationViewDelegate, ContactViewModelDelegate, NEIMKitClientListener>

@property (nonatomic, weak, nullable) id<NEBaseContactViewControllerDelegate> delegate;

/// custom ui cell
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *cellRegisterDic;

@property (nonatomic, strong, nullable) ContactViewModel *viewModel;

@property (nonatomic, strong, nullable) UIColor *listSelectionBackgroundColor;

@property (nonatomic, assign) CGFloat bodyTopViewHeight;
@property (nonatomic, assign) CGFloat bodyBottomViewHeight;
@property (nonatomic, assign) CGFloat topConstant;

@property (nonatomic, strong) TabNavigationView *navigationView;
@property (nonatomic, strong) UIView *bodyTopView;
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NEEmptyDataView *emptyView;
@property (nonatomic, strong) UIView *bodyBottomView;

/// 右列回到空白占位时宿主调用：清掉「上一次点过的行」，避免再次高亮过期选中项。
/// 只在宿主明确关闭左列高亮（右列已无内容）时调用；列表自身刷新仍按 key 恢复选中。
- (void)clearAdaptiveSelection;

- (void)showTitleBar;
- (void)commonUI;
- (void)loadData;
- (void)didRefreshTable;
- (void)clearValidationUnreadCount;
- (void)reloadTableView;
- (void)subscribeVisibleRows;

// extension methods
- (void)initSystemNav;
- (NEBaseFindFriendViewController *)getFindFriendViewController;
- (void)goToFindFriend;
- (void)searchContact;

// TabNavigationViewDelegate
- (void)searchAction;
- (void)didClickAddBtn;

// NEIMKitClientListener
- (void)onConnectStatus:(V2NIMConnectStatus)status;

@end

NS_ASSUME_NONNULL_END
