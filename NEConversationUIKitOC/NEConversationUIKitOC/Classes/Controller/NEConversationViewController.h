// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEConversationViewController.h
// 统一会话列表页面 — 对齐 Swift NEBaseConversationController
// 通过 NEConversationDataSourceType 切换 Cloud / Local 模式

#import <UIKit/UIKit.h>
#import "NEConversationDataSource.h"

@class ConversationViewModel;
@class NEConversationListModel;
@class TabNavigationView;
@class NEEmptyDataView;
@class NEBrokenNetworkView;
@class NEBaseScanQRViewController;
@class FunSearchView;
@class NEBasePopListView;
@class PopListItem;
@class ConversationGroupViewModel;
@class V2NIMConversation;

NS_ASSUME_NONNULL_BEGIN

/// ViewController 数据加载回调
@protocol NEBaseConversationControllerDelegate <NSObject>
@optional
- (void)onDataLoaded;
@end

/// 旧版 OC 名称兼容协议。
@protocol NEConversationViewControllerDelegate <NEBaseConversationControllerDelegate>
@end

@interface NEBaseConversationController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

/// 会话 ViewModel
@property (nonatomic, strong, readonly) ConversationViewModel *viewModel;
@property (nonatomic, strong, readonly) ConversationGroupViewModel *conversationGroupViewModel;

@property (nonatomic, copy, nullable) BOOL (^onOpenConversation)(NSString *route,
                                                                NSDictionary<NSString *, id> *parameters);

/// 左滑删除按钮默认背景色
@property (nonatomic, strong, nullable) UIColor *listSelectionBackgroundColor;

- (void)ne_markSelectedConversationId:(nullable NSString *)conversationId;
- (void)ne_selectConversation:(nullable NSString *)conversationId animated:(BOOL)animated;
/// 传 nil 释放保留，恢复普通手机的分组规则；内部按“值是否变化”决定是否刷新列表。
- (void)ne_retainConversationInGroup:(nullable NSString *)conversationId;

@property (nonatomic, strong) UIColor *deleteButtonBackgroundColor;

/// 左滑置顶按钮默认背景色
@property (nonatomic, strong) UIColor *topButtonBackgroundColor;

/// 断网提示区域高度
@property (nonatomic, assign) CGFloat brokenNetworkViewHeight;

/// 数据源类型（Cloud / Local），初始化时指定
@property (nonatomic, assign, readonly) NEConversationDataSourceType dataSourceType;

/// 自定义标题栏（含品牌按钮、搜索、新建）
@property (nonatomic, strong) TabNavigationView *navigationView;

/// 导航栏下方的顶部自定义区域
@property (nonatomic, strong) UIView *bodyTopView;
@property (nonatomic, strong, readonly) UIView *bodyView;
@property (nonatomic, strong, readonly) UIView *contentView;

/// 顶部自定义区域高度
@property (nonatomic, assign) CGFloat bodyTopViewHeight;

/// 置顶（AI 用户）区域高度覆盖值；0 表示使用默认高度。
@property (nonatomic, assign) CGFloat adaptiveStickTopHeight;

/// 导航栏和状态栏占用的顶部高度
@property (nonatomic, assign) CGFloat topConstant;

/// 导航栏下方的底部自定义区域
@property (nonatomic, strong) UIView *bodyBottomView;

/// 底部自定义区域高度
@property (nonatomic, assign) CGFloat bodyBottomViewHeight;

@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyTopViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyBottomViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentViewTopAnchor;

/// tableView
@property (nonatomic, strong) UITableView *tableView;

/// 空数据视图
@property (nonatomic, strong) NEEmptyDataView *emptyView;

/// 网络断开提示
@property (nonatomic, strong) NEBrokenNetworkView *brokenNetworkView;

/// 置顶内容展示列表（名称保持与 Swift UIKit 公共 API 一致）。
@property (nonatomic, strong, readonly) UICollectionView *stickTopCollcetionView;

@property (nonatomic, strong) NEBasePopListView *popListView;

/// cell 行高
@property (nonatomic, assign) CGFloat cellRowHeight;

/// 代理
@property (nonatomic, weak, nullable) id<NEBaseConversationControllerDelegate> delegate;

/// 是否已请求过数据
@property (nonatomic, assign) BOOL isRequestedData;

/// 会话列表与数字人置顶列表的自定义 Cell 注册表，key 对应模型 customType。
@property (nonatomic, copy) NSDictionary<NSNumber *, Class> *cellRegisterDic;
@property (nonatomic, copy) NSDictionary<NSNumber *, Class> *stickTopCellRegisterDic;

#pragma mark - 初始化

/// 使用指定数据源类型初始化（推荐）
- (instancetype)initWithDataSourceType:(NEConversationDataSourceType)type;

/// Cloud 便捷初始化
+ (instancetype)cloudController;

/// Local 便捷初始化
+ (instancetype)localController;

#pragma mark - 数据

/// 首次请求数据
- (void)requestData;

/// 加载更多
- (void)loadMoreData;

/// 返回当前皮肤对应的扫一扫页面。
- (NEBaseScanQRViewController *)getScanQRViewController;

/// 根据全局配置切换系统导航栏或自定义导航栏。
- (void)showTitleBar;

/// 初始化系统导航栏内容。
- (void)initSystemNav;

- (NEBasePopListView *)getPopListView;
- (NSArray<PopListItem *> *)getPopListItems;
- (void)onselectedTableRowWithConversation:(V2NIMConversation *)conversation;
- (void)didDeleteConversationCellWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)didRemoveStickTopSessionWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)didAddStickTopSessionWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)onTopRecentAtIndexPathWithConversation:(V2NIMConversation *)conversation
                                     indexPath:(NSIndexPath *)indexPath
                                         isTop:(BOOL)isTop
                                    completion:(void (^)(NSError *_Nullable error))completion;
- (void)conversationGroupDidReload;
- (void)conversationGroupSelectionChanged;

#pragma mark - 子类可重写

/// Cell 配置方法（子类可重写以自定义 Cell）
- (UITableViewCell *)cellForRowAtModel:(NEConversationListModel *)model
                             indexPath:(NSIndexPath *)indexPath
                             tableView:(UITableView *)tableView;

/// 点击 Cell
- (void)didSelectConversation:(NEConversationListModel *)model
                  atIndexPath:(NSIndexPath *)indexPath;

/// 左划操作（delete + stickTop）
- (nullable UISwipeActionsConfiguration *)trailingActionsForModel:(NEConversationListModel *)model
                                                      atIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0));

/// 删除会话
- (void)deleteActionHandlerWithIndexPath:(NSIndexPath *)indexPath;

/// 置顶 / 取消置顶
- (void)topActionHandlerWithIndexPath:(NSIndexPath *)indexPath isTop:(BOOL)isTop;

/// 删除一条会话后的回调，子类可重写
- (void)didDeleteConversationCell:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;

/// 删除一条置顶记录后的回调，子类可重写
- (void)didRemoveStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;

/// 添加一条置顶记录后的回调，子类可重写
- (void)didAddStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath;

@end

/// 旧版 OC 类名兼容入口，公共实现由 NEBaseConversationController 承载。
@interface NEConversationViewController : NEBaseConversationController

@property (nonatomic, weak, nullable) id<NEConversationViewControllerDelegate> delegate;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (void)setupSubviews;
- (void)initialConfig;
- (void)brandBtnClick;
- (void)searchAction;
- (void)didClickAddBtn;
- (void)openScanQR;
- (BOOL)handleQRScanResult:(NSString *)result;
- (void)createDiscussGroup;
- (void)createSeniorGroup;
- (void)subscribeVisibleRows;
- (NSArray<NEConversationListModel *> *)displayConversationList;
- (void)reloadData;
- (void)reloadTableView;
- (void)renderConversationList;
- (void)loadMoreStateChange:(BOOL)finish;

@end

/// NormalUI 会话列表。
@interface ConversationController : NEBaseConversationController

@property (nonatomic, strong, readonly) UIButton *searchBarButton;
@property (nonatomic, strong, readonly) UIView *pinUserDividerLine;
@property (nonatomic, strong, readonly) UIButton *addBarButton;

- (void)changeLanguage;
- (void)setupNormalStickTopView;

@end

/// FunUI 会话列表。
@interface FunConversationController : NEBaseConversationController

@property (nonatomic, strong, readonly) FunSearchView *searchView;

- (void)changeLanguage;
- (void)setupFunStickTopView;

@end

NS_ASSUME_NONNULL_END
