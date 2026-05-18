// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKitOC/MessageModel.h>

@class NEChatBaseCell;
@class ChatUIConfig;

NS_ASSUME_NONNULL_BEGIN

/// 消息内容模型基类，遵循 MessageModel 协议
@interface MessageContentModel : NSObject <MessageModel>

#pragma mark - MessageModel Protocol Properties

/// 消息类型（文本、图片、自定义消息...）
@property (nonatomic, assign) MessageType type;
/// 自定义消息的子类型（合并转发、换行消息...）
@property (nonatomic, assign) NSInteger customType;
/// V2NIM 消息对象
@property (nonatomic, strong, nullable) V2NIMMessage *message;

#pragma mark - Cell Reference

/// 消息对应的cell（弱引用）
@property (nonatomic, weak, nullable) NEChatBaseCell *cell;

#pragma mark - Layout

/// 偏移量
@property (nonatomic, assign) CGFloat offset;
/// 文本宽度
@property (nonatomic, assign) CGFloat textWidth;
/// 气泡区域大小
@property (nonatomic, assign) CGSize contentSize;
/// 高度
@property (nonatomic, assign) CGFloat height;

#pragma mark - Selection

/// 划词选择的范围
@property (nonatomic, strong, nullable) NSValue *selectRange; // wraps NSRange
/// 多选按钮是否展示
@property (nonatomic, assign) BOOL showSelect;
/// 多选是否选中
@property (nonatomic, assign) BOOL isSelected;
/// 是否全选
@property (nonatomic, assign) BOOL isSelectAll;
/// 是否未知消息
@property (nonatomic, assign) BOOL unkonwMessage;
/// 是否是合并消息中的子消息
@property (nonatomic, assign) BOOL inMultiForward;

#pragma mark - User Info

/// 头像URL
@property (nonatomic, copy, nullable) NSString *avatar;
/// 昵称 > uid
@property (nonatomic, copy, nullable) NSString *shortName;
/// 备注 >（群昵称）> 昵称 > uid
@property (nonatomic, copy, nullable) NSString *fullName;
/// 群聊气泡上方用户名label高度
@property (nonatomic, assign) CGFloat fullNameHeight;

#pragma mark - Read/Unread

/// 已读数
@property (nonatomic, assign) NSInteger readCount;
/// 未读数
@property (nonatomic, assign) NSInteger unreadCount;

#pragma mark - Reply

/// 是否为回复消息
@property (nonatomic, assign) BOOL isReply;
/// 回复文本
@property (nonatomic, copy, nullable) NSString *replyText;
/// 被回复的消息模型
@property (nonatomic, strong, nullable) id<MessageModel> replyedModel;

#pragma mark - Revoke

/// 是否可重新编辑
@property (nonatomic, assign) BOOL isReedit;
/// 是否超时
@property (nonatomic, assign) BOOL timeOut;
/// 撤回时间
@property (nonatomic, assign) NSTimeInterval revokeTime;
/// 是否已撤回
@property (nonatomic, assign) BOOL isRevoked;

#pragma mark - Pin

/// 标记账号
@property (nonatomic, copy, nullable) NSString *pinAccount;
/// 标记显示名
@property (nonatomic, copy, nullable) NSString *pinShowName;
/// 是否被标记
@property (nonatomic, assign) BOOL isPined;

#pragma mark - Time

/// 是否显示时间
@property (nonatomic, copy, nullable) NSString *timeContent;

#pragma mark - Text Style

/// 消息文本字体
@property (nonatomic, strong) UIFont *messageTextFont;
/// 消息文本颜色
@property (nonatomic, strong) UIColor *messageTextColor;
/// 消息文本最大尺寸
@property (nonatomic, assign, readonly) CGSize messageMaxSize;

#pragma mark - Init

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

#pragma mark - Methods

/// 计算cell高度
- (CGFloat)cellHeight;

/// 获取划词选中的文本（子类覆写）
- (nullable NSString *)selectText;

/// 重置消息
/// @param message V2NIM 消息对象
- (void)resetMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
