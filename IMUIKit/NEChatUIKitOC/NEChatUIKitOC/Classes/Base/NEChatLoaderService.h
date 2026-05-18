// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEChatLoaderService : NSObject

+ (instancetype)shared;

/// 初始化方法
/// 此方法会在模块被加载时调用
- (void)setupInit;

/// 初始化 ChatKit，并指定是否加载 Fun UI 路由
- (void)setupInitWithFunUI:(BOOL)isFun;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
