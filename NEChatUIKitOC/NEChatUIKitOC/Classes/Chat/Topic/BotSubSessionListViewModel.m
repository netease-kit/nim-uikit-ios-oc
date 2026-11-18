// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BotSubSessionListViewModel.h"

#import "ChatMessageHelper.h"
#import <NEChatKit/NEChatKit.h>

static NSString *NEBotPrefixByComposedCharacters(NSString *value, NSUInteger limit) {
  if (![value isKindOfClass:[NSString class]] || value.length == 0 || limit == 0) {
    return @"";
  }
  __block NSUInteger count = 0;
  __block NSUInteger end = 0;
  [value enumerateSubstringsInRange:NSMakeRange(0, value.length)
                           options:NSStringEnumerationByComposedCharacterSequences
                        usingBlock:^(NSString *substring, NSRange substringRange,
                                     NSRange enclosingRange, BOOL *stop) {
    count += 1;
    end = NSMaxRange(substringRange);
    if (count >= limit) {
      *stop = YES;
    }
  }];
  return end < value.length ? [value substringToIndex:end] : value;
}

static NSTimeInterval NEBotNormalizedTimestamp(NSTimeInterval time) {
  return time > 10000000000.0 ? time / 1000.0 : time;
}

static NSString *NEBotConversationSenderId(NSString *conversationId) {
  if (![conversationId isKindOfClass:[NSString class]]) {
    return nil;
  }
  NSArray<NSString *> *parts = [conversationId componentsSeparatedByString:@"|"];
  return parts.count == 3 && parts.firstObject.length > 0 ? parts.firstObject : nil;
}

static V2NIMMessage *NEBotLatestMessage(NSArray<V2NIMMessage *> *messages) {
  V2NIMMessage *latest = nil;
  for (id value in messages ?: @[]) {
    if (![value isKindOfClass:[V2NIMMessage class]]) {
      continue;
    }
    V2NIMMessage *message = value;
    if (!latest || message.createTime > latest.createTime) {
      latest = message;
    }
  }
  return latest;
}

@implementation BotSubSessionItem

- (instancetype)initWithTopic:(V2NIMTopic *)topic
                      summary:(NSString *)summary
                   updateTime:(NSTimeInterval)updateTime
                    hasUnread:(BOOL)hasUnread {
  self = [super init];
  if (self) {
    _topic = topic;
    _summary = [summary copy];
    _updateTime = updateTime;
    _hasUnread = hasUnread;
  }
  return self;
}

@end

@interface NEBotSummaryLoadContext : NSObject

@property(nonatomic, copy) NSArray<V2NIMTopic *> *topics;
@property(nonatomic, strong) NSLock *lock;
@property(nonatomic, assign) NSUInteger nextIndex;
@property(nonatomic, assign) NSUInteger requestVersion;

- (nullable V2NIMTopic *)nextTopic;

@end

@implementation NEBotSummaryLoadContext

- (instancetype)init {
  self = [super init];
  if (self) {
    _topics = @[];
    _lock = [[NSLock alloc] init];
  }
  return self;
}

- (V2NIMTopic *)nextTopic {
  [self.lock lock];
  V2NIMTopic *topic = nil;
  if (self.nextIndex < self.topics.count) {
    topic = self.topics[self.nextIndex];
    self.nextIndex += 1;
  }
  [self.lock unlock];
  return topic;
}

@end

@interface BotSubSessionListViewModel ()

@property(nonatomic, strong, readwrite) TopicRepo *topicRepo;
@property(nonatomic, strong, readwrite) ChatRepo *chatRepo;
@property(nonatomic, strong, readwrite) ConversationRepo *conversationRepo;
@property(nonatomic, strong, readwrite) LocalConversationRepo *localConversationRepo;
@property(nonatomic, assign) NSUInteger summaryRequestVersion;

@end

@implementation BotSubSessionListViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _topicRepo = [TopicRepo shared];
    _chatRepo = [ChatRepo shared];
    _conversationRepo = [ConversationRepo shared];
    _localConversationRepo = [LocalConversationRepo shared];
    _topicList = @[];
    _displayTopicList = @[];
    _topicSummaryMap = @{};
    _topicSummaryTimeMap = @{};
    _topicLatestMessageFromSelfMap = @{};
    _conversationId = @"";
    _sessionId = @"";
    _keyword = @"";
    [_topicRepo addTopicListener:self];
    [_chatRepo addChatListener:self];
    [_conversationRepo addConversationListener:self];
    [_localConversationRepo addLocalConversationListener:self];
  }
  return self;
}

- (void)dealloc {
  [_topicRepo removeTopicListener:self];
  [_chatRepo removeChatListener:self];
  [_conversationRepo removeConversationListener:self];
  [_localConversationRepo removeLocalConversationListener:self];
}

- (void)loadDataWithConversationId:(NSString *)conversationId
                         sessionId:(NSString *)sessionId
                                  :(void (^)(NSError *_Nullable))completion {
  self.conversationId = conversationId ?: @"";
  self.sessionId = sessionId ?: @"";
  __weak typeof(self) weakSelf = self;
  [self loadAllTopicsWithNextToken:nil
                       accumulator:@[]
                        completion:^(NSArray<V2NIMTopic *> *topics, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      completion(error);
      return;
    }
    self.topicList = error ? @[] : [self sortedTopics:topics];
    [self refreshConversationReadTime];
    [self loadSummariesInvalidatingPending:YES topics:self.topicList];
    [self applyFilter];
    [self.delegate onBotSubSessionListReload];
    completion(error);
  }];
}

- (BotSubSessionItem *)itemAtIndex:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)self.displayTopicList.count) {
    return nil;
  }
  V2NIMTopic *topic = self.displayTopicList[index];
  NSNumber *summaryTime = self.topicSummaryTimeMap[@(topic.topicId)];
  NSTimeInterval updateTime = summaryTime ? summaryTime.doubleValue
                                          : NEBotNormalizedTimestamp((NSTimeInterval)topic.updateTime);
  return [[BotSubSessionItem alloc] initWithTopic:topic
                                         summary:self.topicSummaryMap[@(topic.topicId)]
                                      updateTime:updateTime
                                       hasUnread:[self hasUnreadWithTopic:topic]];
}

- (void)updateKeyword:(NSString *)keyword {
  self.keyword = [[keyword ?: @"" stringByTrimmingCharactersInSet:
                    NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
  [self applyFilter];
  [self.delegate onBotSubSessionListReload];
}

- (void)refreshListStateIfNeeded {
  if (self.topicList.count > 0) {
    [self refreshConversationReadTime];
  }
}

- (void)loadAllTopicsWithNextToken:(NSString *)nextToken
                       accumulator:(NSArray<V2NIMTopic *> *)accumulator
                        completion:(void (^)(NSArray<V2NIMTopic *> *, NSError *_Nullable))completion {
  V2NIMTopicListOption *option = [[V2NIMTopicListOption alloc] init];
  option.conversationId = self.conversationId;
  option.limit = 100;
  option.direction = V2NIM_QUERY_DIRECTION_DESC;
  option.beginTime = 0;
  option.endTime = 0;
  option.nextToken = nextToken;
  __weak typeof(self) weakSelf = self;
  [self.topicRepo getTopicListByOption:option :^(V2NIMTopicListResult *result, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      completion(accumulator, error);
      return;
    }
    if (error) {
      completion(accumulator, error);
      return;
    }
    NSArray<V2NIMTopic *> *page = [result.topicList isKindOfClass:[NSArray class]] ? result.topicList : @[];
    NSArray<V2NIMTopic *> *merged = [accumulator arrayByAddingObjectsFromArray:page];
    if (result.hasMore && result.nextToken.length > 0) {
      [self loadAllTopicsWithNextToken:result.nextToken accumulator:merged completion:completion];
    } else {
      completion(merged, nil);
    }
  }];
}

- (void)applyFilter {
  if (self.keyword.length == 0) {
    self.displayTopicList = [self sortedTopics:self.topicList];
    return;
  }
  NSString *key = self.keyword.lowercaseString;
  NSArray<V2NIMTopic *> *filtered = [self.topicList filteredArrayUsingPredicate:
    [NSPredicate predicateWithBlock:^BOOL(V2NIMTopic *topic, NSDictionary *bindings) {
      NSString *name = [[topic.topicName ?: @"" stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
      return [name containsString:key];
    }]];
  self.displayTopicList = [self sortedTopics:filtered];
}

- (NSArray<V2NIMTopic *> *)sortedTopics:(NSArray<V2NIMTopic *> *)topics {
  return [topics sortedArrayUsingComparator:^NSComparisonResult(V2NIMTopic *left, V2NIMTopic *right) {
    NSTimeInterval leftTime = [self sortTimeForTopic:left];
    NSTimeInterval rightTime = [self sortTimeForTopic:right];
    if (leftTime == rightTime) {
      return NSOrderedSame;
    }
    return leftTime > rightTime ? NSOrderedAscending : NSOrderedDescending;
  }];
}

- (NSTimeInterval)sortTimeForTopic:(V2NIMTopic *)topic {
  NSTimeInterval topicTime = NEBotNormalizedTimestamp((NSTimeInterval)topic.updateTime);
  NSTimeInterval summaryTime = NEBotNormalizedTimestamp(
    self.topicSummaryTimeMap[@(topic.topicId)].doubleValue);
  return MAX(topicTime, summaryTime);
}

- (void)loadSummaries {
  [self loadSummariesInvalidatingPending:YES topics:self.topicList];
}

- (void)loadSummariesFor:(NSArray<V2NIMTopic *> *)topics {
  [self loadSummariesInvalidatingPending:NO topics:topics];
}

- (void)loadSummariesInvalidatingPending:(BOOL)invalidatePending
                                  topics:(NSArray<V2NIMTopic *> *)topics {
  if (invalidatePending) {
    self.summaryRequestVersion += 1;
  }
  NSUInteger version = self.summaryRequestVersion;
  if (invalidatePending) {
    self.topicSummaryMap = @{};
    self.topicSummaryTimeMap = @{};
    self.topicLatestMessageFromSelfMap = @{};
  }
  if (topics.count == 0) {
    [self.delegate onBotSubSessionListReload];
    return;
  }
  NEBotSummaryLoadContext *context = [[NEBotSummaryLoadContext alloc] init];
  context.topics = topics;
  context.requestVersion = version;
  NSUInteger workerCount = MIN((NSUInteger)3, topics.count);
  for (NSUInteger worker = 0; worker < workerCount; worker++) {
    [self loadNextSummaryWithContext:context];
  }
}

- (void)loadNextSummaryWithContext:(NEBotSummaryLoadContext *)context {
  if (context.requestVersion != self.summaryRequestVersion) {
    return;
  }
  V2NIMTopic *topic = [context nextTopic];
  if (!topic) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  void (^applySummary)(V2NIMMessage *) = ^(V2NIMMessage *message) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || context.requestVersion != self.summaryRequestVersion) {
      return;
    }
    if ([self updateSummaryForTopic:topic message:message]) {
      [self applyFilter];
      [self.delegate onBotSubSessionListReload];
    }
    [self loadNextSummaryWithContext:context];
  };
  V2NIMMessageRefer *refer = [self messageReferForTopic:topic];
  if (!refer) {
    [NEALog errorLog:[NSString stringWithFormat:@"%@ BotSubSessionListViewModel", ModuleName]
                desc:[NSString stringWithFormat:@"%s, invalid root message refer, topicId: %llu",
                      __FUNCTION__, topic.topicId]];
    applySummary(nil);
    return;
  }
  [self.chatRepo getLocalThreadMessageList:refer completion:^(V2NIMThreadMessageListResult *result,
                                                               NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || context.requestVersion != self.summaryRequestVersion) {
      return;
    }
    if (error) {
      [NEALog errorLog:[NSString stringWithFormat:@"%@ BotSubSessionListViewModel", ModuleName]
                  desc:[NSString stringWithFormat:@"%s, topicId: %llu, error: %@",
                        __FUNCTION__, topic.topicId, error.localizedDescription ?: @"unknown"]];
      applySummary(nil);
      return;
    }
    NSMutableArray<V2NIMMessage *> *messages = [NSMutableArray arrayWithArray:result.replyList ?: @[]];
    if (result.message) {
      [messages addObject:result.message];
    }
    applySummary(NEBotLatestMessage(messages));
  }];
}

- (BOOL)updateSummaryForTopic:(V2NIMTopic *)topic message:(V2NIMMessage *)message {
  NSNumber *key = @(topic.topicId);
  NSString *previousSummary = self.topicSummaryMap[key];
  NSNumber *previousTime = self.topicSummaryTimeMap[key];
  NSNumber *previousFromSelf = self.topicLatestMessageFromSelfMap[key];
  NSMutableDictionary *summaries = [self.topicSummaryMap mutableCopy];
  NSMutableDictionary *times = [self.topicSummaryTimeMap mutableCopy];
  NSMutableDictionary *fromSelfMap = [self.topicLatestMessageFromSelfMap mutableCopy];
  summaries[key] = [self summaryTextFor:message];
  if (message) {
    times[key] = @(NEBotNormalizedTimestamp(message.createTime));
    fromSelfMap[key] = @([message.senderId isEqualToString:[[IMKitClient instance] account]]);
  } else {
    [times removeObjectForKey:key];
    [fromSelfMap removeObjectForKey:key];
  }
  self.topicSummaryMap = summaries;
  self.topicSummaryTimeMap = times;
  self.topicLatestMessageFromSelfMap = fromSelfMap;
  return ![previousSummary isEqualToString:self.topicSummaryMap[key]] ||
         ![previousTime isEqual:self.topicSummaryTimeMap[key]] ||
         ![previousFromSelf isEqual:self.topicLatestMessageFromSelfMap[key]];
}

- (V2NIMMessageRefer *)messageReferForTopic:(V2NIMTopic *)topic {
  NSString *clientId = topic.messageClientId;
  NSString *serverId = topic.messageServerId;
  NSString *conversationId = topic.conversationId.length > 0 ? topic.conversationId : self.conversationId;
  V2NIMConversationType conversationType = [V2NIMConversationIdUtil conversationType:conversationId];
  NSString *senderId = NEBotConversationSenderId(conversationId);
  NSString *receiverId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
  if (clientId.length == 0 || serverId.length == 0 || conversationId.length == 0 ||
      conversationType == V2NIM_CONVERSATION_TYPE_UNKNOWN || senderId.length == 0 ||
      receiverId.length == 0 || topic.messageTime <= 0) {
    return nil;
  }
  V2NIMMessageRefer *refer = [[V2NIMMessageRefer alloc] init];
  refer.messageClientId = clientId;
  refer.messageServerId = serverId;
  refer.conversationId = conversationId;
  refer.conversationType = conversationType;
  refer.senderId = senderId;
  refer.receiverId = receiverId;
  refer.createTime = NEBotNormalizedTimestamp((NSTimeInterval)topic.messageTime);
  return refer;
}

- (NSString *)summaryTextFor:(V2NIMMessage *)message {
  if (!message) {
    return @"";
  }
  NSString *text = [[ChatMessageHelper conversationListSummary:message]
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return NEBotPrefixByComposedCharacters(text ?: @"", 30);
}

- (NSString *)topicDisplayName:(V2NIMTopic *)topic {
  return [topic.topicName ?: @"" stringByTrimmingCharactersInSet:
          NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

- (void)markTopicRead:(V2NIMTopic *)topic {
  [self refreshConversationReadTime];
}

- (void)markAllCurrentTopicsRead {
  [self clearConversationUnread];
}

- (BOOL)hasUnreadWithTopic:(V2NIMTopic *)topic {
  NSNumber *latestTime = self.topicSummaryTimeMap[@(topic.topicId)];
  if (!latestTime || [self.topicLatestMessageFromSelfMap[@(topic.topicId)] boolValue]) {
    return NO;
  }
  NSTimeInterval readTime = NEBotNormalizedTimestamp(self.conversationReadTime);
  return readTime > 0 && latestTime.doubleValue > readTime;
}

- (void)clearConversationUnread {
  __weak typeof(self) weakSelf = self;
  void (^completion)(id, NSError *) = ^(id results, NSError *error) {
    [weakSelf refreshConversationReadTime];
  };
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo clearUnreadCountByIds:@[self.conversationId] completion:completion];
  } else {
    [self.conversationRepo clearUnreadCountByIds:@[self.conversationId] completion:completion];
  }
}

- (void)refreshConversationReadTime {
  __weak typeof(self) weakSelf = self;
  void (^completion)(NSNumber *, NSError *) = ^(NSNumber *time, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    self.conversationReadTime = NEBotNormalizedTimestamp(time.doubleValue);
    [self.delegate onBotSubSessionListReload];
  };
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
    [self.localConversationRepo getConversationReadTime:self.conversationId completion:completion];
  } else {
    [self.conversationRepo getConversationReadTime:self.conversationId completion:completion];
  }
}

- (void)updateTopicNameWithTopic:(V2NIMTopic *)topic
                       topicName:(NSString *)topicName
                                :(void (^)(V2NIMTopic *_Nullable, NSError *_Nullable))completion {
  V2NIMUpdateTopicParams *params = [[V2NIMUpdateTopicParams alloc] init];
  params.topic = topic;
  params.topicName = topicName;
  [self.topicRepo updateTopic:params :completion];
}

- (void)removeTopicWithTopic:(V2NIMTopic *)topic
                            :(void (^)(NSError *_Nullable))completion {
  V2NIMRemoveTopicsParams *params = [[V2NIMRemoveTopicsParams alloc] init];
  params.topicList = @[topic];
  [self.topicRepo removeTopics:params :completion];
}

- (NSSet<NSNumber *> *)collectTopicIdsFromMessages:(NSArray<V2NIMMessage *> *)messages {
  NSMutableSet<NSNumber *> *currentIds = [NSMutableSet set];
  for (V2NIMTopic *topic in self.topicList) {
    [currentIds addObject:@(topic.topicId)];
  }
  NSMutableSet<NSNumber *> *result = [NSMutableSet set];
  for (id value in messages ?: @[]) {
    if (![value isKindOfClass:[V2NIMMessage class]]) {
      continue;
    }
    V2NIMMessage *message = value;
    NSNumber *topicId = message.topicRefer ? @(message.topicRefer.topicId) : nil;
    if ([message.conversationId isEqualToString:self.conversationId] &&
        topicId && [currentIds containsObject:topicId]) {
      [result addObject:topicId];
    }
  }
  return result;
}

- (void)refreshTopicIds:(NSSet<NSNumber *> *)topicIds refreshUnread:(BOOL)refreshUnread {
  if (topicIds.count == 0) {
    return;
  }
  NSArray<V2NIMTopic *> *topics = [self.topicList filteredArrayUsingPredicate:
    [NSPredicate predicateWithBlock:^BOOL(V2NIMTopic *topic, NSDictionary *bindings) {
      return [topicIds containsObject:@(topic.topicId)];
    }]];
  if (topics.count == 0) {
    return;
  }
  if (refreshUnread) {
    [self refreshConversationReadTime];
  }
  [self loadSummariesFor:topics];
}

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
  [self refreshTopicIds:[self collectTopicIdsFromMessages:messages] refreshUnread:YES];
}

- (void)onSendMessage:(V2NIMMessage *)message {
  if (message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED) {
    [self refreshTopicIds:[self collectTopicIdsFromMessages:@[message]] refreshUnread:NO];
  }
}

- (void)sendMessageFailed:(V2NIMMessage *)message error:(NSError *)error {
  [self refreshTopicIds:[self collectTopicIdsFromMessages:@[message]] refreshUnread:NO];
}

- (void)sendMessageFailed:(V2NIMMessage *)message :(NSError *)error {
  [self sendMessageFailed:message error:error];
}

- (void)onReceiveMessagesModified:(NSArray<V2NIMMessage *> *)messages {
  [self refreshTopicIds:[self collectTopicIdsFromMessages:messages] refreshUnread:NO];
}

- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)notifications {
  for (V2NIMMessageDeletedNotification *notification in notifications ?: @[]) {
    if ([notification.messageRefer.conversationId isEqualToString:self.conversationId]) {
      [self loadSummaries];
      return;
    }
  }
}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)notifications {
  NSMutableArray<V2NIMMessageRefer *> *refers = [NSMutableArray array];
  for (V2NIMMessageRevokeNotification *notification in notifications ?: @[]) {
    if ([notification.messageRefer.conversationId isEqualToString:self.conversationId]) {
      [refers addObject:notification.messageRefer];
    }
  }
  if (refers.count == 0) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.chatRepo getMessageListByRefers:refers completion:^(NSArray<V2NIMMessage *> *messages,
                                                            NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    [self refreshTopicIds:[self collectTopicIdsFromMessages:messages ?: @[]] refreshUnread:NO];
  }];
}

- (void)onClearHistoryNotifications:(NSArray<V2NIMClearHistoryNotification *> *)notifications {
  for (V2NIMClearHistoryNotification *notification in notifications ?: @[]) {
    if ([notification.conversationId isEqualToString:self.conversationId]) {
      [self loadSummaries];
      return;
    }
  }
}

- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount {}

- (void)onLocalTotalUnreadCountChanged:(NSInteger)unreadCount {}

- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime {
  if (self.conversationId.length > 0 && [conversationId isEqualToString:self.conversationId]) {
    [self refreshConversationReadTime];
  }
}

- (void)onLocalConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime {
  if (self.conversationId.length > 0 && [conversationId isEqualToString:self.conversationId]) {
    [self refreshConversationReadTime];
  }
}

- (void)onTopicAdded:(V2NIMTopic *)topic {
  if (![topic.conversationId isEqualToString:self.conversationId]) {
    return;
  }
  NSMutableArray<V2NIMTopic *> *topics = [self.topicList mutableCopy];
  NSIndexSet *duplicates = [topics indexesOfObjectsPassingTest:
    ^BOOL(V2NIMTopic *value, NSUInteger index, BOOL *stop) {
      return value.topicId == topic.topicId;
    }];
  [topics removeObjectsAtIndexes:duplicates];
  [topics addObject:topic];
  self.topicList = [self sortedTopics:topics];
  [self loadSummariesFor:@[topic]];
  [self applyFilter];
  [self.delegate onBotSubSessionListReload];
}

- (void)onTopicsRemoved:(NSArray<V2NIMTopicRefer *> *)topics {
  NSMutableSet<NSNumber *> *removedIds = [NSMutableSet set];
  for (V2NIMTopicRefer *refer in topics ?: @[]) {
    if ([refer.conversationId isEqualToString:self.conversationId]) {
      [removedIds addObject:@(refer.topicId)];
    }
  }
  if (removedIds.count == 0) {
    return;
  }
  self.topicList = [self.topicList filteredArrayUsingPredicate:
    [NSPredicate predicateWithBlock:^BOOL(V2NIMTopic *topic, NSDictionary *bindings) {
      return ![removedIds containsObject:@(topic.topicId)];
    }]];
  NSMutableDictionary *summaries = [self.topicSummaryMap mutableCopy];
  NSMutableDictionary *times = [self.topicSummaryTimeMap mutableCopy];
  NSMutableDictionary *fromSelfMap = [self.topicLatestMessageFromSelfMap mutableCopy];
  for (NSNumber *topicId in removedIds) {
    [summaries removeObjectForKey:topicId];
    [times removeObjectForKey:topicId];
    [fromSelfMap removeObjectForKey:topicId];
  }
  self.topicSummaryMap = summaries;
  self.topicSummaryTimeMap = times;
  self.topicLatestMessageFromSelfMap = fromSelfMap;
  [self applyFilter];
  [self.delegate onBotSubSessionListReload];
}

- (void)onTopicUpdated:(V2NIMTopic *)topic {
  if (![topic.conversationId isEqualToString:self.conversationId]) {
    return;
  }
  NSMutableArray<V2NIMTopic *> *topics = [self.topicList mutableCopy];
  NSUInteger index = [topics indexOfObjectPassingTest:
    ^BOOL(V2NIMTopic *value, NSUInteger index, BOOL *stop) {
      return value.topicId == topic.topicId;
    }];
  if (index == NSNotFound) {
    return;
  }
  topics[index] = topic;
  self.topicList = [self sortedTopics:topics];
  [self loadSummariesFor:@[topic]];
  [self applyFilter];
  [self.delegate onBotSubSessionListReload];
}

@end
