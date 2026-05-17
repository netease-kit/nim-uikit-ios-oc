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

NS_ASSUME_NONNULL_BEGIN

/// ViewController 数据加载回调
@protocol NEConversationViewControllerDelegate <NSObject>
@optional
- (void)onDataLoaded;
@end

@interface NEConversationViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

/// 会话 ViewModel
@property (nonatomic, strong, readonly) ConversationViewModel *viewModel;

/// 数据源类型（Cloud / Local），初始化时指定
@property (nonatomic, assign, readonly) NEConversationDataSourceType dataSourceType;

/// 自定义标题栏（含品牌按钮、搜索、新建）
@property (nonatomic, strong) TabNavigationView *navigationView;

/// 导航栏下方的顶部自定义区域
@property (nonatomic, strong) UIView *bodyTopView;

/// 顶部自定义区域高度
@property (nonatomic, assign) CGFloat bodyTopViewHeight;

/// tableView
@property (nonatomic, strong) UITableView *tableView;

/// 空数据视图
@property (nonatomic, strong) NEEmptyDataView *emptyView;

/// 网络断开提示
@property (nonatomic, strong) NEBrokenNetworkView *brokenNetworkView;

/// cell 行高
@property (nonatomic, assign) CGFloat cellRowHeight;

/// 代理
@property (nonatomic, weak, nullable) id<NEConversationViewControllerDelegate> delegate;

/// 是否已请求过数据
@property (nonatomic, assign) BOOL isRequestedData;

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

NS_ASSUME_NONNULL_END
