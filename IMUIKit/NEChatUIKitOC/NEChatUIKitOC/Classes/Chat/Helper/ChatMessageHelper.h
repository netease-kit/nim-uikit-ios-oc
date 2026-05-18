// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "MessageContentModel.h"
#import "MessageEnum.h"
#import "NEChatUIConstant.h"

// ── Message model types ────────────────────────────────────────────────
@class MessageTextModel;
@class MessageAIStreamModel;
@class MessageImageModel;
@class MessageAudioModel;
@class MessageVideoModel;
@class MessageFileModel;
@class MessageLocationModel;
@class MessageCallRecordModel;
@class MessageTipsModel;
@class MessageRichTextModel;
@class MessageCustomModel;

// ── Chat-page cell types (declared; may not be compiled yet) ───────────
@class ChatMessageTextCell;
@class ChatMessageAIStreamTextCell;
@class ChatMessageCallCell;
@class ChatMessageAudioCell;
@class ChatMessageImageCell;
@class ChatMessageRevokeCell;
@class ChatMessageVideoCell;
@class ChatMessageFileCell;
@class ChatMessageLocationCell;
@class ChatMessageTipCell;
@class ChatMessageMultiForwardCell;
@class ChatMessageRichTextCell;

@class FunChatMessageTextCell;
@class FunChatMessageAIStreamTextCell;
@class FunChatMessageCallCell;
@class FunChatMessageAudioCell;
@class FunChatMessageImageCell;
@class FunChatMessageRevokeCell;
@class FunChatMessageVideoCell;
@class FunChatMessageFileCell;
@class FunChatMessageLocationCell;
@class FunChatMessageTipCell;
@class FunChatMessageMultiForwardCell;
@class FunChatMessageRichTextCell;

// ── Pin-page cell types ────────────────────────────────────────────────
@class PinMessageTextCell;
@class PinMessageImageCell;
@class PinMessageAudioCell;
@class PinMessageVideoCell;
@class PinMessageLocationCell;
@class PinMessageFileCell;
@class PinMessageMultiForwardCell;
@class PinMessageRichTextCell;
@class PinMessageDefaultCell;

@class FunPinMessageTextCell;
@class FunPinMessageImageCell;
@class FunPinMessageAudioCell;
@class FunPinMessageVideoCell;
@class FunPinMessageLocationCell;
@class FunPinMessageFileCell;
@class FunPinMessageMultiForwardCell;
@class FunPinMessageRichTextCell;
@class FunPinMessageDefaultCell;

// ── Collection-page cell types ────────────��────────────────────────────
@class CollectionMessageTextCell;
@class CollectionMessageImageCell;
@class CollectionMessageAudioCell;
@class CollectionMessageVideoCell;
@class CollectionMessageLocationCell;
@class CollectionMessageFileCell;
@class CollectionMessageMultiForwardCell;
@class CollectionMessageRichTextCell;
@class CollectionMessageDefaultCell;
@class CollectionDefaultCell;

@class FunCollectionMessageTextCell;
@class FunCollectionMessageImageCell;
@class FunCollectionMessageAudioCell;
@class FunCollectionMessageVideoCell;
@class FunCollectionMessageLocationCell;
@class FunCollectionMessageFileCell;
@class FunCollectionMessageMultiForwardCell;
@class FunCollectionMessageRichTextCell;
@class FunCollectionMessageDefaultCell;
@class FunCollectionDefaultCell;

// ── Other forward declarations ─────────────────────────────────────────
@class NEUserWithFriend;
@class V2NIMMessageRefer;
@class MessageAtInfoModel;

NS_ASSUME_NONNULL_BEGIN

/// OC implementation of ChatMessageHelper — mirrors the Swift original.
@interface ChatMessageHelper : NSObject

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Geometry

/// 获取图片合适尺寸
/// @param maxSize   最大宽高
/// @param size      图片原始宽高
/// @param miniWH    最小宽高
+ (CGSize)getSizeWithMaxSize:(CGSize)maxSize size:(CGSize)size miniWH:(CGFloat)miniWH;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Session Name

/// 获取会话昵称
/// @param conversationId 会话 id
/// @param showAlias      是否优先显示备注
+ (NSString *)getSessionName:(NSString *)conversationId showAlias:(BOOL)showAlias;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Cell Registration Dictionaries

/// 聊天页单元格注册字典 { reuseId → cellClass }
/// @param isFun 是否娱乐皮肤
+ (NSDictionary<NSString *, Class> *)getChatCellRegisterDic:(BOOL)isFun;

/// 兼容旧的 Swift 风格命名
+ (NSDictionary<NSString *, Class> *)getChatCellRegisterDicWithIsFun:(BOOL)isFun;

/// 标记页单元格注册字典 { reuseId → cellClass }
/// @param isFun 是否娱乐皮肤
+ (NSDictionary<NSString *, Class> *)getPinCellRegisterDic:(BOOL)isFun;

/// 收藏页单元格注册字典 { reuseId → cellClass }
/// @param isFun 是否娱乐皮肤
+ (NSDictionary<NSString *, Class> *)getCollectionCellRegisterDic:(BOOL)isFun;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Message Model Factory

/// 同步：根据消息构造消息模型
/// @param message V2NIM 消息对象
+ (MessageContentModel *)modelFromMessage:(V2NIMMessage *)message;

/// 异步：根据消息构造消息模型（通知消息会先查用户信息）
/// @param message    V2NIM 消息对象
/// @param completion 完成回调
+ (void)modelFromMessage:(V2NIMMessage *)message completion:(void (^)(MessageContentModel *model))completion;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Image URL Extraction

/// 从消息列表中提取所有图片 URL，并返回当前图片下标
/// @param current  当前图片消息模型（nil 时 index = 0）
/// @param messages 全部消息模型列表
/// @param indexOut 输出：current 在图片列表中的下标
/// @return         图片 URL / 本地路径列表
+ (NSArray<NSString *> *)getUrls:(nullable MessageContentModel *)current
                        messages:(NSArray<MessageContentModel *> *)messages
                     currentIndex:(NSInteger *)indexOut;

/// 兼容旧的 Swift 风格 API，将图片数组通过 out 参数返回
+ (void)getUrlsWithModel:(nullable MessageContentModel *)current
                messages:(NSArray<MessageContentModel *> *)messages
             currentIndex:(NSInteger *)indexOut
               showImages:(NSArray<NSString *> * _Nullable * _Nullable)showImagesOut;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Time Separator

/// 为消息体插入时间分隔文案（超过 5 分钟才插入）
/// @param model     当前消息模型
/// @param lastModel 上一条消息模型（nil = 列表第一条）
+ (void)addTimeMessage:(MessageContentModel *)model lastModel:(nullable MessageContentModel *)lastModel;

/// Swift `String.stringFromDate(date:)` 的 OC 等价实现
+ (NSString *)ne_stringFromDate:(NSDate *)date;

/// Swift `String.stringFromDate(date:showHM:)` 的 OC 等价实现
+ (NSString *)ne_stringFromDate:(NSDate *)date showHM:(BOOL)showHM;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Display Text

/// 获取消息的外显文案（会话列表 / 通知等场景）
/// @param message V2NIM 消息对象
+ (NSString *)contentOfMessage:(nullable V2NIMMessage *)message;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - AI Error Message

/// 将 AI 错误码转换为可展示的字符串
/// @param errorCode 错误码
+ (nullable NSString *)getAIErrorMessage:(NSInteger)errorCode;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Forward Message Construction

/// 移除消息扩展字段中的回复信息和 @ 信息
/// @param forwardMessage 要转发的消息
+ (void)clearForwardAtMark:(V2NIMMessage *)forwardMessage;

/// 移除转发消息中的回复引用和 @ 信息
/// @param forwardMessage 要转发的消息
+ (void)clearForwardReplyMark:(V2NIMMessage *)forwardMessage;

/// 构建合并转发消息的 header JSON 字符串
/// @param messageCount 转发消息数量
+ (NSString *)buildHeader:(NSInteger)messageCount;

/// 构建合并转发消息的 body 及摘要信息
/// @param messages   要转发的消息数组
/// @param completion 完成回调：bodyStr / abstracts（每条摘要 dict）
+ (void)buildBody:(NSArray<V2NIMMessage *> *)messages
       completion:(void (^)(NSString *body, NSArray<NSDictionary<NSString *, id> *> *abstracts))completion;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Server Extension Parsing

/// 将消息的 serverExtension JSON 字符串解析为字典
/// @param message V2NIM 消息对象
+ (nullable NSDictionary<NSString *, id> *)getMessageServerExtension:(V2NIMMessage *)message;

/// 判断消息是否已撤回
/// @param message V2NIM 消息对象
+ (BOOL)isRevokeMessage:(nullable V2NIMMessage *)message;

/// 获取消息撤回前的内容（用于重新编辑）
/// @param model 消息模型
+ (nullable NSString *)getRevokeMessageContent:(MessageContentModel *)model;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Reply Message Handling

/// 生成回复信息键值对
/// @param messageRefer 被回复的消息 refer
+ (NSDictionary<NSString *, id> *)createReplyDic:(V2NIMMessageRefer *)messageRefer;

/// 从键值对还原回复 refer
/// @param params 回复信息键值对（可为 nil）
+ (V2NIMMessageRefer *)createMessageRefer:(nullable NSDictionary<NSString *, id> *)params;

/// 从消息 serverExtension 中读取回复信息字典
/// @param message V2NIM 消息对象
+ (nullable NSDictionary<NSString *, id> *)getReplyDictionary:(V2NIMMessage *)message;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - Sender Utilities

/// 判断是否为数字人发送的消息
/// @param message V2NIM 消息对象
+ (BOOL)isAISender:(nullable V2NIMMessage *)message;

/// 获取消息实际发送者 id（数字人回复时返回数字人 accountId）
/// @param message V2NIM 消息对象
+ (nullable NSString *)getSenderId:(nullable V2NIMMessage *)message;

/// 判断消息是否是自己发送的
/// @param message V2NIM 消息对象
+ (BOOL)isSelf:(nullable V2NIMMessage *)message;

/// 从各级缓存获取用户信息
/// @param accountId 用户 id
+ (nullable NEUserWithFriend *)getUserFromCache:(NSString *)accountId;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - @ and Keyword Highlighting

/// 解析消息中的 @ 信息并对富文本着色
/// @param message      V2NIM 消息对象（可为 nil）
/// @param attributeStr 待处理的富文本（可为 nil）
/// @return 着色后的富文本（入参为 nil 时返回 nil）
+ (nullable NSMutableAttributedString *)loadAtInMessage:(nullable V2NIMMessage *)message
                                           attributeStr:(nullable NSMutableAttributedString *)attributeStr;

/// 对富文本中的关键词着色
/// @param message      V2NIM 消息对象（可为 nil）
/// @param attributeStr 待处理的富文本（可为 nil）
/// @param keyword      关键词（正则）
/// @param themeColor   高亮颜色
/// @return 着色后的富文本
+ (nullable NSMutableAttributedString *)loadKeywordInMessage:(nullable V2NIMMessage *)message
                                                attributeStr:(nullable NSMutableAttributedString *)attributeStr
                                                     keyword:(NSString *)keyword
                                                  themeColor:(UIColor *)themeColor;

// ─────────────────────────────────────────────────────────────────────
#pragma mark - File Utilities

/// 计算文件 MD5 值
/// @param fileURL 文件 URL
+ (nullable NSString *)getFileChecksum:(NSURL *)fileURL;

/// Compatibility wrapper for Swift-style `getFileChecksum(fileURL:)`.
+ (nullable NSString *)getFileChecksumWithFileURL:(NSURL *)fileURL;

/// 构造消息附件的本地文件路径
/// @param message V2NIM 消息对象（可为 nil）
+ (NSString *)createFilePath:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
