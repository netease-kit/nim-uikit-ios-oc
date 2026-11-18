// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEAdaptiveLayoutTypes.h"

NS_ASSUME_NONNULL_BEGIN

///
/// 角标底色全部由宿主注入，公共组件不引用任一皮肤的私有资源。
@interface NEAdaptiveShellConfiguration : NSObject

@property (nonatomic, assign) CGFloat railWidth;
@property (nonatomic, assign) CGFloat singleContentMinimumWidth;
@property (nonatomic, assign) CGFloat masterMinimumWidth;
@property (nonatomic, assign) CGFloat detailMinimumWidth;
@property (nonatomic, assign) CGFloat dividerWidth;

/// 必填：medium / expanded 两档的列表首选宽与统一上限。
@property (nonatomic, assign) CGFloat mediumMasterWidth;
@property (nonatomic, assign) CGFloat expandedMasterWidth;
@property (nonatomic, assign) CGFloat masterMaximumWidth;

/// 断点（需求初值，不是 Apple 官方断点）。
@property (nonatomic, assign) CGFloat mediumThreshold;
@property (nonatomic, assign) CGFloat expandedThreshold;
@property (nonatomic, assign) CGFloat compactAspectRatio;

@property (nonatomic, strong) UIColor *railBackgroundColor;
/// 双栏分界线的动态颜色。
@property (nonatomic, strong) UIColor *dividerColor;
@property (nonatomic, strong) UIColor *selectedTintColor;
@property (nonatomic, strong) UIColor *normalTintColor;

/// 皮肤提供的返回图；关闭 `usesSystemBackButtonStyle` 时使用。
@property (nonatomic, strong, nullable) UIImage *backImage;
@property (nonatomic, strong) UIColor *backTintColor;
/// 单屏聊天返回入口使用系统返回按钮样式（SF Symbol `chevron.left`）。
@property (nonatomic, assign) BOOL usesSystemBackButtonStyle;
@property (nonatomic, copy, nullable) NSString *backAccessibilityLabel;

@property (nonatomic, assign) BOOL railUsesTrailingEdge;

@property (nonatomic, assign) CGFloat railItemHeight;
@property (nonatomic, assign) CGFloat railItemSpacing;
@property (nonatomic, assign) CGFloat railItemsTopInset;
@property (nonatomic, assign) CGFloat railItemsBottomInset;

/// 统一返回按钮的圆形视觉与命中尺寸。
@property (nonatomic, assign) CGFloat railBackButtonSize;
@property (nonatomic, assign) CGFloat railActionButtonSize;
/// 多个右侧操作之间的垂直间距。
@property (nonatomic, assign) CGFloat railActionSpacing;
/// 返回按钮与第一个右侧操作之间的间距。
@property (nonatomic, assign) CGFloat railActionTopSpacing;

@property (nonatomic, strong) UIColor *railControlBackgroundColor;
@property (nonatomic, strong) UIColor *railControlBorderColor;
@property (nonatomic, assign) CGFloat railControlBorderWidth;
@property (nonatomic, strong) UIColor *railActionTextColor;
@property (nonatomic, strong) UIFont *railActionTextFont;
/// 数量角标背景色；nil 时跟随 `selectedTintColor`（皮肤主题色）。
@property (nonatomic, strong, nullable) UIColor *railBadgeBackgroundColor;
@property (nonatomic, strong) UIColor *railBadgeTextColor;

/// 尾部系统状态区下方由宿主校准的返回按钮位置。
@property (nonatomic, assign) CGFloat railBackTopInset;
@property (nonatomic, assign) CGFloat contentTopInset;
@property (nonatomic, strong) UIColor *contentBackgroundColor;

- (instancetype)initWithRailWidth:(CGFloat)railWidth
          singleContentMinimumWidth:(CGFloat)singleContentMinimumWidth
               masterMinimumWidth:(CGFloat)masterMinimumWidth
               detailMinimumWidth:(CGFloat)detailMinimumWidth
                     dividerWidth:(CGFloat)dividerWidth
                 mediumMasterWidth:(CGFloat)mediumMasterWidth
               expandedMasterWidth:(CGFloat)expandedMasterWidth
               masterMaximumWidth:(CGFloat)masterMaximumWidth NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// 内部使用：转换为纯几何策略输入。
- (NEAdaptiveLayoutConfiguration)policyConfiguration;

@end

NS_ASSUME_NONNULL_END
