// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEAdaptiveShellConfiguration.h"
#import "NEConversationOpenIntent.h"
#import "NEChatDetailHostController.h"
#import "NEConversationNavigationCoordinator.h"

NS_ASSUME_NONNULL_BEGIN

/// 双栏顶部留白的左右列底色：并排页面允许不同背景色。
@interface NEAdaptiveColumnColors : NSObject

@property (nonatomic, strong, readonly) UIColor *master;
@property (nonatomic, strong, readonly) UIColor *detail;

- (instancetype)initWithMaster:(UIColor *)master detail:(UIColor *)detail NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface NEAdaptiveShellViewController : UIViewController <NEConversationPresentationHandler, UITabBarDelegate>

@property (nonatomic, strong, readonly) NEAdaptiveShellConfiguration *configuration;
@property (nonatomic, copy, readonly) NSArray<UINavigationController *> *sections;
/// 稳定持有聊天导航栈的父容器。
@property (nonatomic, strong, readonly) NEChatDetailHostController *detailHost;
@property (nonatomic, strong, readonly) NEConversationNavigationCoordinator *conversationCoordinator;
@property (nonatomic, assign, readonly) NSInteger selectedSectionIndex;
@property (nonatomic, assign, readonly) BOOL isUsingLegacyLayout;
/// 右列是否正与左列并排展示。
@property (nonatomic, assign, readonly, getter=isShowingPairedContent) BOOL showingPairedContent;
@property (nonatomic, assign, readonly, getter=isUsingAdaptiveLayout) BOOL usingAdaptiveLayout;
/// 当前拥有可见内容面的控制器（双栏下是右列可见页）。
@property (nonatomic, strong, readonly, nullable) UIViewController *activeContentViewController;

@property (nonatomic, copy, nullable) void (^onSectionSelected)(NSInteger index);
@property (nonatomic, copy, nullable) void (^onLegacyFallback)(void);
@property (nonatomic, copy, nullable) void (^onGeometryChanged)(NSDictionary<NSString *, id> *geometry);
@property (nonatomic, copy, nullable) void (^onContentLayout)(NSArray<UIViewController *> *controllers);
/// 顶部留白底色（可取自当前分区）。
@property (nonatomic, copy, nullable) UIColor *(^contentBackgroundColorProvider)(void);
/// 顶部留白左右列独立底色。
@property (nonatomic, copy, nullable) NEAdaptiveColumnColors *(^contentBackgroundColorsProvider)(void);
/// 分区右列导航栈工厂。
@property (nonatomic, copy, nullable) UINavigationController *(^sectionDetailNavigationFactory)(void);
@property (nonatomic, copy, nullable) void (^onSectionDetailNavigationCreated)(UINavigationController *navigation);
@property (nonatomic, copy, nullable) void (^onCompactChatVisibilityChanged)(UIViewController *chatRoot, BOOL visible);
@property (nonatomic, copy, nullable) void (^onConversationOpened)(NSString *conversationId);
@property (nonatomic, copy, nullable) UIViewController *(^sectionEmptyDetailFactory)(NSInteger index);
@property (nonatomic, copy, nullable) void (^onDetailPlaceholderChanged)(BOOL placeholder);

- (instancetype)initWithSections:(NSArray<UINavigationController *> *)sections
        detailNavigationController:(UINavigationController *)detailNavigationController
                   configuration:(NEAdaptiveShellConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// Scene 更新、根容器转场、安全区/trait 变化时调用；根视图自身的布局也会自动触发。
- (void)refreshWindow;
/// 换根或退出时注销窗口监听。
- (void)invalidateWindowContext;

- (NSArray<UINavigationController *> *)detachSectionsForLegacyTransfer;

- (BOOL)openConversation:(NEConversationOpenIntent *)intent;

/// 会话被删除或退群时清理保留的聊天页。
- (void)clearConversationIfNeeded:(NSString *)conversationId;
- (void)clearActiveConversation;
- (void)showConversationList;
- (void)selectSection:(NSInteger)index;

- (BOOL)presentSectionChild:(UIViewController *)controller
    fromNavigationController:(UINavigationController *)navigationController
                     animated:(BOOL)animated;

- (void)updateRailItems;
- (void)refreshRailNavigation;

@end

NS_ASSUME_NONNULL_END
