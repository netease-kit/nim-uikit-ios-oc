// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECloudConversationDataSource.h"
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/MultiDelegate.h>
#import <NIMSDK/NIMSDK.h>

@interface NECloudConversationDataSource () <NEConversationListener>
@property (nonatomic, strong) MultiDelegate *dataSourceMultiDelegate;
@end

@implementation NECloudConversationDataSource

@synthesize dataSourceType = _dataSourceType;

- (instancetype)init {
  if (self = [super init]) {
    _dataSourceType = NEConversationDataSourceTypeCloud;
    _dataSourceMultiDelegate = [[MultiDelegate alloc] initWithStrongReferences:NO];
    _repo = ConversationRepo.shared;
    [_repo addConversationListener:self];
  }
  return self;
}

- (void)dealloc {
  [_repo removeConversationListener:self];
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
  [self.repo getConversationList:offset limit:limit completion:^(NSArray<V2NIMConversation *> * _Nullable conversations, NSNumber * _Nullable newOffset, NSNumber * _Nullable finished, NSError * _Nullable error) {
    if (error) {
      completion(nil, nil, nil, error);
      return;
    }
    NSMutableArray<NSString *> *ids = [NSMutableArray arrayWithCapacity:conversations.count];
    for (V2NIMConversation *conv in conversations) {
      [ids addObject:conv.conversationId];
    }
    completion([ids copy], newOffset, finished, nil);
  }];
}

#pragma mark - NEConversationDataSource: Get Conversations

- (void)getConversationInfo:(NSString *)conversationId
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
  [self.repo getConversation:conversationId completion:^(V2NIMConversation * _Nullable conversation, NSError * _Nullable error) {
    if (error || !conversation) {
      completion(nil, error);
      return;
    }
    completion([self _infoFromCloudConversation:conversation], nil);
  }];
}

- (void)getRawConversationsByIds:(NSArray<NSString *> *)conversationIds
                      completion:(void (^)(NSArray * _Nullable, NSError * _Nullable))completion {
  [self.repo getConversationListByIds:conversationIds completion:^(NSArray<V2NIMConversation *> * _Nullable conversations, NSError * _Nullable error) {
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
  [self.repo createConversation:conversationId completion:^(V2NIMConversation * _Nullable conversation, NSError * _Nullable error) {
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
  [self.repo clearTotalUnreadCount:completion];
}

- (void)clearUnreadCountByIds:(NSArray<NSString *> *)conversationIds
                   completion:(void (^)(NSError * _Nullable))completion {
  [self.repo clearUnreadCountByIds:conversationIds completion:^(NSArray<V2NIMConversationOperationResult *> * _Nullable results, NSError * _Nullable error) {
    completion(error);
  }];
}

#pragma mark - NEConversationDataSource: Read Time

- (void)markConversationRead:(NSString *)conversationId
                  completion:(void (^)(NSNumber * _Nullable, NSError * _Nullable))completion {
  [self.repo markConversationRead:conversationId completion:completion];
}

#pragma mark - NEConversationListener → 转发为 DataSource events

- (void)onConversationSyncStarted {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncStarted)]) {
      [d onDataSourceSyncStarted];
    }
  }];
}

- (void)onConversationSyncFinished {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncFinished)]) {
      [d onDataSourceSyncFinished];
    }
  }];
}

- (void)onConversationSyncFailed:(V2NIMError *)error {
  NSError *nsError = [NSError errorWithDomain:@"NEConversationDataSource"
                                         code:error.code
                                     userInfo:@{NSLocalizedDescriptionKey: error.desc ?: @""}];
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceSyncFailed:)]) {
      [d onDataSourceSyncFailed:nsError];
    }
  }];
}

- (void)onConversationCreated:(V2NIMConversation *)conversation {
  NSString *cid = conversation.conversationId;
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationCreated:)]) {
      [d onDataSourceConversationCreated:cid];
    }
  }];
}

- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationDeleted:)]) {
      [d onDataSourceConversationDeleted:conversationIds];
    }
  }];
}

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  NSMutableArray<NSString *> *ids = [NSMutableArray arrayWithCapacity:conversations.count];
  for (V2NIMConversation *c in conversations) {
    [ids addObject:c.conversationId];
  }
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationChanged:)]) {
      [d onDataSourceConversationChanged:[ids copy]];
    }
  }];
}

- (void)onConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationUnreadCountCleared:)]) {
      [d onDataSourceConversationUnreadCountCleared:conversationIds];
    }
  }];
}

- (void)onConversationReadTimeUpdated:(NSString *)conversationId readTime:(NSTimeInterval)readTime {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceConversationReadTimeUpdated:readTime:)]) {
      [d onDataSourceConversationReadTimeUpdated:conversationId readTime:readTime];
    }
  }];
}

- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount {
  [self.dataSourceMultiDelegate invokeDelegates:^(id<NEConversationDataSourceListener> d) {
    if ([d respondsToSelector:@selector(onDataSourceTotalUnreadCountChanged:)]) {
      [d onDataSourceTotalUnreadCountChanged:unreadCount];
    }
  }];
}

#pragma mark - Private: V2NIMConversation → NSDictionary

- (NSDictionary *)_infoFromCloudConversation:(V2NIMConversation *)conv {
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
