// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 三 Tab 主框架：消息 / 通讯录 / 我
@interface NETabBarController : UITabBarController

/// 是否通过切换 UI 风格触发（非首次登录场景）
@property (nonatomic, assign) BOOL isChangeUIType;

- (instancetype)initWithChangeUI:(BOOL)isChangeUI;

@property (nonatomic, strong, readonly, nullable) UINavigationController *chatNavigation;
@property (nonatomic, strong, readonly, nullable) UINavigationController *contactNavigation;
@property (nonatomic, strong, readonly, nullable) UINavigationController *mineNavigation;

- (nullable UIViewController *)makeAdaptiveShellIfEnabled;

@end

NS_ASSUME_NONNULL_END
