// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BotSubSessionListViewModelDelegate <NSObject>
- (void)onBotSubSessionListReload;
@end

@interface BotSubSessionItem : NSObject

@property(nonatomic, strong, readonly) V2NIMTopic *topic;
@property(nonatomic, copy, nullable) NSString *summary;
@property(nonatomic, assign) NSTimeInterval updateTime;
@property(nonatomic, assign) BOOL hasUnread;

- (instancetype)initWithTopic:(V2NIMTopic *)topic
                      summary:(nullable NSString *)summary
                   updateTime:(NSTimeInterval)updateTime
                    hasUnread:(BOOL)hasUnread NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface BotSubSessionListViewModel : NSObject <NEChatListener, NEConversationListener,
                                                  NELocalConversationListener, NETopicListener>

@property(nonatomic, weak, nullable) id<BotSubSessionListViewModelDelegate> delegate;
@property(nonatomic, strong, readonly) TopicRepo *topicRepo;
@property(nonatomic, strong, readonly) ChatRepo *chatRepo;
@property(nonatomic, strong, readonly) ConversationRepo *conversationRepo;
@property(nonatomic, strong, readonly) LocalConversationRepo *localConversationRepo;
@property(nonatomic, copy) NSArray<V2NIMTopic *> *topicList;
@property(nonatomic, copy) NSArray<V2NIMTopic *> *displayTopicList;
@property(nonatomic, copy) NSDictionary<NSNumber *, NSString *> *topicSummaryMap;
@property(nonatomic, copy) NSDictionary<NSNumber *, NSNumber *> *topicSummaryTimeMap;
@property(nonatomic, copy) NSDictionary<NSNumber *, NSNumber *> *topicLatestMessageFromSelfMap;
@property(nonatomic, copy) NSString *conversationId;
@property(nonatomic, copy) NSString *sessionId;
@property(nonatomic, copy) NSString *keyword;
@property(nonatomic, assign) NSTimeInterval conversationReadTime;

- (void)loadDataWithConversationId:(NSString *)conversationId
                         sessionId:(NSString *)sessionId
                                  :(void (^)(NSError *_Nullable error))completion;
- (nullable BotSubSessionItem *)itemAtIndex:(NSInteger)index;
- (void)updateKeyword:(NSString *)keyword;
- (void)refreshListStateIfNeeded;
- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages;
- (void)onSendMessage:(V2NIMMessage *)message;
- (void)sendMessageFailed:(V2NIMMessage *)message :(NSError *)error;
- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)notifications;
- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)notifications;
- (void)onReceiveMessagesModified:(NSArray<V2NIMMessage *> *)messages;
- (void)onClearHistoryNotifications:(NSArray<V2NIMClearHistoryNotification *> *)notifications;
- (void)applyFilter;
- (void)loadSummaries;
- (void)loadSummariesFor:(NSArray<V2NIMTopic *> *)topics;
- (NSString *)summaryTextFor:(nullable V2NIMMessage *)message;
- (NSString *)topicDisplayName:(V2NIMTopic *)topic;
- (void)markTopicRead:(nullable V2NIMTopic *)topic;
- (void)markAllCurrentTopicsRead;
- (BOOL)hasUnreadWithTopic:(V2NIMTopic *)topic;
- (void)clearConversationUnread;
- (void)refreshConversationReadTime;
- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount;
- (void)onLocalTotalUnreadCountChanged:(NSInteger)unreadCount;
- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime;
- (void)onLocalConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime;
- (void)updateTopicNameWithTopic:(V2NIMTopic *)topic
                       topicName:(NSString *)topicName
                                :(void (^)(V2NIMTopic *_Nullable topic, NSError *_Nullable error))completion;
- (void)removeTopicWithTopic:(V2NIMTopic *)topic
                            :(void (^)(NSError *_Nullable error))completion;
- (void)onTopicAdded:(V2NIMTopic *)topic;
- (void)onTopicsRemoved:(NSArray<V2NIMTopicRefer *> *)topics;
- (void)onTopicUpdated:(V2NIMTopic *)topic;

@end

NS_ASSUME_NONNULL_END
