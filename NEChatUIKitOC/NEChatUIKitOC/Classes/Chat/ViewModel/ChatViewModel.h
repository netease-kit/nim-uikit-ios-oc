// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>
#import "NEChatUIConstant.h"
#import "NEChatMessageDeletionResult.h"
#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

@class MessageTextModel;
@class MessageReactionManager;
@class NELastReadPositionSnapshot;

/// ChatViewModel 特有的 delegate 协议
@protocol ChatViewModelDelegate <NSObject>

@optional
/// 显示错误浮窗
- (void)showErrorToast:(nullable NSError *)error defaultToast:(nullable NSString *)defaultToast;

/// 消息重新加载
- (void)dataReload;

/// 获取消息模型
- (void)getMessageModel:(id<MessageModel>)model;

/// 多选列表变更
- (void)selectedMessagesChanged:(NSInteger)count;

/// 翻译结果回调
- (void)didTranslateResult:(NSString *)content;

/// Automatic message translation completed.
- (void)autoTranslationDidFinish:(NSInteger)index;

/// 最早未读消息入口状态变化
- (void)lastReadPositionStateChanged;

@required
/// 消息发送中
- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index;

/// 消息发送完成
- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index;

/// 消息重发成功
- (void)onResendSuccess:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndexPath;

/// 收到消息
- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs;

/// 消息加载更多完成
- (void)onLoadMoreWithMessage:(NSArray<NSIndexPath *> *)indexs;

/// 消息更新回调
- (void)onModefiedMessage:(NSIndexPath *)index;

@optional

/// Reaction 更新回调（由聊天控制器批量合并刷新）
- (void)onReactionModifiedMessage:(NSIndexPath *)index;

/// 首屏消息附加信息加载完成
- (void)initialMessageDetailsDidLoad;

@required

/// 删除消息或收到删除消息回调
- (void)onDeleteMessage:(NSArray<V2NIMMessage *> *)messages
          deleteIndexs:(NSArray<NSIndexPath *> *)deleteIndexs
           reloadIndex:(NSArray<NSIndexPath *> *)reloadIndex;

/// 撤回消息或收到撤回消息回调
- (void)onRevokeMessage:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs;

/// 消息状态变更
- (void)onMessageStatusChange:(nullable V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs;

/// 单聊对方正在输入中
- (void)remoteUserEditing;

/// 单聊对方停止输入
- (void)remoteUserEndEditing;

/// 单聊对方在线状态变更
- (void)remoteUserOnlineChanged;

/// 消息列表重新加载
- (void)tableViewReload;

/// 设置消息置顶内容
- (void)setTopValueWithName:(nullable NSString *)name
                    content:(nullable NSString *)content
                        url:(nullable NSString *)url
                    isVideo:(BOOL)isVideo
                  hideClose:(BOOL)hideClose;

/// 更新消息置顶浮窗中的昵称
- (void)updateTopName:(nullable NSString *)name;

@end

/// 聊天 ViewModel 基类
@interface ChatViewModel : NSObject <NEChatListener, V2NIMAIListener>

@property (nonatomic, copy, readonly) NSString *conversationId;

@property (nonatomic, strong) NSMutableArray<id<MessageModel>> *messages;
@property (nonatomic, strong) NSMutableArray<NSString *> *messageClientIds;
@property (nonatomic, weak, nullable) id<ChatViewModelDelegate> delegate;

/// 多选选中的消息（有 didSet，改变时通知 delegate）
@property (nonatomic, strong) NSMutableArray<V2NIMMessage *> *selectedMessages;

@property (nonatomic, strong, nullable) MessageContentModel *operationModel;
@property (nonatomic, strong, nullable) V2NIMMessage *topMessage;
@property (nonatomic, assign) BOOL isReplying;
@property (nonatomic, assign) NSInteger messagPageNum;
@property (nonatomic, assign) NSInteger aiMessagNum;
@property (nonatomic, strong, nullable) V2NIMMessage *anchor;
@property (nonatomic, assign) BOOL isHistoryChat;
@property (nonatomic, strong) NSMutableSet<NSString *> *deletingMsgDic;

/// AI 翻译 User
@property (nonatomic, strong, nullable) V2NIMAIUser *translationAIUser;
/// 翻译 request id 记录
@property (nonatomic, copy) NSString *translationLanguageRequestId;
/// 数字人请求成功 code
@property (nonatomic, assign) NSInteger aiUserRequestSuccess;
/// 网络断开标志
@property (nonatomic, assign) BOOL networkBroken;
/// Per-chat QuickComment state owner. Presentation surfaces consume its immutable snapshots.
@property (nonatomic, strong, nullable, readonly) MessageReactionManager *reactionManager;
@property (nonatomic, strong, nullable, readonly) NELastReadPositionSnapshot *lastReadPositionSnapshot;
@property (nonatomic, assign, readonly) BOOL lastReadPositionLocating;
@property (nonatomic, assign, readonly) BOOL lastReadPositionSuppressed;

/// 初始化
- (instancetype)init;

/// 带 conversationId 初始化
- (instancetype)initWithConversationId:(NSString *)conversationId;

/// 带 conversationId 和锚点消息初始化
- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor;

/// 添加监听
- (void)addListener;
/// Restart / stop the QuickComment listener with the visible chat page.
- (void)startReactionManager;
- (void)stopReactionManager;
- (void)toggleReactionMessage:(V2NIMMessage *)message
                         index:(NSInteger)index
                    completion:(void (^)(V2NIMError *_Nullable error))completion;
- (nullable id)reactionEmojiProvider;

/// 获取 AI 用户列表
- (void)getAIUserList;

/// 清空当前会话的未读数
- (void)clearUnreadCount;
/// Freeze the conversation read time before the existing unread-clearing flow.
- (void)enterConversation;
/// Invalidate pending last-read callbacks when the chat page leaves.
- (void)leaveConversation;
/// Resolve the first message after the frozen read time.
- (void)locateLastReadPosition:(void (^)(V2NIMMessage *_Nullable message))completion;
/// Consume or restore the last-read entry after the controller verifies visibility.
- (void)completeLastReadPositionLocation:(BOOL)success;
/// Reconcile the entry with currently visible message identifiers.
- (void)updateLastReadPositionVisibility:(NSSet<NSString *> *)visibleMessageIdentifiers;

/// 加载数据
- (void)loadData:(void (^)(NSError *_Nullable error, NSInteger count, NSInteger newEnd, NSInteger anchorIndex))completion;

/// 查询回复
- (void)loadReply:(id<MessageModel>)model completion:(void (^)(void))completion;

/// 加载消息的更多信息（回复、标记、发送者信息）
- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray;

/// 更新消息发送者的信息
- (void)updateMessageInfo:(nullable NSString *)accid;

/// 插入消息
- (NSInteger)insertToMessages:(id<MessageModel>)newModel;

/// 查询历史消息
- (void)getHistoryMessage:(V2NIMQueryDirection)order
                  message:(nullable V2NIMMessage *)message
               completion:(void (^)(NSError *_Nullable error, NSInteger count, NSArray<V2NIMMessage *> *messages))completion;

/// 下拉获取历史消息
- (void)dropDownRemoteRefresh:(void (^)(NSError *_Nullable error, NSInteger count, NSArray<V2NIMMessage *> *messages))completion;

/// 上拉获取最新消息
- (void)pullRemoteRefresh:(void (^)(NSError *_Nullable error, NSInteger count, NSArray<V2NIMMessage *> *messages))completion;

/// 下载语音消息附件
- (void)downloadAudioFile:(NSArray<id<MessageModel>> *)models;

/// 加载置顶消息
- (void)loadTopMessage;

/// 发送消息
- (void)sendMessage:(V2NIMMessage *)message
     conversationId:(nullable NSString *)conversationId
             params:(nullable V2NIMSendMessageParams *)params
         completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error, NSUInteger progress))completion;

/// 反垃圾检查
- (void)checkAntiSpam:(nullable V2NIMSendMessageResult *)result;

/// 获取请求大模型的内容
- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type;

/// 获取上下文内容
- (nullable NSArray<V2NIMAIModelCallMessage *> *)getAIMessages;

/// 获取消息发送参数
- (V2NIMSendMessageParams *)getSendMessageParams:(nullable NSString *)aiUserAccid message:(V2NIMMessage *)message;

/// 获取回复消息发送参数
- (V2NIMSendMessageParams *)getReplyMessageParams:(nullable NSString *)aiUserAccid
                                     replyMessage:(V2NIMMessage *)replyMessage
                                          message:(V2NIMMessage *)message;

/// 获取转发消息发送参数
- (V2NIMSendMessageParams *)getForwardMessageParams:(nullable NSString *)aiUserAccid forwardMessage:(V2NIMMessage *)forwardMessage;

/// 发送文本消息
- (void)sendTextMessage:(NSString *)text
         conversationId:(nullable NSString *)conversationId
              remoteExt:(nullable NSDictionary *)remoteExt
           aiUserAccid:(nullable NSString *)aiUserAccid
            completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error))completion;
/// 兼容旧 OC 转换产物
- (void)sendTextMessage:(NSString *)text
              remoteExt:(nullable NSDictionary *)remoteExt
           aiUserAccid:(nullable NSString *)aiUserAccid
            completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error))completion;

/// 发送换行消息
- (void)sendRichTextMessage:(V2NIMMessage *)message
                      title:(nullable NSString *)title
                       body:(nullable NSString *)body
               aiUserAccid:(nullable NSString *)aiUserAccid
                completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error))completion;

/// 发送语音消息
- (void)sendAudioMessage:(NSString *)filePath
          conversationId:(nullable NSString *)conversationId
              completion:(void (^)(NSError *_Nullable error))completion;

/// 发送图片消息
- (void)sendImageMessage:(NSString *)path
                    name:(nullable NSString *)name
                   width:(int32_t)width
                  height:(int32_t)height
          conversationId:(nullable NSString *)conversationId
              completion:(void (^)(NSError *_Nullable error))completion;

/// 发送视频消息
- (void)sendVideoMessage:(NSURL *)url
                    name:(nullable NSString *)name
                   width:(int32_t)width
                  height:(int32_t)height
                duration:(int32_t)duration
          conversationId:(nullable NSString *)conversationId
              completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error, NSUInteger progress))completion;

/// 将视频格式转为 MP4
- (void)convertVideoToMP4:(NSURL *)videoURL completion:(void (^)(NSURL *_Nullable url, NSError *_Nullable error))completion;

/// 发送地理位置消息
- (void)sendLocationMessage:(ChatLocaitonModel *)model
             conversationId:(nullable NSString *)conversationId
                 completion:(void (^)(NSError *_Nullable error))completion;
/// 兼容旧 OC 转换产物
- (void)sendLocationMessage:(ChatLocaitonModel *)model
                 completion:(void (^)(NSError *_Nullable error))completion;

/// 发送文件消息
- (void)sendFileMessage:(NSString *)filePath
            displayName:(nullable NSString *)displayName
         conversationId:(nullable NSString *)conversationId
             completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error, NSUInteger progress))completion;

/// 发送自定义消息
- (void)sendCustomMessage:(NSString *)text
            rawAttachment:(NSString *)rawAttachment
           conversationId:(nullable NSString *)conversationId
               completion:(void (^)(NSError *_Nullable error))completion;

/// 本地插入文本消息
- (void)insertTextMessage:(NSString *)text conversationId:(NSString *)conversationId senderId:(nullable NSString *)senderId;

/// 本地插入提示消息
- (void)insertTipMessage:(NSString *)text
              createTime:(nullable NSNumber *)createTime
          conversationId:(nullable NSString *)conversationId
                senderId:(nullable NSString *)senderId;

/// 发送消息已读回执
- (void)markRead:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable error))completion;
/// 兼容旧 OC 转换产物
- (void)markReadMessages:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable error))completion;

/// 获取消息已读未读回执
- (void)getMessageReceipts:(NSArray<V2NIMMessage *> *)messages
                completion:(void (^)(NSArray<NSIndexPath *> *reloadIndexs, NSError *_Nullable error))completion;

/// 删除消息
- (void)deleteMessage:(void (^)(NSError *_Nullable error))completion;

/// 批量删除消息
- (void)deleteMessages:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable error))completion;

/// 回复消息（不使用 thread）
- (void)replyMessageWithoutThread:(V2NIMMessage *)message
                     replyMessage:(V2NIMMessage *)replyMessage
                      aiUserAccid:(nullable NSString *)aiUserAccid
                       completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error))completion;

/// 回复消息（使用 thread）
- (void)replyMessageWithThread:(V2NIMMessage *)message
                  replyMessage:(V2NIMMessage *)replyMessage
                   aiUserAccid:(nullable NSString *)aiUserAccid
                    completion:(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error))completion;

/// 撤回消息
- (void)revokeMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable error))completion;

/// 获取用户展示名称
- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias;

/// 加载用户展示名称
- (void)loadShowName:(NSArray<NSString *> *)accountIds teamId:(nullable NSString *)teamId completion:(void (^)(void))completion;

/// 获取消息所支持的操作列表
- (nullable NSMutableArray<OperationItem *> *)avalibleOperationsForMessage:(nullable MessageContentModel *)model;

- (void)performTranslation:(MessageTextModel *)model
            targetLanguage:(nullable NSString *)targetLanguage
                 completion:(void (^)(NSInteger index, NSError *_Nullable error))completion;
- (void)hideTranslation:(MessageTextModel *)model completion:(void (^)(NSInteger index))completion;
- (void)autoTranslateIfNeeded:(MessageTextModel *)model;
- (void)autoTranslateVisibleHistory:(NSArray<id<MessageModel>> *)visibleModels;

/// 消息列表添加时间
- (void)addTimeForHistoryMessage:(BOOL)forward;

/// 构建消息UI显示model（带回调）
- (void)modelFromMessage:(V2NIMMessage *)message completion:(void (^)(id<MessageModel> model))completion;

/// 构建消息UI显示model（同步）
- (id<MessageModel>)modelFromMessage:(V2NIMMessage *)message;

/// 查找回复消息（不进行远端拉取）
- (nullable id<MessageModel>)getReplyMessageFromLocal:(V2NIMMessage *)message;

/// Swift UIKit 公开选择子的等价入口。
- (nullable id<MessageModel>)getReplyMessageWithMessage:(V2NIMMessage *)message;

/// 查找回复消息（可远端查询）
- (void)getReplyMessage:(V2NIMMessage *)message completion:(void (^)(id<MessageModel> _Nullable model))completion;

/// Swift UIKit 公开选择子的等价入口。
- (void)getReplyMessageWithMessage:(V2NIMMessage *)message
                                  :(void (^)(id<MessageModel> _Nullable model))completion;

- (BOOL)shouldShowThreadReply:(nullable V2NIMMessage *)message;

/// 删除消息模型，保留历史字典键 deleteIndexs / reloadIndexs。
- (NSDictionary<NSString *, NSArray<NSNumber *> *> *)deleteMessageModel:(V2NIMMessage *)message;

/// 与 Swift UIKit 对齐的类型安全结果入口。
- (NEChatMessageDeletionResult *)deleteMessageResultForMessage:(V2NIMMessage *)message;

/// 删除消息更新UI
- (void)deleteMessageUpdateUI:(NSArray<V2NIMMessage *> *)messages;

/// 删除消息更新UI，messageClientIds 同时包含未加载消息的 ID。
- (void)deleteMessageUpdateUI:(NSArray<V2NIMMessage *> *)messages
             messageClientIds:(NSArray<NSString *> *)messageClientIds;

/// 撤回消息更新UI
- (void)revokeMessageUpdateUI:(V2NIMMessage *)message;

/// 下载附件
- (void)downLoad:(NSString *)urlString
        filePath:(NSString *)filePath
        progress:(nullable void (^)(NSUInteger progress))progress
      completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion;

/// 转发消息
- (void)forwardMessages:(NSArray<NSString *> *)conversationIds
         isMultiForward:(BOOL)isMultiForward
                  depth:(NSInteger)depth
                comment:(nullable NSString *)comment
             completion:(void (^)(NSError *_Nullable error))completion;

/// Sends translated text directly to each selected conversation, matching the
/// Swift translation-forward path instead of treating the text as a forwarded
/// source message.
- (void)sendTranslationForwardMessage:(NSString *)translatedText
                               comment:(nullable NSString *)comment
                       conversationIds:(NSArray<NSString *> *)conversationIds
                            completion:(void (^)(NSError *_Nullable error))completion;

/// 逐条转发消息
- (void)forwardMessage:(NSArray<V2NIMMessage *> *)forwardMessages
        conversationIds:(NSArray<NSString *> *)conversationIds
                comment:(nullable NSString *)comment
             completion:(void (^)(NSError *_Nullable error))completion;

/// 合并转发消息
- (void)forwardMultiMessage:(NSArray<V2NIMMessage *> *)forwardMessages
             conversationIds:(NSArray<NSString *> *)conversationIds
                       depth:(NSInteger)depth
                     comment:(nullable NSString *)comment
                  completion:(void (^)(NSError *_Nullable error))completion;

/// 标记消息
- (void)addPinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable error, NSInteger index))completion;

/// 取消消息标记
- (void)removePinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable error, NSInteger index))completion;

/// 置顶消息
- (void)topMessage:(void (^)(NSError *_Nullable error))completion;

/// 取消置顶消息
- (void)untopMessage:(void (^)(NSError *_Nullable error))completion;

/// 兼容旧 OC 转换产物
- (void)topMessageAction:(void (^)(NSError *_Nullable error))completion;

/// 兼容旧 OC 转换产物
- (void)untopMessageAction:(void (^)(NSError *_Nullable error))completion;

/// 收藏消息
- (void)collectMessage:(MessageContentModel *)model conversationName:(NSString *)conversationName completion:(void (^)(NSError *_Nullable error))completion;

/// 语音转文字
- (void)voiceToText:(MessageContentModel *)model completion:(void (^)(NSString *_Nullable text, NSError *_Nullable error))completion;

/// 停止 AI Stream 消息
- (void)stopAIStreamMessage:(V2NIMMessage *)message;

/// 重新生成 AI 消息
- (void)regenAIMessage:(V2NIMMessage *)message;

/// 获取听筒模式
- (BOOL)getHandSetEnable;

/// 设置听筒模式
- (void)setHandSetEnable:(BOOL)ear;

/// 移除缓存数据的标记状态
- (NSInteger)removeLocalPinMessage:(V2NIMMessage *)message;

/// 消息即将发送
- (void)sendingMsg:(V2NIMMessage *)message;

/// 消息发送完成
- (void)sendMsgSuccess:(V2NIMMessage *)message;

/// 消息发送失败
- (void)sendMsgFailed:(V2NIMMessage *)message error:(nullable NSError *)error;

/// 交换消息位置
- (void)exchangeMessageModel:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/// 数字人回复的消息错误码映射
- (void)setErrorText:(nullable V2NIMMessage *)message;

/// 更新消息接口
- (void)modifyMessage:(V2NIMMessage *)message
               params:(V2NIMModifyMessageParams *)params
           completion:(void (^)(V2NIMModifyMessageResult *_Nullable result, NSError *_Nullable error))completion;

/// 更新消息UI
- (void)modifyMessageUpdateUI:(V2NIMMessage *)modifyMessage;

/// 翻译
- (void)translateLanguage:(NSString *)sourceText
           targetLanguage:(NSString *)targetLanguage
               completion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
