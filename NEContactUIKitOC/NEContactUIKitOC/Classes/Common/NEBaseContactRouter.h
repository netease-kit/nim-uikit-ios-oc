// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContactRouter : NSObject
@end

/// 两套皮肤分别提供注册实现，公共头文件统一公开入口。
@interface ContactRouter (Registration)
+ (void)registerRouter;
+ (void)registerFun;

@end

NS_ASSUME_NONNULL_END
