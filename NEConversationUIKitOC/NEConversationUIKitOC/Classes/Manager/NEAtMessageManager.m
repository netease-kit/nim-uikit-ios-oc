// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAtMessageManager.h"
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/LocalConversationRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NECommonUtil.h>
#import <NEChatKit/NEPathUtils.h>

NSString *const NEAtMessageChangeNoti = @"at_message_change_noti";

static NSString *const kAtAllKey = @"ait_all";
static NSString *const kYxAtMsg = @"yxAitMsg";
static NEAtMessageManager *gAtMessageManager = nil;

@implementation AtMEMessageRecord

- (instancetype)init {
  self = [super init];
  if (self) {
    _isRead = NO;
    _atMessages = [NSMutableDictionary dictionary];
  }
  return self;
}

@end

@implementation AtMessageModel
@end

@interface NEAtMessageManager ()
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AtMEMessageRecord *> *atMessageDic;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, copy) NSString *currentAccid;
@end

@implementation NEAtMessageManager

+ (NEAtMessageManager *)instance {
  return gAtMessageManager;
}

+ (void)setInstance:(NEAtMessageManager *)instance {
  gAtMessageManager = instance;
}

+ (instancetype)sharedManager {
  [self setupInstance];
  return self.instance;
}

+ (void)setupInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gAtMessageManager = [[self alloc] initPrivate];
  });
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _lock = [[NSLock alloc] init];
    _atMessageDic = [NSMutableDictionary dictionary];
    _workQueue = dispatch_queue_create("com.netease.imuikit.atmessage", DISPATCH_QUEUE_SERIAL);
    _currentAccid = @"";

    [ChatRepo.shared addChatListener:self];
    [IMKitClient.instance addLoginListener:self];
  }
  return self;
}

- (void)dealloc {
  [ChatRepo.shared removeChatListener:self];
  [IMKitClient.instance removeLoginListener:self];
}

#pragma mark - Public

- (BOOL)isAtCurrentUserConversationId:(NSString *)conversationId {
  if (conversationId.length == 0) {
    return NO;
  }

  [self.lock lock];
  AtMEMessageRecord *record = self.atMessageDic[conversationId];
  BOOL result = (record && !record.isRead);
  [self.lock unlock];
  return result;
}

- (BOOL)isAtCurrentUser:(NSString *)conversationId {
  return [self isAtCurrentUserConversationId:conversationId];
}

- (BOOL)isAtCurrentUserWithConversationId:(NSString *)conversationId {
  return [self isAtCurrentUserConversationId:conversationId];
}

- (void)clearAtRecord:(NSString *)conversationId {
  if (conversationId.length == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    NSDictionary *snapshot = nil;
    BOOL changed = NO;

    [self.lock lock];
    AtMEMessageRecord *record = self.atMessageDic[conversationId];
    if (record && (!record.isRead || record.atMessages.count > 0)) {
      record.isRead = YES;
      [record.atMessages removeAllObjects];
      record.lastTime = nil;
      snapshot = [self serializedRecordsLocked];
      changed = YES;
    }
    [self.lock unlock];

    if (changed) {
      [self writeCacheToDocument:snapshot];
      [self postAtMessageChangeNotification];
    }
  });
}

#pragma mark - NEIMKitClientListener

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    if (status == V2NIM_LOGIN_STATUS_LOGINED) {
      self.currentAccid = [IMKitClient.instance account] ?: @"";
      [self.lock lock];
      [self.atMessageDic removeAllObjects];
      [self.lock unlock];
      [self loadCacheFromDocument];
    } else if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
      [self.lock lock];
      BOOL hadRecords = self.atMessageDic.count > 0;
      [self.atMessageDic removeAllObjects];
      [self.lock unlock];
      self.currentAccid = @"";
      if (hadRecords) {
        [self postAtMessageChangeNotification];
      }
    }
  });
}

- (void)onDataSync:(V2NIMDataSyncType)type
             state:(V2NIMDataSyncState)state
             error:(V2NIMError *)error {
  if (state == V2NIM_DATA_SYNC_STATE_COMPLETED && self.currentAccid.length == 0) {
    self.currentAccid = [IMKitClient.instance account] ?: @"";
  }
}

#pragma mark - NEChatListener

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
  [self filterAtMessage:messages];
}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
  if (revokeNotifications.count == 0) {
    return;
  }

  NSMutableArray<V2NIMMessageRefer *> *refers = [NSMutableArray array];
  for (V2NIMMessageRevokeNotification *notification in revokeNotifications) {
    if (notification.messageRefer) {
      [refers addObject:notification.messageRefer];
    }
  }
  if (refers.count > 0) {
    [self removeRevokeAtMessage:refers];
  }
}

#pragma mark - Private

- (void)filterAtMessage:(NSArray<V2NIMMessage *> *)messages {
  if (![IMKitConfigCenter shared].enableAtMessage || messages.count == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    if ([self filterAtMessagesInWorkQueue:messages]) {
      [self postAtMessageChangeNotification];
      [self writeCacheToDocument:[self serializedRecords]];
    }
  });
}

- (void)filterAtMessageWithMessages:(NSArray<V2NIMMessage *> *)messages {
  [self filterAtMessage:messages];
}

- (void)startFilterRoamingMessagesTask {
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    [weakSelf startFilterRoamingMessagesTaskInWorkQueue];
  });
}

- (void)startFilterRoamingMessagesTaskInWorkQueue {
  [self getAllConversation:@[] offset:0 completion:^(NSArray<V2NIMConversation *> *conversations, NSError *error) {
    if (error || conversations.count == 0) return;

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.netease.imuikit.atmessage.roaming", DISPATCH_QUEUE_SERIAL);
    NSMutableDictionary<NSString *, AtMEMessageRecord *> *records = [NSMutableDictionary dictionary];
    [self.lock lock];
    [self.atMessageDic enumerateKeysAndObjectsUsingBlock:^(NSString *conversationId, AtMEMessageRecord *record, BOOL *stop) {
      AtMEMessageRecord *recordCopy = [[AtMEMessageRecord alloc] init];
      recordCopy.isRead = record.isRead;
      recordCopy.lastTime = record.lastTime;
      recordCopy.atMessages = [record.atMessages mutableCopy];
      records[conversationId] = recordCopy;
    }];
    [self.lock unlock];
    __block BOOL found = NO;
    NSString *account = self.currentAccid.length > 0 ? self.currentAccid : [IMKitClient.instance account];

    for (V2NIMConversation *conversation in conversations) {
      if (conversation.type != V2NIM_CONVERSATION_TYPE_TEAM) continue;
      if (conversation.conversationId.length == 0) continue;
      dispatch_group_enter(group);
      V2NIMMessageListOption *option = [[V2NIMMessageListOption alloc] init];
      option.limit = 100;
      option.conversationId = conversation.conversationId;
      option.strictMode = NO;
      [[ChatRepo shared] getMessageListWithOption:option completion:^(NSArray<V2NIMMessage *> *messages, NSError *messageError) {
        dispatch_async(queue, ^{
          if (!messageError) {
            for (V2NIMMessage *message in messages ?: @[]) {
              NSDictionary *remoteExt = [NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""];
              NSDictionary *atInfo = [remoteExt[kYxAtMsg] isKindOfClass:[NSDictionary class]] ? remoteExt[kYxAtMsg] : nil;
              if (!atInfo) continue;
              BOOL isAtAll = atInfo[kAtAllKey] != nil && ![message.senderId isEqualToString:account];
              BOOL isAtMe = account.length > 0 && atInfo[account] != nil;
              if (!isAtAll && !isAtMe) continue;
              if ([self addAtRecordWithCompare:message toRecords:records]) found = YES;
            }
          }
          dispatch_group_leave(group);
        });
      }];
    }

    dispatch_group_notify(group, self.workQueue, ^{
      if (!found) return;
      [self.lock lock];
      self.atMessageDic = records;
      [self.lock unlock];
      [self writeCacheToDocument:[self serializedRecords]];
      [self postAtMessageChangeNotification];
    });
  }];
}

- (void)getAllConversation:(NSArray<V2NIMConversation *> *)conversations
                    offset:(int64_t)offset
                completion:(void (^)(NSArray<V2NIMConversation *> *conversations, NSError *error))completion {
  [[ConversationRepo shared] getConversationList:offset limit:20 completion:^(NSArray<V2NIMConversation *> *list, NSNumber *nextOffset, NSNumber *finished, NSError *error) {
    if (error) {
      if (completion) completion(conversations ?: @[], error);
      return;
    }
    NSMutableArray *all = [conversations mutableCopy] ?: [NSMutableArray array];
    [all addObjectsFromArray:list ?: @[]];
    if (!finished.boolValue && nextOffset != nil) {
      [self getAllConversation:all offset:nextOffset.longLongValue completion:completion];
    } else if (completion) {
      completion(all, nil);
    }
  }];
}

- (BOOL)filterAtMessagesInWorkQueue:(NSArray<V2NIMMessage *> *)messages {
  BOOL changed = NO;
  NSString *currentAccid = [IMKitClient.instance account] ?: @"";
  if (currentAccid.length == 0) {
    return NO;
  }

  for (V2NIMMessage *message in messages) {
    NSDictionary *remoteExt = [NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""];
    NSDictionary *atInfo = [remoteExt[kYxAtMsg] isKindOfClass:[NSDictionary class]] ? remoteExt[kYxAtMsg] : nil;
    if (!atInfo) {
      continue;
    }

    BOOL isAtAll = (atInfo[kAtAllKey] != nil) && ![message.senderId isEqualToString:currentAccid];
    BOOL isAtMe = (atInfo[currentAccid] != nil);
    if (!isAtAll && !isAtMe) {
      continue;
    }

    if ([self addAtRecordWithCompare:message toRecords:self.atMessageDic]) {
      changed = YES;
    }
  }

  return changed;
}

- (BOOL)addAtRecordWithCompare:(V2NIMMessage *)message toRecords:(NSMutableDictionary<NSString *, AtMEMessageRecord *> *)records {
  if (message.conversationId.length == 0 || message.messageClientId.length == 0) {
    return NO;
  }

  __block NSNumber *readTime = nil;
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation) {
    [ConversationRepo.shared getConversationReadTime:message.conversationId
                                          completion:^(NSNumber * _Nullable time, NSError * _Nullable error) {
      readTime = time;
      dispatch_semaphore_signal(semaphore);
    }];
  } else {
    [LocalConversationRepo.shared getConversationReadTime:message.conversationId
                                               completion:^(NSNumber * _Nullable time, NSError * _Nullable error) {
      readTime = time;
      dispatch_semaphore_signal(semaphore);
    }];
  }
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  double compareTime = readTime.doubleValue;
  if (message.createTime <= compareTime) {
    return NO;
  }

  BOOL changed = NO;
  [self.lock lock];
  AtMEMessageRecord *record = records[message.conversationId];
  if (!record) {
    record = [[AtMEMessageRecord alloc] init];
    records[message.conversationId] = record;
  }

  if (record.atMessages[message.messageClientId] != nil) {
    [self.lock unlock];
    return NO;
  }

  NSNumber *messageTime = @(message.createTime);
  record.isRead = NO;
  record.lastTime = @(MAX(record.lastTime.doubleValue, message.createTime));
  record.atMessages[message.messageClientId] = messageTime;
  changed = YES;
  [self.lock unlock];
  return changed;
}

- (BOOL)removeRecordWithMessageRefer:(V2NIMMessageRefer *)messageRefer {
  BOOL changed = NO;
  [self.lock lock];
  AtMEMessageRecord *record = self.atMessageDic[messageRefer.conversationId];
  if (record.atMessages[messageRefer.messageClientId] != nil) {
    [record.atMessages removeObjectForKey:messageRefer.messageClientId];
    changed = YES;
    if (record.atMessages.count <= 0) {
      record.isRead = YES;
      record.lastTime = nil;
    } else {
      NSNumber *latestTime = nil;
      for (NSNumber *messageTime in record.atMessages.allValues) {
        if (!latestTime || messageTime.doubleValue > latestTime.doubleValue) {
          latestTime = messageTime;
        }
      }
      record.lastTime = latestTime;
    }
  }
  [self.lock unlock];
  return changed;
}

- (void)postAtMessageChangeNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NEAtMessageChangeNoti object:nil];
  });
}

- (NSDictionary<NSString *, NSDictionary *> *)serializedRecords {
  [self.lock lock];
  NSDictionary *snapshot = [self serializedRecordsLocked];
  [self.lock unlock];
  return snapshot;
}

- (NSDictionary<NSString *, NSDictionary *> *)serializedRecordsLocked {
  NSMutableDictionary<NSString *, NSDictionary *> *result = [NSMutableDictionary dictionary];
  [self.atMessageDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull conversationId, AtMEMessageRecord * _Nonnull record, BOOL * _Nonnull stop) {
    result[conversationId] = @{
      @"isRead": @(record.isRead),
      @"lastTime": record.lastTime ?: @0,
      @"atMessages": record.atMessages ?: @{}
    };
  }];
  return result;
}

- (NSString *)cacheFilePath {
  if (self.currentAccid.length == 0) {
    return @"";
  }

  NSString *directory = [NEPathUtils getDirectoryForDocuments:imkitDir] ?: @"";
  if (directory.length == 0) {
    return @"";
  }
  NSString *suffix = [NIMSDK sharedSDK].v2Option.enableV2CloudConversation
      ? @"_at_message_cloud.plist"
      : @"_at_message_local.plist";
  return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", self.currentAccid, suffix]];
}

- (NSString *)legacyCacheFilePath {
  if (self.currentAccid.length == 0) return @"";
  NSString *directory = [NEPathUtils getDirectoryForDocuments:imkitDir] ?: @"";
  if (directory.length == 0) return @"";
  return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_at_message.plist", self.currentAccid]];
}

- (void)writeCacheToDocument:(NSDictionary<NSString *, NSDictionary *> *)snapshot {
  NSString *filePath = [self cacheFilePath];
  if (filePath.length == 0 || !snapshot) {
    return;
  }

  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:snapshot options:0 error:&error];
  if (error || !data) {
    return;
  }

  [data writeToFile:filePath atomically:YES];
}

- (void)loadCacheFromDocument {
  NSString *directory = [NEPathUtils getDirectoryForDocuments:imkitDir] ?: @"";
  NSString *filePath = [self cacheFilePath];
  if (directory.length == 0 || filePath.length == 0) {
    return;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
  }

  NSString *sourceFilePath = filePath;
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  if (data.length == 0) {
    NSString *legacyPath = [self legacyCacheFilePath];
    NSData *legacyData = [NSData dataWithContentsOfFile:legacyPath];
    if (legacyData.length > 0) {
      sourceFilePath = legacyPath;
      data = legacyData;
    }
  }
  if (data.length == 0) {
    return;
  }

  NSError *error = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  if (error || ![jsonObject isKindOfClass:[NSDictionary class]]) {
    return;
  }

  NSMutableDictionary<NSString *, AtMEMessageRecord *> *records = [NSMutableDictionary dictionary];
  [(NSDictionary *)jsonObject enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[NSDictionary class]]) {
      return;
    }

    NSDictionary *recordJson = (NSDictionary *)obj;
    AtMEMessageRecord *record = [[AtMEMessageRecord alloc] init];
    record.isRead = [recordJson[@"isRead"] boolValue];
    record.lastTime = [recordJson[@"lastTime"] isKindOfClass:[NSNumber class]] ? recordJson[@"lastTime"] : nil;
    NSDictionary *atMessages = [recordJson[@"atMessages"] isKindOfClass:[NSDictionary class]] ? recordJson[@"atMessages"] : nil;
    if (atMessages.count > 0) {
      [atMessages enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull messageId, id  _Nonnull time, BOOL * _Nonnull stop) {
        if ([messageId isKindOfClass:[NSString class]] && [time isKindOfClass:[NSNumber class]]) {
          record.atMessages[messageId] = time;
        }
      }];
    }
    records[(NSString *)key] = record;
  }];

  [self.lock lock];
  self.atMessageDic = records;
  [self.lock unlock];

  if (![sourceFilePath isEqualToString:filePath]) {
    [self writeCacheToDocument:[self serializedRecords]];
  }
  [self postAtMessageChangeNotification];
}

- (void)removeRevokeAtMessage:(NSArray<V2NIMMessageRefer *> *)messages {
  if (messages.count == 0) return;
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    NSString *account = [IMKitClient.instance account] ?: @"";
    BOOL changed = NO;
    for (V2NIMMessageRefer *refer in messages) {
      if (refer.messageClientId.length == 0 || refer.conversationId.length == 0) continue;
      if ([refer.senderId isEqualToString:account]) continue;
      if ([self removeRecordWithMessageRefer:refer]) changed = YES;
    }
    if (!changed) return;
    [self postAtMessageChangeNotification];
    [self writeCacheToDocument:[self serializedRecords]];
  });
}

- (void)removeRevokeAtMessageWithMessages:(NSArray<V2NIMMessageRefer *> *)messages {
  [self removeRevokeAtMessage:messages];
}

@end
