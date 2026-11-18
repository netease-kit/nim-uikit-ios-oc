// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import "NETopicChatViewModel.h"
#import "TopicChatViewModel.h"
#import "ChatMessageHelper.h"
#import "MessageTextModel.h"
#import <NEChatKit/NEChatKit-Swift.h>

static NSString *NETopicNamePrefix(NSString *value, NSUInteger limit) {
  if (![value isKindOfClass:[NSString class]] || value.length == 0 || limit == 0) return @"";
  __block NSUInteger count = 0;
  __block NSUInteger end = 0;
  [value enumerateSubstringsInRange:NSMakeRange(0, value.length)
                           options:NSStringEnumerationByComposedCharacterSequences
                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
    count += 1;
    end = NSMaxRange(substringRange);
    if (count >= limit) *stop = YES;
  }];
  return end < value.length ? [value substringToIndex:end] : value;
}

@interface TopicChatViewModel ()
@property(nonatomic, strong, readwrite) TopicRepo *topicRepo;
@property(nonatomic, copy, readwrite) NSString *sessionName;
@property(nonatomic, copy) NSString *conversationId;
@property(nonatomic, strong) V2NIMMessage *oldestMessage;
@property(nonatomic, strong) V2NIMMessage *newestMessage;
@property(nonatomic, strong) V2NIMMessage *olderTopicAnchorMessage;
@property(nonatomic, assign) BOOL hasMoreOlder;
@property(nonatomic, assign) BOOL hasMoreNewer;
@property(nonatomic, strong) NSMutableSet<NSString *> *creatingTopicMessageIds;
@property(nonatomic, strong) V2NIMMessage *pendingAutoNameMessage;
@property(nonatomic, strong) V2NIMTopicRefer *pendingAutoNameTopicRefer;
@property(nonatomic, copy) NSString *pendingAutoNameConversationId;
@property(nonatomic, assign) BOOL autoNamingTopic;
@property(nonatomic, assign) BOOL removingCurrentTopic;
@property(nonatomic, assign) BOOL notifiedCurrentTopicRemoved;
- (BOOL)containsTopicMessage:(nullable V2NIMMessage *)message;
- (BOOL)isSameMessageRefer:(nullable V2NIMMessageRefer *)left right:(nullable V2NIMMessageRefer *)right;
- (BOOL)shouldShowThreadReply:(nullable V2NIMMessage *)message;
- (NSString *)replyMessageId:(nullable V2NIMMessage *)message;
@end

@implementation NETopicChatViewModel

- (instancetype)initWithConversationId:(NSString *)conversationId
                                  topic:(V2NIMTopic *)topic
                            sessionName:(NSString *)sessionName {
  return [super initWithConversationId:conversationId
                                anchor:nil
                                 topic:topic
                           sessionName:sessionName];
}

- (void)updateTopicName:(NSString *)name
              completion:(void (^)(NSError *_Nullable))completion {
  [super updateTopicName:name :^(V2NIMTopic *topic, NSError *error) {
    if (completion) completion(error);
  }];
}

@end

@implementation TopicChatViewModel
@synthesize conversationId = _conversationId;

- (BOOL)supportsLastReadPosition { return NO; }

- (BOOL)containsTopicMessage:(V2NIMMessage *)message {
  if (![message isKindOfClass:[V2NIMMessage class]]) return NO;
  for (id<MessageModel> model in self.messages) {
    if ([model.message.messageClientId isEqualToString:message.messageClientId] &&
        message.messageClientId.length > 0) return YES;
  }
  return NO;
}

- (void)setupReactionManagerWithConversationId:(NSString *)conversationId {}

- (void)startReactionManager {}

- (id)reactionEmojiProvider { return nil; }

- (instancetype)initWithConversationId:(NSString *)conversationId
                                 anchor:(V2NIMMessage *)anchor
                                  topic:(V2NIMTopic *)topic
                            sessionName:(NSString *)sessionName {
  self = [super initWithConversationId:conversationId anchor:anchor];
  if (self) {
    _topicRepo = [TopicRepo shared];
    _conversationId = [conversationId isKindOfClass:[NSString class]] ? [conversationId copy] : @"";
    _topic = [topic isKindOfClass:[V2NIMTopic class]] ? topic : nil;
    _sessionName = [sessionName isKindOfClass:[NSString class]] ? [sessionName copy] : @"";
    _creatingTopicMessageIds = [NSMutableSet set];
    [_topicRepo addTopicListener:self];
  }
  return self;
}

- (void)dealloc { [self.topicRepo removeTopicListener:self]; }

- (NSString *)currentTitle {
  NSString *name = [self.topic.topicName isKindOfClass:[NSString class]] ? self.topic.topicName : nil;
  name = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (name.length > 0) return name;
  return self.sessionName;
}

- (BOOL)isSameTopicRefer:(V2NIMTopicRefer *)refer {
  if (![refer isKindOfClass:[V2NIMTopicRefer class]] || !self.topic) return NO;
  return refer.topicId == self.topic.topicId && refer.createTime == self.topic.createTime &&
    [refer.conversationId isEqualToString:self.topic.conversationId];
}

- (BOOL)isTopic:(V2NIMTopic *)topic matchingRefer:(V2NIMTopicRefer *)refer {
  if (![topic isKindOfClass:[V2NIMTopic class]] ||
      ![refer isKindOfClass:[V2NIMTopicRefer class]]) return NO;
  return [refer.conversationId isEqualToString:topic.conversationId] &&
    refer.topicId == topic.topicId && refer.createTime == topic.createTime;
}

- (BOOL)isPendingAutoNameTopic:(V2NIMTopic *)topic {
  if (![topic isKindOfClass:[V2NIMTopic class]] ||
      self.pendingAutoNameConversationId.length == 0 ||
      !self.pendingAutoNameMessage ||
      ![topic.conversationId isEqualToString:self.pendingAutoNameConversationId]) return NO;
  if (self.pendingAutoNameTopicRefer) {
    return [self isTopic:topic matchingRefer:self.pendingAutoNameTopicRefer];
  }
  NSString *messageClientId = self.pendingAutoNameMessage.messageClientId;
  if (messageClientId.length > 0 && topic.messageClientId.length > 0) {
    return [messageClientId isEqualToString:topic.messageClientId];
  }
  NSString *messageServerId = self.pendingAutoNameMessage.messageServerId;
  if (messageServerId.length > 0 && topic.messageServerId.length > 0) {
    return [messageServerId isEqualToString:topic.messageServerId];
  }
  return YES;
}

- (BOOL)isCurrentTopicMessage:(V2NIMMessage *)message {
  if (![message isKindOfClass:[V2NIMMessage class]] || ![message.conversationId isEqualToString:self.conversationId]) return NO;
  if (self.topic) return [self isSameTopicRefer:message.topicRefer];
  NSString *clientId = message.messageClientId;
  if (clientId.length > 0 && [self.creatingTopicMessageIds containsObject:clientId]) return YES;
  V2NIMTopicRefer *messageRefer = [message.topicRefer isKindOfClass:[V2NIMTopicRefer class]] ? message.topicRefer : nil;
  if (self.pendingAutoNameTopicRefer && messageRefer &&
      [self isTopicRefer:messageRefer matchingRefer:self.pendingAutoNameTopicRefer]) return YES;
  return NO;
}

- (BOOL)isTopicRefer:(V2NIMTopicRefer *)left matchingRefer:(V2NIMTopicRefer *)right {
  if (![left isKindOfClass:[V2NIMTopicRefer class]] ||
      ![right isKindOfClass:[V2NIMTopicRefer class]]) return NO;
  return [left.conversationId isEqualToString:right.conversationId] &&
    left.topicId == right.topicId && left.createTime == right.createTime;
}

- (BOOL)isMessage:(V2NIMMessage *)message matchingRefer:(V2NIMMessageRefer *)refer {
  if (![message isKindOfClass:[V2NIMMessage class]] ||
      ![refer isKindOfClass:[V2NIMMessageRefer class]]) return NO;
  if (refer.messageClientId.length > 0 &&
      [refer.messageClientId isEqualToString:message.messageClientId]) return YES;
  if (refer.messageServerId.length > 0 &&
      [refer.messageServerId isEqualToString:message.messageServerId] &&
      refer.createTime == message.createTime) return YES;
  return [refer.conversationId isEqualToString:message.conversationId] &&
    refer.createTime == message.createTime;
}

- (NSArray<V2NIMMessage *> *)safeMessages:(NSArray *)values {
  NSMutableArray *result = [NSMutableArray array];
  for (id value in values ?: @[]) if ([value isKindOfClass:[V2NIMMessage class]]) [result addObject:value];
  return result;
}

- (NSString *)topicMessageKey:(V2NIMMessage *)message {
  if (message.messageClientId.length > 0) return [@"client:" stringByAppendingString:message.messageClientId];
  if (message.messageServerId.length > 0) return [@"server:" stringByAppendingString:message.messageServerId];
  return [NSString stringWithFormat:@"time:%lld-type:%ld", (long long)message.createTime, (long)message.messageType];
}

- (NSArray<V2NIMMessage *> *)uniqueTopicMessages:(NSArray<V2NIMMessage *> *)messages {
  NSMutableArray<V2NIMMessage *> *result = [NSMutableArray array];
  NSMutableSet<NSString *> *keys = [NSMutableSet set];
  for (V2NIMMessage *message in [self safeMessages:messages]) {
    NSString *key = [self topicMessageKey:message];
    if ([keys containsObject:key]) continue;
    [keys addObject:key];
    [result addObject:message];
  }
  return result;
}

- (void)appendMessages:(NSArray<V2NIMMessage *> *)messages
              direction:(V2NIMQueryDirection)direction
                 result:(V2NIMTopicMessageListResult *)result {
  for (V2NIMMessage *message in messages) {
    if (message.messageClientId.length > 0 &&
        ![self.messageClientIds containsObject:message.messageClientId]) {
      [self.messageClientIds addObject:message.messageClientId];
    }
    self.oldestMessage = !self.oldestMessage || message.createTime < self.oldestMessage.createTime ? message : self.oldestMessage;
    self.newestMessage = !self.newestMessage || message.createTime > self.newestMessage.createTime ? message : self.newestMessage;
    if ([ChatMessageHelper isAISender:message]) [self setErrorText:message];
    BOOL containsMessage = NO;
    for (id<MessageModel> existing in self.messages) {
      NSString *existingClientId = existing.message.messageClientId;
      NSString *messageClientId = message.messageClientId;
      if (existingClientId == messageClientId || [existingClientId isEqualToString:messageClientId]) {
        containsMessage = YES;
        break;
      }
    }
    if (containsMessage) continue;
    id<MessageModel> model = [self modelFromMessage:message];
    if (model) [self insertToMessages:model];
  }
  if (direction == V2NIM_QUERY_DIRECTION_DESC) {
    V2NIMMessage *first = messages.count > 0 ? messages[0] : nil;
    self.olderTopicAnchorMessage = [result.anchorMessage isKindOfClass:[V2NIMMessage class]]
      ? result.anchorMessage : first;
    self.hasMoreOlder = result ? result.hasMore : NO;
  } else {
    V2NIMMessage *last = messages.count > 0 ? messages.lastObject : nil;
    self.newestMessage = [result.anchorMessage isKindOfClass:[V2NIMMessage class]] ? result.anchorMessage : (last ?: self.newestMessage);
    self.hasMoreNewer = result ? result.hasMore : messages.count > 0;
  }
  if (messages.count > 0) [self addTimeForHistoryMessage:YES];
}

- (void)refreshReadReceiptsForMessages:(NSArray<V2NIMMessage *> *)messages {
  if (messages.count == 0) return;
  __weak typeof(self) weakSelf = self;
  [self getMessageReceipts:messages completion:^(NSArray<NSIndexPath *> *reloadIndexs, NSError *error) {
    if (reloadIndexs.count == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf.delegate onLoadMoreWithMessage:reloadIndexs];
    });
  }];
}

- (void)loadTopicPageWithAnchor:(V2NIMMessage *)anchor
                      direction:(V2NIMQueryDirection)direction
                     completion:(void (^)(NSError *, NSArray<V2NIMMessage *> *, V2NIMTopicMessageListResult *))completion {
  if (!self.topic) { if (completion) completion(nil, @[], nil); return; }
  V2NIMTopicMessageListOption *option = [[V2NIMTopicMessageListOption alloc] init];
  option.topic = self.topic;
  option.limit = 100;
  option.anchorMessage = anchor;
  option.direction = direction;
  option.sortOrder = V2NIM_SORT_ORDER_ASC;
  option.beginTime = 0;
  option.endTime = 0;
  [[TopicRepo shared] getTopicMessageList:option :^(V2NIMTopicMessageListResult *result, NSError *error) {
    NSArray *messages = [result isKindOfClass:[V2NIMTopicMessageListResult class]] ? [self uniqueTopicMessages:result.replyList] : @[];
    messages = [messages sortedArrayUsingComparator:^NSComparisonResult(V2NIMMessage *left, V2NIMMessage *right) {
      if (left.createTime == right.createTime) return NSOrderedSame;
      return left.createTime < right.createTime ? NSOrderedAscending : NSOrderedDescending;
    }];
    if (completion) completion(error, messages, result);
  }];
}

- (void)resetTopicHistoryState {
  [self.messages removeAllObjects];
  [self.messageClientIds removeAllObjects];
  self.oldestMessage = nil;
  self.newestMessage = nil;
  self.olderTopicAnchorMessage = nil;
  self.hasMoreOlder = NO;
  self.hasMoreNewer = NO;
  self.isHistoryChat = NO;
}

- (void)loadTopicData:(void (^)(NSError *, NSInteger, NSInteger, NSInteger))completion {
  if (!self.topic) {
    [self resetTopicHistoryState];
    [self.delegate tableViewReload];
    if (completion) completion(nil, 0, 0, 0);
    return;
  }
  [self loadTopicPageWithAnchor:nil direction:V2NIM_QUERY_DIRECTION_DESC
                     completion:^(NSError *error, NSArray<V2NIMMessage *> *messages,
                                  V2NIMTopicMessageListResult *result) {
    if (error) {
      if (completion) completion(error, 0, 0, 0);
      return;
    }
    [self resetTopicHistoryState];
    [self appendMessages:messages direction:V2NIM_QUERY_DIRECTION_DESC result:result];
    [self.delegate tableViewReload];
    if (completion) completion(nil, messages.count, 0, 0);
    if (messages.count > 0) [self loadMoreWithMessage:messages];
  }];
}

- (void)getTopicHistoryWithOrder:(V2NIMQueryDirection)order
                   anchorMessage:(V2NIMMessage *)anchorMessage
                                :(void (^)(NSError *, NSInteger, NSArray<V2NIMMessage *> *))completion {
  if (!self.topic) {
    if (completion) completion(nil, 0, @[]);
    return;
  }
  [self loadTopicPageWithAnchor:anchorMessage direction:order
                     completion:^(NSError *error, NSArray<V2NIMMessage *> *messages,
                                  V2NIMTopicMessageListResult *result) {
    if (error) {
      if (completion) completion(error, 0, @[]);
      return;
    }
    [self appendMessages:messages direction:order result:result];
    if (completion) completion(nil, messages.count, messages);
  }];
}

- (void)loadData:(void (^)(NSError *, NSInteger, NSInteger, NSInteger))completion {
  [self loadTopicData:completion];
}

- (void)dropDownRemoteRefresh:(void (^)(NSError *, NSInteger, NSArray<V2NIMMessage *> *))completion {
  if (!self.hasMoreOlder) { if (completion) completion(nil, 0, @[]); return; }
  V2NIMMessage *anchor = self.olderTopicAnchorMessage ?: self.oldestMessage ?: self.messages.firstObject.message;
  [self getTopicHistoryWithOrder:V2NIM_QUERY_DIRECTION_DESC anchorMessage:anchor
                                :^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *messages) {
    if (completion) completion(error, count, messages);
    if (count > 0) [self loadMoreWithMessage:messages];
  }];
}

- (void)pullRemoteRefresh:(void (^)(NSError *, NSInteger, NSArray<V2NIMMessage *> *))completion {
  V2NIMMessage *lastMessage = self.messages.lastObject.message;
  if (!self.hasMoreNewer && !self.newestMessage && !lastMessage) {
    if (completion) completion(nil, 0, @[]);
    return;
  }
  V2NIMMessage *anchor = self.newestMessage ?: lastMessage;
  [self getTopicHistoryWithOrder:V2NIM_QUERY_DIRECTION_ASC anchorMessage:anchor
                                :^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *messages) {
    if (completion) completion(error, count, messages);
    if (count > 0) [self loadMoreWithMessage:messages];
  }];
}

- (NSString *)defaultTopicNameForMessage:(V2NIMMessage *)message {
  NSString *name = @"";
  if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
    NSArray<NSString *> *parts = [message.text ?: @"" componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    name = [[parts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *value, NSDictionary *bindings) {
      return [value isKindOfClass:[NSString class]] && value.length > 0;
    }]] componentsJoinedByString:@" "];
  }
  if (name.length == 0) name = [[ChatMessageHelper conversationListSummary:message] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
  if (name.length == 0) name = self.sessionName;
  return NETopicNamePrefix(name, 20);
}

- (void)resolveTopicFromMessage:(V2NIMMessage *)message {
  if (self.topic) return;
  V2NIMTopicRefer *refer = [message.topicRefer isKindOfClass:[V2NIMTopicRefer class]] ? message.topicRefer : nil;
  if (!refer) return;
  self.pendingAutoNameTopicRefer = refer;
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] getTopicByRefer:refer :^(V2NIMTopic *topic, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || ![topic isKindOfClass:[V2NIMTopic class]]) return;
    [self updateCurrentTopic:topic];
  }];
}

- (void)updateCurrentTopic:(V2NIMTopic *)topic {
  self.topic = topic;
  [self notifyTopicChanged:topic];
  [self autoNameTopicIfNeeded];
}

- (void)notifyTopicChanged:(V2NIMTopic *)topic {
  id delegate = self.delegate;
  if ([delegate conformsToProtocol:@protocol(TopicChatViewModelOutput)] &&
      [delegate respondsToSelector:@selector(onTopicChanged:)]) {
    [(id<TopicChatViewModelOutput>)delegate onTopicChanged:topic];
  }
}

- (void)notifyCurrentTopicRemovedIfNeeded {
  if (self.notifiedCurrentTopicRemoved) return;
  self.notifiedCurrentTopicRemoved = YES;
  id delegate = self.delegate;
  if ([delegate conformsToProtocol:@protocol(TopicChatViewModelOutput)] &&
      [delegate respondsToSelector:@selector(onCurrentTopicRemoved)]) {
    [(id<TopicChatViewModelOutput>)delegate onCurrentTopicRemoved];
  }
}

- (void)clearPendingAutoName {
  self.pendingAutoNameMessage = nil;
  self.pendingAutoNameTopicRefer = nil;
  self.pendingAutoNameConversationId = nil;
  self.autoNamingTopic = NO;
}

- (void)clearPendingAutoNameIfSame:(V2NIMMessage *)message {
  NSString *pendingClientId = self.pendingAutoNameMessage.messageClientId;
  NSString *messageClientId = message.messageClientId;
  if (pendingClientId != messageClientId &&
      ![pendingClientId isEqualToString:messageClientId]) return;
  [self clearPendingAutoName];
}

- (void)autoNameTopicIfNeeded {
  if (!self.topic || !self.pendingAutoNameMessage || self.autoNamingTopic) return;
  if (self.pendingAutoNameTopicRefer &&
      ![self isTopic:self.topic matchingRefer:self.pendingAutoNameTopicRefer]) return;
  NSString *existingName = [self.topic.topicName isKindOfClass:[NSString class]] ? self.topic.topicName : @"";
  existingName = [existingName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (existingName.length > 0) {
    [self clearPendingAutoName];
    return;
  }
  V2NIMUpdateTopicParams *params = [[V2NIMUpdateTopicParams alloc] init];
  params.topic = self.topic;
  params.topicName = [self defaultTopicNameForMessage:self.pendingAutoNameMessage];
  self.autoNamingTopic = YES;
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] updateTopic:params :^(V2NIMTopic *topic, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.autoNamingTopic = NO;
    if ([topic isKindOfClass:[V2NIMTopic class]]) {
      [self clearPendingAutoName];
      [self updateCurrentTopic:topic];
    }
  }];
}

- (void)sendMessage:(V2NIMMessage *)message conversationId:(NSString *)conversationId params:(V2NIMSendMessageParams *)params completion:(void (^)(V2NIMMessage *, NSError *, NSUInteger))completion {
  NSString *target = conversationId ?: [ChatRepo conversationId];
  NSString *currentConversationId = [ChatRepo conversationId];
  BOOL isCurrentTopicTarget = [target isEqualToString:currentConversationId] ||
    ([target hasPrefix:[currentConversationId stringByAppendingString:@"|"]]);
  if (!isCurrentTopicTarget) {
    [super sendMessage:message conversationId:target params:params completion:completion];
    return;
  }
  V2NIMSendTopicMessageParams *topicParams = [[V2NIMSendTopicMessageParams alloc] init];
  topicParams.sendMessageParams = params;
  if (!self.topic) {
    V2NIMCreateTopicParams *create = [[V2NIMCreateTopicParams alloc] init];
    topicParams.createTopicParams = create;
    if (message.messageClientId.length > 0) [self.creatingTopicMessageIds addObject:message.messageClientId];
    self.pendingAutoNameMessage = message;
    self.pendingAutoNameTopicRefer = nil;
    self.pendingAutoNameConversationId = currentConversationId;
  }
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] sendTopicMessageWithMessage:message conversationId:currentConversationId topic:self.topic params:topicParams :^(V2NIMSendMessageResult *result, NSError *error, NSUInteger progress) {
    __strong typeof(weakSelf) self = weakSelf;
    V2NIMMessage *sent = [result.message isKindOfClass:[V2NIMMessage class]] ? result.message : nil;
    if (self) {
      if ([IMKitConfigCenter shared].enableAntiSpamTipMessage) [self checkAntiSpam:result];
      if (sent) {
        NSString *pendingClientId = self.pendingAutoNameMessage.messageClientId;
        NSString *messageClientId = message.messageClientId;
        if (self.pendingAutoNameMessage &&
            (pendingClientId == messageClientId || [pendingClientId isEqualToString:messageClientId])) {
          self.pendingAutoNameMessage = sent;
          self.pendingAutoNameTopicRefer = sent.topicRefer;
        }
        [self resolveTopicFromMessage:sent];
        [self autoNameTopicIfNeeded];
        if (!self.topic) [self loadPendingTopicIfNeeded];
      }
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self sendMsgFailed:message error:error];
        });
        if (message.messageClientId.length > 0) {
          [self.creatingTopicMessageIds removeObject:message.messageClientId];
        }
        [self clearPendingAutoNameIfSame:message];
      } else if (sent) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self sendMsgSuccess:sent];
        });
      }
    }
    if (completion) completion(sent ?: message, error, progress);
  }];
}

- (void)sendMessageWithMessage:(V2NIMMessage *)message
                conversationId:(NSString *)conversationId
                         params:(V2NIMSendMessageParams *)params
                               :(void (^)(V2NIMMessage *, NSError *, NSUInteger))completion {
  [self sendMessage:message conversationId:conversationId params:params completion:completion];
}

- (void)onSendMessage:(V2NIMMessage *)message {
  if (![self isCurrentTopicMessage:message]) return;
  [self resolveTopicFromMessage:message];
  if (message.messageClientId.length > 0 && ![self.messageClientIds containsObject:message.messageClientId]) {
    [self.messageClientIds addObject:message.messageClientId];
  }
  if ([message isKindOfClass:[V2NIMMessage class]]) {
    if (!self.oldestMessage || message.createTime < self.oldestMessage.createTime) self.oldestMessage = message;
    if (!self.newestMessage || message.createTime > self.newestMessage.createTime) self.newestMessage = message;
  }
  switch (message.sendingState) {
    case V2NIM_MESSAGE_SENDING_STATE_SENDING: [self sendingMsg:message]; break;
    case V2NIM_MESSAGE_SENDING_STATE_FAILED:
      [self sendMsgFailed:message error:nil];
      [self.creatingTopicMessageIds removeObject:message.messageClientId ?: @""];
      [self clearPendingAutoNameIfSame:message];
      break;
    case V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED:
      [self sendMsgSuccess:message];
      [self.creatingTopicMessageIds removeObject:message.messageClientId ?: @""];
      break;
    default: break;
  }
}

- (void)sendMessageFailed:(V2NIMMessage *)message error:(NSError *)error {
  if (![self isCurrentTopicMessage:message]) return;
  [self.creatingTopicMessageIds removeObject:message.messageClientId ?: @""];
  [self clearPendingAutoNameIfSame:message];
  [self sendMsgFailed:message error:error];
}

- (void)sendMessageFailed:(V2NIMMessage *)message :(NSError *)error {
  [self sendMessageFailed:message error:error];
}

- (void)insertTipMessage:(NSString *)text
              createTime:(NSNumber *)createTime
          conversationId:(NSString *)conversationId
                senderId:(NSString *)senderId {
  NSString *targetConversationId = conversationId.length > 0 ? conversationId : [ChatRepo conversationId];
  if (![targetConversationId isEqualToString:[ChatRepo conversationId]]) return;
  void (^notify)(void) = ^{
    id delegate = self.delegate;
    if ([delegate conformsToProtocol:@protocol(TopicChatViewModelOutput)] &&
        [delegate respondsToSelector:@selector(onTopicTipMessage:)]) {
      [(id<TopicChatViewModelOutput>)delegate onTopicTipMessage:text ?: @""];
    }
  };
  if ([NSThread isMainThread]) notify();
  else dispatch_async(dispatch_get_main_queue(), notify);
}

- (void)loadPendingTopicIfNeeded {
  if (self.topic || self.pendingAutoNameConversationId.length == 0) return;
  V2NIMTopicListOption *option = [[V2NIMTopicListOption alloc] init];
  option.conversationId = self.pendingAutoNameConversationId;
  option.limit = 20;
  option.direction = V2NIM_QUERY_DIRECTION_DESC;
  option.beginTime = 0;
  option.endTime = 0;
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] getTopicListByOption:option :^(V2NIMTopicListResult *result, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || self.topic || ![result isKindOfClass:[V2NIMTopicListResult class]]) return;
    for (id value in result.topicList ?: @[]) {
      if ([value isKindOfClass:[V2NIMTopic class]] && [self isPendingAutoNameTopic:value]) {
        [self updateCurrentTopic:value];
        break;
      }
    }
  }];
}

- (void)replyMessageWithThread:(V2NIMMessage *)message replyMessage:(V2NIMMessage *)replyMessage aiUserAccid:(NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *, NSError *))completion {
  V2NIMTopic *currentTopic = self.topic;
  if (!currentTopic) {
    // A newly-created Topic can be delivered by the SDK listener after the
    // reply action. Resolve it from the message reference before falling back
    // to the normal conversation sender, matching the Swift implementation.
    V2NIMTopicRefer *topicRefer = [replyMessage.topicRefer isKindOfClass:[V2NIMTopicRefer class]] ? replyMessage.topicRefer : nil;
    if (!topicRefer) topicRefer = [message.topicRefer isKindOfClass:[V2NIMTopicRefer class]] ? message.topicRefer : nil;
    if (!topicRefer && [self.pendingAutoNameTopicRefer isKindOfClass:[V2NIMTopicRefer class]]) topicRefer = self.pendingAutoNameTopicRefer;
    if (topicRefer) {
      __weak typeof(self) weakSelf = self;
      [[TopicRepo shared] getTopicByRefer:topicRefer :^(V2NIMTopic *resolvedTopic, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || ![resolvedTopic isKindOfClass:[V2NIMTopic class]]) {
          if (completion) completion(nil, error);
          return;
        }
        [self updateCurrentTopic:resolvedTopic];
        V2NIMSendMessageParams *params = [self getReplyMessageParams:aiUserAccid replyMessage:replyMessage message:message];
        [[TopicRepo shared] replyTopicMessageWithMessage:message replyMessage:replyMessage topic:resolvedTopic params:params :^(V2NIMSendMessageResult *result, NSError *replyError, NSUInteger progress) {
          V2NIMMessage *sent = [result.message isKindOfClass:[V2NIMMessage class]] ? result.message : nil;
          if (completion) completion(sent, replyError);
        }];
      }];
      return;
    }
    [self sendMessage:message conversationId:self.conversationId params:nil completion:^(V2NIMMessage *sent, NSError *error, NSUInteger progress) {
      if (completion) completion(sent, error);
    }];
    return;
  }
  V2NIMSendMessageParams *params = [self getReplyMessageParams:aiUserAccid replyMessage:replyMessage message:message];
  [[TopicRepo shared] replyTopicMessageWithMessage:message replyMessage:replyMessage topic:currentTopic params:params :^(V2NIMSendMessageResult *result, NSError *error, NSUInteger progress) {
    V2NIMMessage *sent = [result.message isKindOfClass:[V2NIMMessage class]] ? result.message : nil;
    if (completion) completion(sent, error);
  }];
}

- (void)replyMessageWithThreadWithMessage:(V2NIMMessage *)message
                              replyMessage:(V2NIMMessage *)replyMessage
                               aiUserAccid:(NSString *)aiUserAccid
                                          :(void (^)(V2NIMMessage *, NSError *))completion {
  [self replyMessageWithThread:message replyMessage:replyMessage
                   aiUserAccid:aiUserAccid completion:completion];
}

- (BOOL)isSameMessageRefer:(V2NIMMessageRefer *)left right:(V2NIMMessageRefer *)right {
  if (![left isKindOfClass:[V2NIMMessageRefer class]] ||
      ![right isKindOfClass:[V2NIMMessageRefer class]]) return NO;
  if (left.messageClientId.length > 0 &&
      [left.messageClientId isEqualToString:right.messageClientId]) return YES;
  return left.messageServerId.length > 0 &&
    [left.messageServerId isEqualToString:right.messageServerId] &&
    left.createTime == right.createTime;
}

- (BOOL)shouldShowThreadReply:(V2NIMMessage *)message {
  V2NIMMessageRefer *threadReply = message.threadReply;
  if (!threadReply.messageClientId.length) return NO;
  V2NIMMessageRefer *threadRoot = message.threadRoot;
  return !threadRoot || ![self isSameMessageRefer:threadRoot right:threadReply];
}

- (void)revokeMessageUpdateUI:(V2NIMMessage *)message {
  [super revokeMessageUpdateUI:message];
}

- (NSString *)replyMessageId:(V2NIMMessage *)message {
  if (![message isKindOfClass:[V2NIMMessage class]]) return nil;
  if ([self shouldShowThreadReply:message] && message.threadReply.messageClientId.length > 0) {
    return message.threadReply.messageClientId;
  }
  NSDictionary *remoteExt = [NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""];
  id reply = remoteExt[keyReplyMsgKey];
  return [reply isKindOfClass:[NSDictionary class]] ? reply[@"idClient"] : nil;
}

- (id<MessageModel>)getReplyMessageFromLocal:(V2NIMMessage *)message {
  NSString *replyId = [self replyMessageId:message];
  if (replyId.length == 0) return nil;
  for (id<MessageModel> model in [self.messages copy]) {
    if ([model.message.messageClientId isEqualToString:replyId] && !model.isRevoked) return model;
  }
  MessageTextModel *textModel = [[MessageTextModel alloc] initWithMessage:nil];
  NSDictionary *replyDic = [ChatMessageHelper getReplyDictionary:message];
  NSString *senderId = nil;
  if ([self shouldShowThreadReply:message] && message.threadReply.senderId.length > 0) {
    senderId = message.threadReply.senderId;
  } else {
    senderId = replyDic[@"from"];
  }
  if (senderId.length > 0) textModel.fullName = senderId;
  return textModel;
}

- (id<MessageModel>)getReplyMessageWithMessage:(V2NIMMessage *)message {
  return [self getReplyMessageFromLocal:message];
}

- (void)getReplyMessage:(V2NIMMessage *)message completion:(void (^)(id<MessageModel>))completion {
  NSString *replyId = [self replyMessageId:message];
  if (replyId.length == 0) { if (completion) completion(nil); return; }
  for (id<MessageModel> model in [self.messages copy]) {
    if ([model.message.messageClientId isEqualToString:replyId] && !model.isRevoked) {
      if (completion) completion(model);
      return;
    }
  }
  NSDictionary *replyDic = [ChatMessageHelper getReplyDictionary:message];
  V2NIMMessageRefer *refer = [ChatMessageHelper createMessageRefer:replyDic];
  if ([self shouldShowThreadReply:message]) {
    V2NIMMessageRefer *threadReply = message.threadReply;
    if (threadReply.senderId.length > 0) refer.senderId = threadReply.senderId;
    if (threadReply.receiverId.length > 0) refer.receiverId = threadReply.receiverId;
    if (threadReply.messageClientId.length > 0) refer.messageClientId = threadReply.messageClientId;
    if (threadReply.messageServerId.length > 0) refer.messageServerId = threadReply.messageServerId;
    refer.conversationType = threadReply.conversationType;
    if (threadReply.conversationId.length > 0) refer.conversationId = threadReply.conversationId;
    refer.createTime = threadReply.createTime;
  }
  __weak typeof(self) weakSelf = self;
  [[ChatRepo shared] getMessageListByRefers:@[refer] completion:^(NSArray<V2NIMMessage *> *messages, NSError *error) {
    V2NIMMessage *target = messages.firstObject;
    if (!target) { if (completion) completion(nil); return; }
    [weakSelf modelFromMessage:target completion:^(id<MessageModel> model) {
      if (completion) completion(model);
    }];
  }];
}

- (void)getReplyMessageWithMessage:(V2NIMMessage *)message
                                   :(void (^)(id<MessageModel>))completion {
  [self getReplyMessage:message completion:completion];
}

- (void)revokeMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable))completion {
  NSMutableDictionary *extension = [NSMutableDictionary dictionaryWithDictionary:
    [NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""] ?: @{}];
  if ([self shouldShowThreadReply:message] && message.threadReply.messageClientId.length > 0) {
    extension[keyReplyMsgKey] = [ChatMessageHelper createReplyDic:message.threadReply];
  }
  extension[revokeLocalMessage] = @YES;
  extension[revokeLocalMessageTime] = @([[NSDate date] timeIntervalSince1970]);
  if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
    if (message.text) extension[revokeLocalMessageContent] = message.text;
    else [extension removeObjectForKey:revokeLocalMessageContent];
  }
  if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
    NSString *title = [NECustomUtils titleOfRichText:message.attachment];
    NSString *body = [NECustomUtils bodyOfRichText:message.attachment];
    if (title.length > 0) extension[revokeLocalMessageTitle] = title;
    if (body.length > 0) extension[revokeLocalMessageContent] = body;
  }
  V2NIMMessageRevokeParams *params = [[V2NIMMessageRevokeParams alloc] init];
  params.serverExtension = [NECommonUtil getJSONStringFromDictionary:extension];
  __weak typeof(self) weakSelf = self;
  [[ChatRepo shared] revokeMessage:message params:params completion:^(NSError *error) {
    if (!error) [weakSelf revokeMessageUpdateUI:message];
    if (completion) completion(error);
  }];
}

- (void)revokeMessageWithMessage:(V2NIMMessage *)message
                                 :(void (^)(NSError *))completion {
  [self revokeMessage:message completion:completion];
}

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
  NSMutableArray *filtered = [NSMutableArray array];
  for (id value in messages ?: @[]) if ([value isKindOfClass:[V2NIMMessage class]] && [self isCurrentTopicMessage:value]) [filtered addObject:value];
  if (filtered.count == 0) return;
  for (V2NIMMessage *message in filtered) {
    if (message.messageServerId.length == 0 && message.messageType != V2NIM_MESSAGE_TYPE_CUSTOM) continue;
    if (message.messageClientId.length > 0 && [self.messageClientIds containsObject:message.messageClientId]) continue;
    if (message.messageClientId.length > 0) [self.messageClientIds addObject:message.messageClientId];
    if (!self.oldestMessage || message.createTime < self.oldestMessage.createTime) self.oldestMessage = message;
    if (!self.newestMessage || message.createTime > self.newestMessage.createTime) self.newestMessage = message;
    if ([ChatMessageHelper isAISender:message]) [self setErrorText:message];
    if (self.isHistoryChat) {
      [self.delegate onRecvMessages:filtered indexs:@[]];
      return;
    }
    __weak typeof(self) weakSelf = self;
    [self modelFromMessage:message completion:^(id<MessageModel> model) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !model) return;
      [ChatMessageHelper addTimeMessage:model lastModel:self.messages.lastObject];
      [self downloadAudioFile:@[model]];
      [self loadReply:model completion:^{
        NSInteger index = [self insertToMessages:model];
        if (index >= 0) {
          [self.delegate onRecvMessages:@[message] indexs:@[[NSIndexPath indexPathForRow:index inSection:0]]];
          [self loadMoreWithMessage:@[message]];
          if ([model isKindOfClass:[MessageTextModel class]]) {
            [self autoTranslateIfNeeded:(MessageTextModel *)model];
          }
        }
      }];
    }];
  }
}

- (void)onReceiveMessagesModified:(NSArray<V2NIMMessage *> *)messages {
  NSMutableArray<V2NIMMessage *> *filtered = [NSMutableArray array];
  for (id value in messages ?: @[]) {
    if ([value isKindOfClass:[V2NIMMessage class]] && [self isCurrentTopicMessage:value]) {
      [filtered addObject:value];
    }
  }
  for (V2NIMMessage *message in filtered) {
    for (NSInteger index = 0; index < self.messages.count; index++) {
      id<MessageModel> current = self.messages[index];
      if (![current isKindOfClass:[MessageContentModel class]] ||
          ![current.message.messageClientId isEqualToString:message.messageClientId]) continue;
      MessageContentModel *model = (MessageContentModel *)current;
      [model resetMessage:message];
      if (index > 0) [ChatMessageHelper addTimeMessage:model lastModel:self.messages[index - 1]];
      if ([self.delegate respondsToSelector:@selector(getMessageModel:)]) [self.delegate getMessageModel:model];
      self.messages[index] = model;
      [self.delegate onModefiedMessage:[NSIndexPath indexPathForRow:index inSection:0]];
      break;
    }
  }
}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
  NSMutableArray<V2NIMMessageRevokeNotification *> *filtered = [NSMutableArray array];
  for (id value in revokeNotifications ?: @[]) {
    if (![value isKindOfClass:[V2NIMMessageRevokeNotification class]]) continue;
    V2NIMMessageRefer *refer = [(V2NIMMessageRevokeNotification *)value messageRefer];
    if (![refer isKindOfClass:[V2NIMMessageRefer class]]) continue;
    for (id<MessageModel> model in [self.messages copy]) {
      if ([self isMessage:model.message matchingRefer:refer]) {
        [filtered addObject:value];
        break;
      }
    }
  }
  if (filtered.count > 0) [super onMessageRevokeNotifications:filtered];
}

- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)notifications {
  NSMutableArray<V2NIMMessageDeletedNotification *> *filtered = [NSMutableArray array];
  for (id value in notifications ?: @[]) {
    if (![value isKindOfClass:[V2NIMMessageDeletedNotification class]]) continue;
    V2NIMMessageRefer *refer = [(V2NIMMessageDeletedNotification *)value messageRefer];
    if (![refer isKindOfClass:[V2NIMMessageRefer class]] || !refer.messageClientId) continue;
    for (id<MessageModel> model in [self.messages copy]) {
      if ([model.message.messageClientId isEqualToString:refer.messageClientId] ||
          [[self replyMessageId:model.message] isEqualToString:refer.messageClientId]) {
        [filtered addObject:value];
        break;
      }
    }
  }
  if (filtered.count > 0) [super onMessageDeletedNotifications:filtered];
}

- (void)updateTopicName:(NSString *)name
                       :(void (^)(V2NIMTopic *, NSError *))completion {
  if (!self.topic) { if (completion) completion(nil, nil); return; }
  V2NIMUpdateTopicParams *params = [[V2NIMUpdateTopicParams alloc] init];
  params.topic = self.topic;
  params.topicName = [name isKindOfClass:[NSString class]] ? name : @"";
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] updateTopic:params :^(V2NIMTopic *topic, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if ([topic isKindOfClass:[V2NIMTopic class]]) {
      [self updateCurrentTopic:topic];
    }
    if (completion) completion(topic, error);
  }];
}

- (void)removeCurrentTopic:(void (^)(NSError *))completion {
  if (!self.topic) { if (completion) completion(nil); return; }
  V2NIMRemoveTopicsParams *params = [[V2NIMRemoveTopicsParams alloc] init];
  params.topicList = @[self.topic];
  self.removingCurrentTopic = YES;
  self.notifiedCurrentTopicRemoved = NO;
  __weak typeof(self) weakSelf = self;
  [[TopicRepo shared] removeTopics:params :^(NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    self.removingCurrentTopic = NO;
    if (!error) [self notifyCurrentTopicRemovedIfNeeded];
    if (completion) completion(error);
  }];
}

- (void)onTopicAdded:(V2NIMTopic *)topic {
  if (![topic isKindOfClass:[V2NIMTopic class]] || self.topic || !self.pendingAutoNameMessage) return;
  if (![self isPendingAutoNameTopic:topic]) return;
  [self updateCurrentTopic:topic];
}
- (void)onTopicUpdated:(V2NIMTopic *)topic {
  if (![topic isKindOfClass:[V2NIMTopic class]] || !self.topic ||
      topic.topicId != self.topic.topicId || topic.createTime != self.topic.createTime ||
      ![topic.conversationId isEqualToString:self.topic.conversationId]) return;
  [self updateCurrentTopic:topic];
}
- (void)onTopicsRemoved:(NSArray<V2NIMTopicRefer *> *)topics {
  for (id value in topics ?: @[]) {
    if (![value isKindOfClass:[V2NIMTopicRefer class]] || !self.topic) continue;
    V2NIMTopicRefer *refer = value;
    if (refer.topicId != self.topic.topicId ||
        ![refer.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
    if (!self.removingCurrentTopic) [self notifyCurrentTopicRemovedIfNeeded];
    break;
  }
}

@end
