// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NELocalConversationDataSource.h
// Local 会话数据源 — 实现 NEConversationDataSource 协议
// 底层使用 LocalConversationRepo (V2NIMLocalConversation)

#import <Foundation/Foundation.h>
#import "NEConversationDataSource.h"

@class LocalConversationRepo;

NS_ASSUME_NONNULL_BEGIN

@interface NELocalConversationDataSource : NSObject <NEConversationDataSource>

- (instancetype)init;

/// 直接访问底层 LocalConversationRepo（供 ViewModel 在需要 Local 特有功能时使用）
@property (nonatomic, strong, readonly) LocalConversationRepo *repo;

@end

NS_ASSUME_NONNULL_END
