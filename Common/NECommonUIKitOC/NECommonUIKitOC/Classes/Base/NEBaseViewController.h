// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NENavigationView;

NS_ASSUME_NONNULL_BEGIN

/// UI 模块 ViewController 基类
/// 提供自定义导航栏（NENavigationView）、返回按钮处理、侧滑返回手势支持。
@interface NEBaseViewController : UIViewController <UIGestureRecognizerDelegate>

/// 自定义导航栏顶部高度（默认 = navigationAndStatusHeight）
/// 设置时自动同步 navigationViewHeightAnchor
@property (nonatomic, assign) CGFloat topConstant;

/// 自定义导航栏高度约束
@property (nonatomic, strong, nullable) NSLayoutConstraint *navigationViewHeightAnchor;

/// 自定义导航栏视图
@property (nonatomic, strong, readonly) NENavigationView *navigationView;

/// 返回事件（子类可重写）
- (void)backEvent;

/// 设置按钮事件（子类可重写）
- (void)toSetting;

/// 添加左侧侧滑返回手势
- (void)addLeftSwipeDismissGesture;

/// 弹出单按钮 Alert（用于错误提示等）
- (void)showSingleAlertWithMessage:(NSString *)message completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END