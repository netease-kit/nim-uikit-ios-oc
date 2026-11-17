// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "P2PChatViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TopicChatViewModelOutput <NSObject>
- (void)onTopicChanged:(V2NIMTopic *)topic;
@optional
- (void)onTopicTipMessage:(NSString *)text;
- (void)onCurrentTopicRemoved;
@end

@interface TopicChatViewModel : P2PChatViewModel <NETopicListener>

@property(nonatomic, strong, readonly) TopicRepo *topicRepo;
@property(nonatomic, strong, nullable) V2NIMTopic *topic;
@property(nonatomic, copy, readonly) NSString *sessionName;
@property(nonatomic, assign, readonly) BOOL supportsLastReadPosition;

- (instancetype)initWithConversationId:(NSString *)conversationId
                                 anchor:(nullable V2NIMMessage *)anchor
                                  topic:(nullable V2NIMTopic *)topic
                            sessionName:(NSString *)sessionName NS_DESIGNATED_INITIALIZER;
- (NSString *)currentTitle;
- (void)loadTopicData:(void (^)(NSError *_Nullable error, NSInteger count,
                                NSInteger reloadIndex, NSInteger removeIndex))completion;
- (void)getTopicHistoryWithOrder:(V2NIMQueryDirection)order
                   anchorMessage:(nullable V2NIMMessage *)anchorMessage
                                :(void (^)(NSError *_Nullable error, NSInteger count,
                                          NSArray<V2NIMMessage *> *messages))completion;
- (void)loadData:(void (^)(NSError *_Nullable error, NSInteger count,
                           NSInteger reloadIndex, NSInteger removeIndex))completion;
- (void)dropDownRemoteRefresh:(void (^)(NSError *_Nullable error, NSInteger count,
                                        NSArray<V2NIMMessage *> *messages))completion;
- (void)pullRemoteRefresh:(void (^)(NSError *_Nullable error, NSInteger count,
                                    NSArray<V2NIMMessage *> *messages))completion;
- (void)sendMessageWithMessage:(V2NIMMessage *)message
                conversationId:(nullable NSString *)conversationId
                         params:(nullable V2NIMSendMessageParams *)params
                               :(void (^)(V2NIMMessage *_Nullable message, NSError *_Nullable error,
                                         NSUInteger progress))completion;
- (void)replyMessageWithThreadWithMessage:(V2NIMMessage *)message
                              replyMessage:(V2NIMMessage *)replyMessage
                               aiUserAccid:(nullable NSString *)aiUserAccid
                                          :(void (^)(V2NIMMessage *_Nullable message,
                                                    NSError *_Nullable error))completion;
- (nullable id<MessageModel>)getReplyMessageWithMessage:(V2NIMMessage *)message;
- (void)getReplyMessageWithMessage:(V2NIMMessage *)message
                                   :(void (^)(id<MessageModel> _Nullable model))completion;
- (void)revokeMessageWithMessage:(V2NIMMessage *)message
                                 :(void (^)(NSError *_Nullable error))completion;
- (BOOL)shouldShowThreadReply:(nullable V2NIMMessage *)message;
- (void)revokeMessageUpdateUI:(V2NIMMessage *)message;
- (void)onSendMessage:(V2NIMMessage *)message;
- (void)sendMessageFailed:(V2NIMMessage *)message :(NSError *)error;
- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages;
- (void)onReceiveMessagesModified:(NSArray<V2NIMMessage *> *)messages;
- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)notifications;
- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)notifications;
- (void)onTopicAdded:(V2NIMTopic *)topic;
- (void)onTopicsRemoved:(NSArray<V2NIMTopicRefer *> *)topics;
- (void)onTopicUpdated:(V2NIMTopic *)topic;
- (void)updateTopicName:(NSString *)topicName
                       :(void (^)(V2NIMTopic *_Nullable topic, NSError *_Nullable error))completion;
- (void)removeCurrentTopic:(void (^)(NSError *_Nullable error))completion;

- (instancetype)initWithConversationId:(NSString *)conversationId NS_UNAVAILABLE;
- (instancetype)initWithConversationId:(NSString *)conversationId
                                 anchor:(nullable V2NIMMessage *)anchor NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
