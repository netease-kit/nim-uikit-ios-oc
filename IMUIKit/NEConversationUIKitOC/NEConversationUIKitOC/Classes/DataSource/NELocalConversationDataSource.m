// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELocalConversationDataSource.h"
#import <NEChatKit/LocalConversationRepo.h>
#import <NEChatKit/MultiDelegate.h>
#import <NIMSDK/NIMSDK.h>

@interface NELocalConversationDataSource () <NELocalConversationListener>
@property (nonatomic, strong) MultiDelegate *dataSourceMultiDelegate;
@end

@implementation NELocalConversationDataSource

@synthesize dataSourceType = _dataSourceType;

- (instancetype)init {
  if (self = [super init]) {
    _dataSourceType = NEConversationDataSourceTypeLocal;
    _dataSourceMultiDelegate = [[MultiDelegate alloc] initWithStrongReferences:NO];
    _repo = LocalConversationRepo.shared;
    [_repo addLocalConversationListener:self];
  }
  return self;
}

- (void)dealloc {
  [_repo removeLocalConversationListener:self];
}

#pragma mark - NEConversationDataSource: Listener

- (void)addDataSourceListener:(id<NEConversationDataSourceListener>)listener {
  [self.dataSourceMultiDelegate addDelegate:listener];
}

- (void)removeDataSourceListener:(id<NEConversationDataSourceListener>)listener {
  [self.dataSourceMultiDelegate removeDelegate:listener];
}

#pragma mark - NEConversationDataSource: Conversation List

- (void)getConversationList:(int64_t)offset
                      limit:(NSInteger)limit
                 completion:(void (^)(NSArray<NSString *> * _Nullable,
                                      NSNumber * _Nullable,
                                      NSNumber * _Nullable,
                                      NSError * _Nullable))completion {
  // LocalConversationRepo 的 offset 是 NSInteger，从 int64_t 安全截断
  NSInteger localOffset = (NSInteger)offset;
  [self.repo getConversationList:localOffset limit:limit completion:^(NSArray<V2NIMLocalConversation *> * _Nullable conversations, NSNumber * _Nullable newOffset, NSNumber * _Nullable finished, NSError * _Nullable error) {
    if (error) {
      completion(nil, nil, nil, error);
      return;
    }
    NSMutableArray<NSString *> *ids = [NSMutableArray arrayWithCapacity:conversations.count];
    for (V2NIMLocalConversation *conv in conversations) {
      [ids addObject:conv.conversationId];
    }
    completion([ids copy], newOffset, finished, nil);
  }];
}

#pragma mark - NEConversationDataSource: Get Conversations

- (void)getConversationInfo:(NSString *)conversationId
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
  [self.repo getConversation:conversationId completion:^(V2NIMLocalConversation * _Nullable conversation, NSError * _Nullable error) {
    if (error || !conversation) {
      completion(nil, error);
      return;
    }
    completion([self _infoFromLocalConversation:conversation], nil);
  }];
}

- (void)getRawConversationsByIds:(NSArray<NSString *> *)conversationIds
                      completion:(void (^)(NSArray * _Nullable, NSError * _Nullable))completion {
  [self.repo getConversationListByIds:conversationIds completion:^(NSArray<V2NIMLocalConversation *> * _Nullable conversations, NSError * _Nullable error) {
    completion(conversations, error);
  }];
}

#pragma mark - NEConversationDataSource: CRUD

- (void)deleteConversation:(NSString *)conversationId
              clearMessage:(BOOL)clearMessage
                completion:(void (^)(NSError * _Nullable))completion {
  [self.repo deleteConversation:conversationId clearMessage:clearMessage completion:completion];
}

- (void)createConversation:(NSString *)conversationId
                completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
  [self.repo createConversation:conversationId completion:^(V2NIMLocalConversation * _Nullable conversation, NSError * _Nullable error) {
    completion(conversation.conversationId, error);
  }];
}

#pragma mark - NEConversationDataSource: Stick Top

- (void)setStickTop:(NSString *)conversationId
           stickTop:(BOOL)stickTop
         completion:(void (^)(NSError * _Nullable))completion {
  [self.repo setStickTop:conversationId stickTop:stickTop completion:completion];
}

#pragma mark - NEConversationDataSource: Unread

- (NSInteger)getTotalUnreadCount {
  return [self.repo getTotalUnreadCount];
}

- (void)clearTotalUnreadCountWithCompletion:(void (^)(NSError * _Nullable))completion {
  // LocalConversationRepo.clearTotalUnreadCount 无 completion 参数，同步操作
  [self.repo clearTotalUnreadCount];
  if (completion) {
    completion(nil);
  }
}

- (void)clearUnreadCountByIds:(NSArray<NSString *> *)conversationIds
                   completion:(void (^)(NSError * _Nullable))completion {
  [self.repo clearUnreadCountByIds:conversationIds completion:^(NSArray<V2NIMLocalConversationOperationResult *> * _Nullable results, NSError * _Nullable error) {
    completion(error);
  }];
}

#pragma mark - NEConversationDataSource: Read Time

- (void)markConversationRead:(NSString *)conversationId
                  completion:(void (^)(NSNumber * _Nullable, NSError * _Nullable))completion {
  [self.repo markConversationRead:conversationId completion:completion];
}

#pragma mark - NELocalConversationListener → 转发为 DataSource events

- (void)onLocalConversationSyncStarted {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncStarted)]) {
      [d onDataSourceSyncStarted];
    }
  }];
}

- (void)onLocalConversationSyncFinished {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncFinished)]) {
      [d onDataSourceSyncFinished];
    }
  }];
}

- (void)onLocalConversationSyncFailed:(V2NIMError *)error {
  NSError *nsError = [NSError errorWithDomain:@"NEConversationDataSource"
                                         code:error.code
                                     userInfo:@{NSLocalizedDescriptionKey: error.desc ?: @""}];
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncFailed:)]) {
      [d onDataSourceSyncFailed:nsError];
    }
  }];
}

- (void)onLocalConversationCreated:(V2NIMLocalConversation *)conversation {
  NSString *cid = conversation.conversationId;
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationCreated:)]) {
      [d onDataSourceConversationCreated:cid];
    }
  }];
}

- (void)onLocalConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationDeleted:)]) {
      [d onDataSourceConversationDeleted:conversationIds];
    }
  }];
}

- (void)onLocalConversationChanged:(NSArray<V2NIMLocalConversation *> *)conversations {
  NSMutableArray<NSString *> *ids = [NSMutableArray arrayWithCapacity:conversations.count];
  for (V2NIMLocalConversation *c in conversations) {
    [ids addObject:c.conversationId];
  }
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationChanged:)]) {
      [d onDataSourceConversationChanged:[ids copy]];
    }
  }];
}

- (void)onLocalTotalUnreadCountChanged:(NSInteger)unreadCount {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceTotalUnreadCountChanged:)]) {
      [d onDataSourceTotalUnreadCountChanged:unreadCount];
    }
  }];
}

#pragma mark - Private: V2NIMLocalConversation → NSDictionary

- (NSDictionary *)_infoFromLocalConversation:(V2NIMLocalConversation *)conv {
  NSMutableDictionary *info = [NSMutableDictionary dictionary];
  info[@"conversationId"] = conv.conversationId ?: @"";
  info[@"type"] = @(conv.type);
  info[@"name"] = conv.name ?: @"";
  info[@"avatar"] = conv.avatar ?: @"";
  info[@"unreadCount"] = @(conv.unreadCount);
  info[@"stickTop"] = @(conv.stickTop);
  info[@"sortOrder"] = @(conv.sortOrder);
  info[@"mute"] = @(conv.mute);
  info[@"localExtension"] = conv.localExtension ?: @"";
  if (conv.lastMessage) {
    info[@"lastMessage"] = conv.lastMessage;
  }
  info[@"rawConversation"] = conv;
  return [info copy];
}

@end
