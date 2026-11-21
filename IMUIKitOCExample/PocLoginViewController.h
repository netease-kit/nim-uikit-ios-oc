// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Swift 版 PocLoginViewController
/// 账号 + Token 直连登录页（用于开发/测试/私有化场景）
@interface PocLoginViewController : UIViewController

/// 登录成功回调
@property (nonatomic, copy, nullable) void (^loginSuccess)(void);

@end

NS_ASSUME_NONNULL_END
