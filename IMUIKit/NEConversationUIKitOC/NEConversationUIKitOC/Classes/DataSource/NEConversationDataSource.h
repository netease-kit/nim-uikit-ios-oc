// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEConversationDataSource.h
// 统一会话数据源协议 — 对齐 D8 设计决策
// Cloud 和 Local 会话共享同一套 UI，通过此协议切换底层实现。

#import <Foundation/Foundation.h>

@class V2NIMConversation;
@class V2NIMLocalConversation;
@class V2NIMMessage;

NS_ASSUME_NONNULL_BEGIN

/// 会话数据源类型枚举
typedef NS_ENUM(NSInteger, NEConversationDataSourceType) {
    NEConversationDataSourceTypeCloud = 0,
    NEConversationDataSourceTypeLocal = 1,
};

#pragma mark - NEConversationDataSourceListener

/// 统一会话数据源监听协议
/// ViewModel 实现此协议接收来自 DataSource 的事件推送
@protocol NEConversationDataSourceListener <NSObject>
@optional
- (void)onDataSourceSyncStarted;
- (void)onDataSourceSyncFinished;
- (void)onDataSourceSyncFailed:(NSError *)error;
- (void)onDataSourceConversationCreated:(NSString *)conversationId;
- (void)onDataSourceConversationDeleted:(NSArray<NSString *> *)conversationIds;
- (void)onDataSourceConversationChanged:(NSArray<NSString *> *)conversationIds;
- (void)onDataSourceTotalUnreadCountChanged:(NSInteger)unreadCount;
@end

#pragma mark - NEConversationDataSource

/// 统一会话数据源协议
/// Cloud 和 Local 各自实现此协议，ViewModel 通过 `id<NEConversationDataSource>` 持有
@protocol NEConversationDataSource <NSObject>

/// 数据源类型
@property (nonatomic, readonly) NEConversationDataSourceType dataSourceType;

#pragma mark - Listener
- (void)addDataSourceListener:(id<NEConversationDataSourceListener>)listener;
- (void)removeDataSourceListener:(id<NEConversationDataSourceListener>)listener;

#pragma mark - Conversation List (分页)
/// 分页获取会话列表
/// @param offset 起始偏移（Cloud 为 int64_t 对应 sortOrder，Local 为 int 对应分页索引，统一使用 int64_t）
/// @param limit 每页数量
/// @param completion 回调：conversationIds, newOffset, finished, error
- (void)getConversationList:(int64_t)offset
                      limit:(NSInteger)limit
                 completion:(void (^)(NSArray<NSString *> * _Nullable conversationIds,
                                      NSNumber * _Nullable newOffset,
                                      NSNumber * _Nullable finished,
                                      NSError * _Nullable error))completion;

#pragma mark - Get Conversations
/// 根据 conversationId 获取会话属性
/// 回调字典包含统一属性: conversationId, type(NSNumber), name, avatar, lastMessage,
///         unreadCount(NSNumber), stickTop(NSNumber/BOOL), sortOrder(NSNumber),
///         mute(NSNumber/BOOL), localExtension
- (void)getConversationInfo:(NSString *)conversationId
                 completion:(void (^)(NSDictionary * _Nullable info, NSError * _Nullable error))completion;

/// 批量获取会话 ID 对应的 SDK 原始对象（V2NIMConversation / V2NIMLocalConversation）
/// ViewModel 在需要调用 SDK 特定 API 时可通过此方法获取原始对象
- (void)getRawConversationsByIds:(NSArray<NSString *> *)conversationIds
                      completion:(void (^)(NSArray * _Nullable rawConversations, NSError * _Nullable error))completion;

#pragma mark - CRUD
- (void)deleteConversation:(NSString *)conversationId
              clearMessage:(BOOL)clearMessage
                completion:(void (^)(NSError * _Nullable))completion;

- (void)createConversation:(NSString *)conversationId
                completion:(void (^)(NSString * _Nullable createdConversationId, NSError * _Nullable))completion;

#pragma mark - Stick Top
- (void)setStickTop:(NSString *)conversationId
           stickTop:(BOOL)stickTop
         completion:(void (^)(NSError * _Nullable))completion;

#pragma mark - Unread
- (NSInteger)getTotalUnreadCount;
- (void)clearTotalUnreadCountWithCompletion:(void (^)(NSError * _Nullable))completion;
- (void)clearUnreadCountByIds:(NSArray<NSString *> *)conversationIds
                   completion:(void (^)(NSError * _Nullable))completion;

#pragma mark - Read Time
- (void)markConversationRead:(NSString *)conversationId
                  completion:(void (^)(NSNumber * _Nullable timestamp, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
