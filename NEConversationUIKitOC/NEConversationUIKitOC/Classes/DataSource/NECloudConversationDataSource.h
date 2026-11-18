// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NECloudConversationDataSource.h
// Cloud 会话数据源 — 实现 NEConversationDataSource 协议
// 底层使用 ConversationRepo (V2NIMConversation)

#import <Foundation/Foundation.h>
#import "NEConversationDataSource.h"

@class ConversationRepo;

NS_ASSUME_NONNULL_BEGIN

@interface NECloudConversationDataSource : NSObject <NEConversationDataSource>

- (instancetype)init;

/// 直接访问底层 ConversationRepo（供 ViewModel 在需要 Cloud 特有功能时使用）
@property (nonatomic, strong, readonly) ConversationRepo *repo;

@end

NS_ASSUME_NONNULL_END
