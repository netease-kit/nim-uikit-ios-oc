// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/ChatKitClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEContactService : NSObject <ChatServiceDelegate>

@property (class, nonatomic, readonly) NEContactService *shared;

/// 注册 NEContactUIKit 初始化协议
- (void)setupInit:(nullable NSDictionary<NSString *, id> *)params;

/// 注册路由
- (void)registerRouter:(nullable NSDictionary<NSString *, id> *)param;

@end

NS_ASSUME_NONNULL_END
