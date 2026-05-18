// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Swift 版 NELoginViewController
/// 主登录入口页：Logo + 登录按钮 + 底部工具栏（账号直连、节点选择等）
@interface LoginViewController : UIViewController

/// 登录成功回调
@property (nonatomic, copy, nullable) void (^loginSuccess)(void);

@end

NS_ASSUME_NONNULL_END