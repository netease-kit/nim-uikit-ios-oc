// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAtMessageManager.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ConversationRepo.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NECommonUtil.h>
#import <NEChatKitOC/NEPathUtils.h>

NSString *const NEAtMessageChangeNoti = @"at_message_change_noti";

static NSString *const kAtAllKey = @"ait_all";
static NSString *const kYxAtMsg = @"yxAitMsg";
static NSString *const kAtMessageCacheSuffix = @"_at_message_cloud.plist";

@interface NEAtMessageRecord : NSObject
@property (nonatomic, assign) BOOL isRead;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *atMessages;
@property (nonatomic, strong, nullable) NSNumber *lastTime;
@end

@implementation NEAtMessageRecord

- (instancetype)init {
  self = [super init];
  if (self) {
    _isRead = YES;
    _atMessages = [NSMutableDictionary dictionary];
  }
  return self;
}

@end

@interface NEAtMessageManager ()
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NEAtMessageRecord *> *atMessageDic;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, copy) NSString *currentAccid;
@end

@implementation NEAtMessageManager

+ (instancetype)sharedManager {
  static NEAtMessageManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] initPrivate];
  });
  return instance;
}

+ (void)setupInstance {
  [self sharedManager];
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _lock = [[NSLock alloc] init];
    _atMessageDic = [NSMutableDictionary dictionary];
    _workQueue = dispatch_queue_create("com.netease.imuikit.atmessage", DISPATCH_QUEUE_SERIAL);
    _currentAccid = [IMKitClient.instance account] ?: @"";

    [ChatRepo.shared addChatListener:self];
    [IMKitClient.instance addLoginListener:self];

    if (_currentAccid.length > 0) {
      [self loadCacheFromDocument];
    }
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
  NEAtMessageRecord *record = self.atMessageDic[conversationId];
  BOOL result = (record && !record.isRead);
  [self.lock unlock];
  return result;
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
    NEAtMessageRecord *record = self.atMessageDic[conversationId];
    if (record && (!record.isRead || record.atMessages.count > 0)) {
      record.isRead = YES;
      [record.atMessages removeAllObjects];
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
  if (status == V2NIM_LOGIN_STATUS_LOGINED) {
    self.currentAccid = [IMKitClient.instance account] ?: @"";
    [self.lock lock];
    [self.atMessageDic removeAllObjects];
    [self.lock unlock];
    [self loadCacheFromDocument];
  } else if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    self.currentAccid = @"";
    [self.lock lock];
    [self.atMessageDic removeAllObjects];
    [self.lock unlock];
  }
}

#pragma mark - NEChatListener

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
  if (![IMKitConfigCenter shared].enableAtMessage || messages.count == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    BOOL changed = [self filterAtMessagesInWorkQueue:messages];
    if (!changed) {
      return;
    }

    NSDictionary *snapshot = [self serializedRecords];
    [self writeCacheToDocument:snapshot];
    [self postAtMessageChangeNotification];
  });
}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
  if (revokeNotifications.count == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(self.workQueue, ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    BOOL changed = NO;
    for (V2NIMMessageRevokeNotification *notification in revokeNotifications) {
      V2NIMMessageRefer *refer = notification.messageRefer;
      if (refer.messageClientId.length == 0 || refer.conversationId.length == 0) {
        continue;
      }
      if ([refer.senderId isEqualToString:self.currentAccid]) {
        continue;
      }
      if ([self removeRecordWithMessageRefer:refer]) {
        changed = YES;
      }
    }

    if (!changed) {
      return;
    }

    NSDictionary *snapshot = [self serializedRecords];
    [self writeCacheToDocument:snapshot];
    [self postAtMessageChangeNotification];
  });
}

#pragma mark - Private

- (BOOL)filterAtMessagesInWorkQueue:(NSArray<V2NIMMessage *> *)messages {
  BOOL changed = NO;
  NSString *currentAccid = self.currentAccid.length > 0 ? self.currentAccid : [IMKitClient.instance account];
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

    if ([self addAtRecordWithCompare:message]) {
      changed = YES;
    }
  }

  return changed;
}

- (BOOL)addAtRecordWithCompare:(V2NIMMessage *)message {
  if (message.conversationId.length == 0 || message.messageClientId.length == 0) {
    return NO;
  }

  __block NSNumber *readTime = nil;
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [ConversationRepo.shared getConversationReadTime:message.conversationId
                                        completion:^(NSNumber * _Nullable time, NSError * _Nullable error) {
    readTime = time;
    dispatch_semaphore_signal(semaphore);
  }];
  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

  if (readTime && message.createTime <= readTime.doubleValue) {
    return NO;
  }

  BOOL changed = NO;
  [self.lock lock];
  NEAtMessageRecord *record = self.atMessageDic[message.conversationId];
  if (!record) {
    record = [[NEAtMessageRecord alloc] init];
    self.atMessageDic[message.conversationId] = record;
  }

  double lastTime = record.lastTime.doubleValue;
  NSNumber *messageTime = @(message.createTime);
  if (record.atMessages[message.messageClientId] == nil || lastTime < message.createTime) {
    record.isRead = NO;
    record.lastTime = messageTime;
    record.atMessages[message.messageClientId] = messageTime;
    changed = YES;
  }
  [self.lock unlock];
  return changed;
}

- (BOOL)removeRecordWithMessageRefer:(V2NIMMessageRefer *)messageRefer {
  BOOL changed = NO;
  [self.lock lock];
  NEAtMessageRecord *record = self.atMessageDic[messageRefer.conversationId];
  if (record.atMessages[messageRefer.messageClientId] != nil) {
    [record.atMessages removeObjectForKey:messageRefer.messageClientId];
    if (record.atMessages.count <= 0) {
      record.isRead = YES;
    }
    changed = YES;
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
  [self.atMessageDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull conversationId, NEAtMessageRecord * _Nonnull record, BOOL * _Nonnull stop) {
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
  return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", self.currentAccid, kAtMessageCacheSuffix]];
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
  NSString *filePath = [self cacheFilePath];
  if (filePath.length == 0) {
    return;
  }

  NSData *data = [NSData dataWithContentsOfFile:filePath];
  if (data.length == 0) {
    return;
  }

  NSError *error = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  if (error || ![jsonObject isKindOfClass:[NSDictionary class]]) {
    return;
  }

  NSMutableDictionary<NSString *, NEAtMessageRecord *> *records = [NSMutableDictionary dictionary];
  [(NSDictionary *)jsonObject enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[NSDictionary class]]) {
      return;
    }

    NSDictionary *recordJson = (NSDictionary *)obj;
    NEAtMessageRecord *record = [[NEAtMessageRecord alloc] init];
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
}

@end
