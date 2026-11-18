// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 统一导航栏控制器，设定全局导航栏样式
@interface NENavigationController : UINavigationController

/// 导航栏背景色，默认白色
@property (nonatomic, strong) UIColor *barBackgroundColor;

/// 导航栏 tintColor（按钮/文字颜色）
@property (nonatomic, strong) UIColor *barTintColor;

/// 导航栏标题文字颜色
@property (nonatomic, strong) UIColor *titleColor;

/// 导航栏标题字号，默认 17
@property (nonatomic, assign) CGFloat titleFontSize;

@end

NS_ASSUME_NONNULL_END
