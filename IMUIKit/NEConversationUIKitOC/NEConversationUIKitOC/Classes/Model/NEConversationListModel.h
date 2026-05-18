// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEConversationListModel.h
// 统一会话列表模型 — 对齐 Swift NEConversationListModel / NELocalConversationListModel
// Cloud 和 Local 共用同一个 Model，内部持有原始 SDK 对象。

#import <Foundation/Foundation.h>

@class V2NIMConversation;
@class V2NIMLocalConversation;
@class V2NIMMessage;
@class V2NIMLastMessage;

NS_ASSUME_NONNULL_BEGIN

/// 统一会话列表模型
/// 持有原始 SDK 会话对象（Cloud 或 Local），并提取公共属性供 UI 层使用
@interface NEConversationListModel : NSObject

#pragma mark - 公共属性（对齐 Swift 版本）

/// 会话 ID
@property (nonatomic, copy, readonly) NSString *conversationId;

/// 会话类型（V2NIMConversationType 的 rawValue）
@property (nonatomic, assign, readonly) NSInteger type;

/// 显示名称
@property (nonatomic, copy, readonly, nullable) NSString *name;

/// 头像 URL
@property (nonatomic, copy, readonly, nullable) NSString *avatar;

/// 未读数
@property (nonatomic, assign, readonly) NSInteger unreadCount;

/// 是否置顶
@property (nonatomic, assign, readonly) BOOL stickTop;

/// 排序权重
@property (nonatomic, assign, readonly) int64_t sortOrder;

/// 是否免打扰
@property (nonatomic, assign, readonly) BOOL mute;

/// 本地扩展
@property (nonatomic, copy, readonly, nullable) NSString *localExtension;

/// 最后一条消息（V2NIMLastMessage，非 V2NIMMessage）
@property (nonatomic, strong, readonly, nullable) V2NIMLastMessage *lastMessage;

#pragma mark - UI 扩展属性

/// 自定义类型（对齐 Swift customType）
@property (nonatomic, assign) NSInteger customType;

/// 最后一条消息内容（包含表情解析后的富文本）
@property (nonatomic, strong, nullable) NSAttributedString *lastMessageContent;

/// 单聊是否在线
@property (nonatomic, assign) BOOL p2pOnline;

#pragma mark - 原始对象访问

/// 云端会话原始对象（仅 Cloud DataSource 时有值）
@property (nonatomic, strong, nullable) V2NIMConversation *cloudConversation;

/// 本地会话原始对象（仅 Local DataSource 时有值）
@property (nonatomic, strong, nullable) V2NIMLocalConversation *localConversation;

#pragma mark - 便捷构造

/// 从云端会话创建
+ (instancetype)modelWithCloudConversation:(V2NIMConversation *)conversation;

/// 从本地会话创建
+ (instancetype)modelWithLocalConversation:(V2NIMLocalConversation *)conversation;

/// 更新底层会话对象（自动刷新公共属性）
- (void)updateWithCloudConversation:(V2NIMConversation *)conversation;
- (void)updateWithLocalConversation:(V2NIMLocalConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
