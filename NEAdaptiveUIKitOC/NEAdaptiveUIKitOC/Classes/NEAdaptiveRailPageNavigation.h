// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEAdaptiveRailNavigation.h"

NS_ASSUME_NONNULL_BEGIN

///
/// 支持三类既有来源：
/// - `NENavigationView` 及其子类（IMKit 标准自绘标题栏）；
/// - 系统 `UINavigationItem`；
/// - 页面自绘标题栏（使用 `NEUnifiedBackButton`，或 `id.arrowDown` 的收起入口）。
///
@interface NEAdaptiveRailPageNavigation : NSObject

@property (nonatomic, copy, nullable) void (^onChange)(void);

/// 解析页面当前的导航栏动作；页面没有可迁移入口时返回 nil。
+ (nullable instancetype)makeForPage:(UIViewController *)page;

/// 页面当前是否展示自己的标题栏（自绘整窗页头且没有统一返回入口的页面自己承担返回）。
+ (BOOL)hasVisibleTitleBarInPage:(UIViewController *)page;

/// 返回动作：页面自己配置了返回入口时原样转发，保留页面自定义语义。
- (nullable NEAdaptiveRailAction *)backAction;

/// 页面当前可见的全部右侧操作，按页面从左到右排列。
- (NSArray<NEAdaptiveRailAction *> *)trailingActions;

/// 绑定是否仍是页面当前的导航入口来源。
- (BOOL)isValidForPage:(UIViewController *)page;

- (void)suppress;

/// 页面重新出现后可能再次写入系统导航项，把新写入项纳入缓存并再次移交。
- (void)refreshSuppressedSystemItems;

- (void)restore;

@end

NS_ASSUME_NONNULL_END
