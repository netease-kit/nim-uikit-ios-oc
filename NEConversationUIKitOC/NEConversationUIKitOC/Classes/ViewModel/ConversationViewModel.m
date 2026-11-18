// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationViewModel.h"
#import "NEAtMessageManager.h"
#import "NEConversationListModel.h"
#import "NECloudConversationDataSource.h"
#import "NELocalConversationDataSource.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEAIUserModel.h>
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatKit/NEAIUserPinManager.h>
#import <NEChatKit/NESubscribeManager.h>
#import <NEChatKit/SubscribeRepo.h>
#import <NEChatKit/TeamRepo.h>

#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEAIRobotManager.h>

static NSString * const kClassName = @"ConversationViewModel";

@interface ConversationViewModel () <NEIMKitClientListener, NETeamListener, NEContactListener, NESubscribeListener, AIUserPinListener, AIUserChangeListener>

/// 网络断开标志
@property (nonatomic, assign) BOOL networkBroken;

/// 同步完成前暂存的回调
@property (nonatomic, copy, nullable) ConversationCallBack pendingCallBack;

/// 单聊账号 id
@property (nonatomic, strong) NSMutableSet<NSString *> *p2pAccountIds;

/// Snapshot/event ordering mirrors Swift ConversationViewModel.
@property (nonatomic, assign) uint64_t conversationStateVersion;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *conversationEventVersions;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *deletedConversationEventVersions;

- (void)executeOnMain:(dispatch_block_t)work;
- (void)retrieveConversationDatasWithCompletion:(nullable ConversationCallBack)completion;
- (void)recordConversationUpdate:(NSString *)conversationId;
- (void)recordConversationDeletion:(NSString *)conversationId;
- (BOOL)canApplySnapshotForConversationId:(NSString *)conversationId requestVersion:(uint64_t)requestVersion;
- (void)applyRawConversation:(id)rawConv conversationId:(NSString *)conversationId isAdd:(BOOL)isAdd requestVersion:(uint64_t)requestVersion;
- (void)backfillP2PConversationProfiles:(NSArray<NSString *> *)accountIds requestVersion:(uint64_t)requestVersion;
- (void)refreshConversationNameIfNeeded:(id)rawConversation conversationId:(NSString *)conversationId;
- (void)refreshP2PConversationsForAccountIds:(NSArray<NSString *> *)accountIds;
- (void)refreshRawConversationsForConversationIds:(NSArray<NSString *> *)conversationIds;
- (void)subscribeOnlineStatus:(NSArray<NSString *> *)accountIds notifyOnCachedChange:(BOOL)notifyOnCachedChange;

@end

@implementation ConversationViewModel

#pragma mark - 初始化

- (instancetype)initWithDataSource:(id<NEConversationDataSource>)dataSource {
  if (self = [super init]) {
    _dataSource = dataSource;
    _offset = 0;
    _page = 50;
    _syncFinished = NO;
    _networkBroken = NO;
    _conversationListData = [NSMutableArray array];
    _aiUserListData = [NSMutableArray array];
    _conversationDic = [NSMutableDictionary dictionary];
    _onlineStatusDic = [NSMutableDictionary dictionary];
    _p2pAccountIds = [NSMutableSet set];
    _conversationEventVersions = [NSMutableDictionary dictionary];
    _deletedConversationEventVersions = [NSMutableDictionary dictionary];
    _conversationStateVersion = 0;

    // 注册 DataSource 监听
    [_dataSource addDataSourceListener:self];

    // 注册 Team / Contact / Login 监听
    [[TeamRepo shared] addTeamListener:self];
    [[ContactRepo shared] addContactListener:self];
    [IMKitClient.instance addLoginListener:self];
    [[NEAIUserPinManager shared] addPinManagerListener:self];
    [[NEAIUserManager shared] addAIUserChangeListener:self];
    if ([IMKitConfigCenter shared].enableOnlineStatus) {
      [[SubscribeRepo shared] addListener:self];
    }

    // 监听删除会话通知（对齐 Swift deleteConversationNotificationName）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleDeleteConversationNoti:)
                                                 name:NENotificationDeleteConversation
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleAtMessageChangeNoti:)
                                               name:NEAtMessageChangeNoti
                                             object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleRobotDidRemove:)
                                               name:[NEAIRobotManager robotDidRemoveNotification]
                                             object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleRobotDisplayInfoDidChange:)
                                                 name:[NEAIRobotManager robotDisplayInfoDidChangeNotification]
                                               object:nil];
  }
  return self;
}

- (void)_handleRobotDidRemove:(NSNotification *)notification {
  NSString *accountId = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
  NSString *conversationId = accountId.length > 0 ? [V2NIMConversationIdUtil p2pConversationId:accountId] : nil;
  if (conversationId.length == 0 || !self.conversationDic[conversationId]) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
}

- (void)_handleRobotDisplayInfoDidChange:(NSNotification *)notification {
  NSArray<NSString *> *accountIds = [notification.object isKindOfClass:[NSArray class]]
      ? notification.object
      : nil;
  for (NSString *accountId in accountIds) {
    NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
    if (conversationId.length > 0 && self.conversationDic[conversationId]) {
      [self.delegate reloadTableView];
      return;
    }
  }
}

+ (instancetype)cloudViewModel {
  NECloudConversationDataSource *ds = [[NECloudConversationDataSource alloc] init];
  return [[self alloc] initWithDataSource:ds];
}

+ (instancetype)localViewModel {
  NELocalConversationDataSource *ds = [[NELocalConversationDataSource alloc] init];
  return [[self alloc] initWithDataSource:ds];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_dataSource removeDataSourceListener:self];
  [[TeamRepo shared] removeTeamListener:self];
  [[ContactRepo shared] removeContactListener:self];
  [IMKitClient.instance removeLoginListener:self];
  [[NEAIUserPinManager shared] removePinManagerListener:self];
  [[NEAIUserManager shared] removeAIUserChangeListener:self];
  if ([IMKitConfigCenter shared].enableOnlineStatus) {
    [self unsubscribeOnlineStatus];
    [[SubscribeRepo shared] removeListener:self];
  }
}

#pragma mark - 数据获取

- (void)getAIUserList {
  if ([IMKitConfigCenter shared].enableAIUser) {
    [[NEAIUserManager shared] getAIUserList];
  }
}

- (void)getConversationListByPage:(ConversationCallBack)completion {
  if (![NSThread isMainThread]) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf getConversationListByPage:completion];
    });
    return;
  }
  if (!self.syncFinished) {
    self.pendingCallBack = completion;
  }
  uint64_t requestVersion = self.conversationStateVersion;

  NSLog(@"%@ [Performance] getConversationListByPage start, syncFinished:%d", kClassName, self.syncFinished);

  __weak typeof(self) weakSelf = self;
  [self.dataSource getConversationList:self.offset
                                 limit:self.page
                            completion:^(NSArray<NSString *> * _Nullable conversationIds,
                                         NSNumber * _Nullable newOffset,
                                         NSNumber * _Nullable finished,
                                         NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;

    NSLog(@"%@ [Performance] getConversationList onSuccess, syncFinished:%d, count:%lu",
          kClassName, self.syncFinished, (unsigned long)conversationIds.count);

    dispatch_async(dispatch_get_main_queue(), ^{
      if (!error) {
        // Swift updates offset whenever the SDK supplies one, including an empty page.
      if (newOffset) {
        self.offset = newOffset.longLongValue;
      }

      // 通过 DataSource 获取原始对象并建模
      [self.dataSource getRawConversationsByIds:conversationIds
                                    completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable rawError) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (rawError || !rawConversations) {
            completion(rawError, finished);
            return;
          }

          for (id rawConv in rawConversations) {
            NSString *cid = [self _conversationIdFromRaw:rawConv];
            if (!cid) continue;
            if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
              if (![self canApplySnapshotForConversationId:cid requestVersion:requestVersion]) continue;
              [self applyRawConversation:rawConv conversationId:cid isAdd:NO requestVersion:requestVersion];
            } else {
              [self _addOrUpdateWithRawConversation:rawConv conversationId:cid isAdd:NO];
            }
            if ([self _conversationTypeFromRaw:rawConv] == V2NIM_CONVERSATION_TYPE_P2P) {
              NSString *targetId = [V2NIMConversationIdUtil conversationTargetId:cid];
              if (targetId.length > 0) [self.p2pAccountIds addObject:targetId];
            }
          }

          if ([IMKitConfigCenter shared].enableOnlineStatus && self.p2pAccountIds.count > 0) {
            [self subscribeOnlineStatus:self.p2pAccountIds.allObjects notifyOnCachedChange:NO];
          }
          [self.delegate reloadTableView];
          completion(nil, finished);
          NSArray<NSString *> *p2pAccountIds = self.p2pAccountIds.allObjects;
          uint64_t backfillRequestVersion = self.conversationStateVersion;
          [self backfillP2PConversationProfiles:p2pAccountIds requestVersion:backfillRequestVersion];
        });
      }];
      } else {
        completion(error, finished);
      }
    });
  }];
}

- (void)retrieveConversationDatas {
  [self retrieveConversationDatasWithCompletion:nil];
}

- (void)retrieveConversationDatasWithCompletion:(ConversationCallBack)completion {
  if (![NSThread isMainThread]) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf retrieveConversationDatasWithCompletion:completion];
    });
    return;
  }
  NSInteger limit = self.conversationDic.count > (NSUInteger)self.page ? self.conversationDic.count : self.page;
  uint64_t requestVersion = self.conversationStateVersion;

  __weak typeof(self) weakSelf = self;
  [self.dataSource getConversationList:0
                                 limit:limit
                            completion:^(NSArray<NSString *> * _Nullable conversationIds,
                                         NSNumber * _Nullable newOffset,
                                         NSNumber * _Nullable finished,
                                         NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      if (completion) completion(error, finished);
      return;
    }

    if (error || !conversationIds) {
      if (completion) completion(error, finished);
      return;
    }
    if (newOffset) {
      self.offset = newOffset.longLongValue;
    }

    [self.dataSource getRawConversationsByIds:conversationIds
                                  completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable rawError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (rawError || !rawConversations) {
          if (completion) completion(rawError, finished);
          return;
        }
        NSArray<NEConversationListModel *> *preservedModels = @[];
        if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
          preservedModels = [self.conversationListData filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
            NSNumber *version = self.conversationEventVersions[model.conversationId] ?: @0;
            NSNumber *deleted = self.deletedConversationEventVersions[model.conversationId] ?: @0;
            return version.unsignedLongLongValue > requestVersion && deleted.unsignedLongLongValue <= requestVersion;
          }]];
        }
        [self.conversationListData removeAllObjects];
        [self.conversationDic removeAllObjects];
        for (id rawConv in rawConversations) {
          NSString *cid = [self _conversationIdFromRaw:rawConv];
          if (!cid) continue;
          if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
            if (![self canApplySnapshotForConversationId:cid requestVersion:requestVersion]) continue;
            [self applyRawConversation:rawConv conversationId:cid isAdd:NO requestVersion:requestVersion];
          } else {
            [self _addOrUpdateWithRawConversation:rawConv conversationId:cid isAdd:NO];
          }
        }
        for (NEConversationListModel *model in preservedModels) {
          self.conversationDic[model.conversationId] = model;
          [self compareToInsert:model];
        }
        [self.delegate reloadTableView];
        if (finished) {
          [self.delegate loadMoreStateChange:finished.boolValue];
        }
        if (completion) completion(nil, finished);
      });
    }];
  }];
}

#pragma mark - 数据操作

- (ConversationRepo *)conversationRepo {
  return self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud ? [ConversationRepo shared] : nil;
}

- (void)atMessageChange {
  [self _handleAtMessageChangeNoti:nil];
}

- (void)deleteConversationNoti:(NSNotification *)noti {
  [self _handleDeleteConversationNoti:noti];
}

- (void)addOrUpdateConversationData:(V2NIMConversation *)conversation :(BOOL)isAdd {
  if (!conversation || conversation.conversationId.length == 0) return;
  [self executeOnMain:^{
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      [self recordConversationUpdate:conversation.conversationId];
      [self _addOrUpdateWithRawConversation:conversation conversationId:conversation.conversationId isAdd:isAdd];
    }
  }];
}

- (void)deleteConversation:(V2NIMConversation *)conversation :(void (^)(NSError *))completion {
  [self deleteConversation:conversation.conversationId completion:completion];
}

- (void)addStickTopWithConversation:(V2NIMConversation *)conversation :(void (^)(NSError *))completion {
  [self addStickTop:conversation.conversationId completion:completion];
}

- (void)removeStickTopWithConversation:(V2NIMConversation *)conversation :(void (^)(NSError *))completion {
  [self removeStickTop:conversation.conversationId completion:completion];
}

- (void)onMuteListChanged {
  [self.delegate reloadTableView];
}

- (void)updateUserInfo:(NEConversationListModel *)model :(NEUserWithFriend *)user :(V2NIMConversation *)conversation {
  [self addOrUpdateConversationData:conversation :NO];
}

- (void)updateTeamInfo:(NEConversationListModel *)model :(V2NIMTeam *)team :(V2NIMConversation *)conversation {
  [self addOrUpdateConversationData:conversation :NO];
}

- (void)onConversationCreated:(V2NIMConversation *)conversation {
  if (!conversation) return;
  [self executeOnMain:^{
    [self recordConversationUpdate:conversation.conversationId];
    if ([self checkDismissTeamNoti:conversation]) return;
    [self _addOrUpdateWithRawConversation:conversation
                           conversationId:conversation.conversationId
                                    isAdd:YES];
    if ([IMKitConfigCenter shared].enableOnlineStatus &&
        conversation.type == V2NIM_CONVERSATION_TYPE_P2P) {
      NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversation.conversationId];
      if (accountId.length > 0) {
        [self.p2pAccountIds addObject:accountId];
        [self subscribeOnlineStatus:@[accountId] notifyOnCachedChange:NO];
      }
    }
    [self.delegate reloadTableView];
    [self refreshConversationNameIfNeeded:conversation conversationId:conversation.conversationId];
  }];
}

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  [self executeOnMain:^{
    for (V2NIMConversation *conversation in conversations ?: @[]) {
      if (conversation.conversationId.length == 0) continue;
      [self recordConversationUpdate:conversation.conversationId];
      if ([self checkDismissTeamNoti:conversation]) continue;
      [self _addOrUpdateWithRawConversation:conversation
                             conversationId:conversation.conversationId
                                      isAdd:NO];
      if ([IMKitConfigCenter shared].enableOnlineStatus &&
          conversation.type == V2NIM_CONVERSATION_TYPE_P2P) {
        NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversation.conversationId];
        if (accountId.length > 0) [self.p2pAccountIds addObject:accountId];
      }
    }
    if ([IMKitConfigCenter shared].enableOnlineStatus && self.p2pAccountIds.count > 0) {
      [self subscribeOnlineStatus:self.p2pAccountIds.allObjects notifyOnCachedChange:NO];
    }
    [self.delegate reloadTableView];
  }];
}

- (void)onConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds {
  [self onDataSourceConversationUnreadCountCleared:conversationIds];
}

- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime {
  [self onDataSourceConversationReadTimeUpdated:conversationId readTime:readTime];
}

- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self onDataSourceConversationDeleted:conversationIds];
}

- (BOOL)checkDismissTeamNoti:(V2NIMConversation *)conversation {
  return [self _checkDismissTeamNoti:conversation conversationId:conversation.conversationId];
}

- (void)onConversationSyncStarted { [self onDataSourceSyncStarted]; }
- (void)onConversationSyncFinished { [self onDataSourceSyncFinished]; }
- (void)onConversationSyncFailed:(V2NIMError *)error { [self onDataSourceSyncFailed:error.nserror]; }

- (void)addOrUpdateConversationById:(NSString *)conversationId isAdd:(BOOL)isAdd {
  if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
    [self executeOnMain:^{
      [self recordConversationUpdate:conversationId];
    }];
  }
  [self.dataSource getRawConversationsByIds:@[conversationId]
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (rawConversations.count > 0) {
        id rawConv = rawConversations.firstObject;
        [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:isAdd];
      }
    });
  }];
}

- (void)compareToInsert:(NEConversationListModel *)cacheModel {
  for (NSUInteger i = 0; i < self.conversationListData.count; i++) {
    NEConversationListModel *existing = self.conversationListData[i];
    if (existing.sortOrder <= cacheModel.sortOrder) {
      [self.conversationListData insertObject:cacheModel atIndex:i];
      return;
    }
  }
  [self.conversationListData addObject:cacheModel];
}

- (void)deleteConversation:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion {
  [self.dataSource deleteConversation:conversationId clearMessage:NO completion:completion];
}

- (void)addStickTop:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion {
  NSLog(@"%@ addStickTop: %@", kClassName, conversationId);
  [self.dataSource setStickTop:conversationId stickTop:YES completion:completion];
}

- (void)removeStickTop:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion {
  NSLog(@"%@ removeStickTop: %@", kClassName, conversationId);
  [self.dataSource setStickTop:conversationId stickTop:NO completion:completion];
}

- (void)didDeleteConversation:(NSString *)conversationId {
  if (![IMKitConfigCenter shared].enableDismissTeamDeleteConversation) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.dataSource deleteConversation:conversationId clearMessage:NO completion:^(NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    if (error) {
      NSLog(@"%@ didDeleteConversation error: %@", kClassName, error.localizedDescription);
    } else {
      [self executeOnMain:^{
        if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
          [self recordConversationDeletion:conversationId];
        }
        [self.conversationDic removeObjectForKey:conversationId];
        [self.conversationListData filterUsingPredicate:
         [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
          return ![model.conversationId isEqualToString:conversationId];
        }]];
        [self.delegate reloadTableView];
      }];
    }
  }];
}

#pragma mark - NEConversationDataSourceListener

- (void)onDataSourceSyncStarted {
  NSLog(@"%@ onDataSourceSyncStarted", kClassName);
  if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
    [self executeOnMain:^{
      self.syncFinished = NO;
    }];
  }
}

- (void)onDataSourceSyncFinished {
  NSLog(@"%@ [Performance] onDataSourceSyncFinished", kClassName);
  [self executeOnMain:^{
    self.syncFinished = YES;
    ConversationCallBack completion = self.pendingCallBack;
    self.pendingCallBack = nil;
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      [self retrieveConversationDatasWithCompletion:completion];
    } else if (completion) {
      [self getConversationListByPage:completion];
    }
  }];
}

- (void)onDataSourceSyncFailed:(NSError *)error {
  NSLog(@"%@ onDataSourceSyncFailed: %@", kClassName, error.localizedDescription);
}

- (void)onDataSourceConversationCreated:(NSString *)conversationId {
  NSLog(@"%@ onDataSourceConversationCreated: %@", kClassName, conversationId);

  __weak typeof(self) weakSelf = self;
  [self.dataSource getRawConversationsByIds:@[conversationId]
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || rawConversations.count == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
        [self recordConversationUpdate:conversationId];
      }
      id rawConv = rawConversations.firstObject;
      if ([self _checkDismissTeamNoti:rawConv conversationId:conversationId]) return;
      [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:YES];

      if ([IMKitConfigCenter shared].enableOnlineStatus &&
          [self _conversationTypeFromRaw:rawConv] == V2NIM_CONVERSATION_TYPE_P2P) {
        NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
        if (accountId.length > 0) {
          [self.p2pAccountIds addObject:accountId];
          [self subscribeOnlineStatus:@[accountId] notifyOnCachedChange:NO];
        }
      }
      [self.delegate reloadTableView];
      [self refreshConversationNameIfNeeded:rawConv conversationId:conversationId];
    });
  }];
}

- (void)onDataSourceConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self executeOnMain:^{
    NSMutableSet *removeSet = [NSMutableSet setWithArray:conversationIds];
    for (NSString *cid in conversationIds) {
      if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
        [self recordConversationDeletion:cid];
      }
      [self.conversationDic removeObjectForKey:cid];
    }
    [self.conversationListData filterUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
      return ![removeSet containsObject:model.conversationId];
    }]];
    [self.delegate reloadTableView];
  }];
}

- (void)onDataSourceConversationChanged:(NSArray<NSString *> *)conversationIds {
  if (conversationIds.count == 0) return;

  __weak typeof(self) weakSelf = self;
  [self.dataSource getRawConversationsByIds:conversationIds
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || !rawConversations) return;

    dispatch_async(dispatch_get_main_queue(), ^{
      for (id rawConv in rawConversations) {
        NSString *cid = [self _conversationIdFromRaw:rawConv];
        if (!cid) continue;
        if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
          [self recordConversationUpdate:cid];
        }
        if ([self _checkDismissTeamNoti:rawConv conversationId:cid]) continue;
        [self _addOrUpdateWithRawConversation:rawConv conversationId:cid isAdd:NO];

        if ([IMKitConfigCenter shared].enableOnlineStatus &&
            [self _conversationTypeFromRaw:rawConv] == V2NIM_CONVERSATION_TYPE_P2P) {
          NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:cid];
          if (accountId.length > 0) {
            [self.p2pAccountIds addObject:accountId];
          }
        }
      }

      if ([IMKitConfigCenter shared].enableOnlineStatus && self.p2pAccountIds.count > 0) {
        [self subscribeOnlineStatus:self.p2pAccountIds.allObjects notifyOnCachedChange:NO];
      }

      [self.delegate reloadTableView];
    });
  }];
}

- (void)onDataSourceConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds {
  [self executeOnMain:^{
    for (NSString *conversationId in conversationIds) {
      NEConversationListModel *model = self.conversationDic[conversationId];
      [model markUnreadCountCleared];
      if (model.unreadCount == 0) {
        [NEAtMessageManager.instance clearAtRecord:conversationId];
      }
    }
    [self.delegate reloadTableView];
  }];
}

- (void)onDataSourceConversationReadTimeUpdated:(NSString *)conversationId readTime:(NSTimeInterval)readTime {
  [self executeOnMain:^{
    NEConversationListModel *model = self.conversationDic[conversationId];
    [model markUnreadCountClearedThrough:readTime];
    if (model.unreadCount == 0) {
      [NEAtMessageManager.instance clearAtRecord:conversationId];
    }
    [self.delegate reloadTableView];
  }];
}

- (void)onDataSourceTotalUnreadCountChanged:(NSInteger)unreadCount {
  // UI 层可通过 KVO 或 Notification 监听，此处暂不做额外处理
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
  if (status == V2NIM_CONNECT_STATUS_WAITING) {
    self.networkBroken = YES;
  }

  if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.networkBroken) {
    self.networkBroken = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (self && !self.pendingCallBack) {
        [self retrieveConversationDatas];
      }
    });
  }
}

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    [self executeOnMain:^{
      self.syncFinished = NO;
      self.pendingCallBack = nil;
      self.offset = 0;
      self.conversationStateVersion = 0;
      [self.conversationEventVersions removeAllObjects];
      [self.deletedConversationEventVersions removeAllObjects];
      [self.p2pAccountIds removeAllObjects];
      [self.onlineStatusDic removeAllObjects];
    }];
  }
}

#pragma mark - V2NIMTeamListener

- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked {
  NSLog(@"%@ onTeamLeft: %@ isKicked: %d", kClassName, team.teamId, isKicked);
  NSString *cid = [V2NIMConversationIdUtil teamConversationId:team.teamId];
  if (cid) {
    [self didDeleteConversation:cid];
  }
}

- (void)onTeamDismissed:(V2NIMTeam *)team {
  NSLog(@"%@ onTeamDismissed: %@", kClassName, team.teamId);
  if ([IMKitConfigCenter shared].enableDismissTeamDeleteConversation) {
    NSString *cid = [V2NIMConversationIdUtil teamConversationId:team.teamId];
    if (cid) {
      [self didDeleteConversation:cid];
    }
  }
}

- (void)onTeamJoined:(V2NIMTeam *)team {
  // 加入群后，会话会通过 onConversationCreated 自动创建
}

- (void)onTeamCreated:(V2NIMTeam *)team {
  // 建群后同理
}

- (void)onTeamSyncFinished {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
}

#pragma mark - NEContactListener

- (void)onUserProfileChanged:(NSArray<V2NIMUser *> *)users {
  NSMutableArray<NSString *> *accountIds = [NSMutableArray arrayWithCapacity:users.count];
  for (V2NIMUser *user in users) {
    if (user.accountId.length > 0) {
      [accountIds addObject:user.accountId];
    }
  }
  [self refreshP2PConversationsForAccountIds:accountIds];
}

- (void)onFriendDeleted:(NSString *)accountId deletionType:(V2NIMFriendDeletionType)deletionType {
  [self refreshP2PConversationsForAccountIds:accountId.length > 0 ? @[accountId] : @[]];
}

- (void)onFriendInfoChanged:(V2NIMFriend *)friendInfo {
  NSLog(@"%@ onFriendInfoChanged: %@", kClassName, friendInfo.accountId);
  [self refreshP2PConversationsForAccountIds:friendInfo.accountId.length > 0 ? @[friendInfo.accountId] : @[]];
}

#pragma mark - NESubscribeListener

- (void)subscribeOnlineStatus:(NSArray<NSString *> *)accountIds {
  if (![NSThread isMainThread]) {
    __weak typeof(self) weakSelf = self;
    [self executeOnMain:^{
      [weakSelf subscribeOnlineStatus:accountIds];
    }];
    return;
  }
  [self subscribeOnlineStatus:accountIds notifyOnCachedChange:YES];
}

- (void)subscribeOnlineStatus:(NSArray<NSString *> *)accountIds notifyOnCachedChange:(BOOL)notifyOnCachedChange {
  NSMutableArray<NSString *> *subscribeList = [NSMutableArray array];
  BOOL didChange = NO;
  for (NSString *accountId in accountIds) {
    if (accountId.length == 0) {
      continue;
    }

    if ([[NEAIUserManager shared] isAIUser:accountId]) {
      continue;
    }

    V2NIMUserStatus *event = [[NESubscribeManager shared] getSubscribeStatus:accountId];
    NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
    if (event && conversationId.length > 0) {
      BOOL isOnline = [NESubscribeManager isOnline:event];
      NSNumber *cachedStatus = self.onlineStatusDic[conversationId];
      if (!cachedStatus || cachedStatus.boolValue != isOnline) {
        self.onlineStatusDic[conversationId] = @(isOnline);
        didChange = YES;
      }
    } else {
      [subscribeList addObject:accountId];
    }
  }

  if (notifyOnCachedChange && didChange) {
    [self.delegate reloadTableView];
  }

  if (subscribeList.count > 0) {
    [[NESubscribeManager shared] subscribeUsersOnlineState:subscribeList completion:^(NSError * _Nullable error) {
    }];
  }
}

- (void)unsubscribeOnlineStatus {
  NSArray<NSString *> *subscribeList = self.p2pAccountIds.allObjects;
  if (subscribeList.count == 0) {
    return;
  }

  [[NESubscribeManager shared] unSubscribeUsersOnlineState:subscribeList completion:^(NSError * _Nullable error) {
  }];
}

- (void)onUserStatusChanged:(NSArray<V2NIMUserStatus *> *)data {
  [self executeOnMain:^{
    BOOL needRefresh = NO;
    for (V2NIMUserStatus *status in data) {
      if (![self.p2pAccountIds containsObject:status.accountId]) {
        continue;
      }

      NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:status.accountId];
      if (conversationId.length == 0) {
        continue;
      }

      BOOL isOnline = [NESubscribeManager isOnline:status];
      NSNumber *cachedStatus = self.onlineStatusDic[conversationId];
      if (!cachedStatus || cachedStatus.boolValue != isOnline) {
        self.onlineStatusDic[conversationId] = @(isOnline);
        needRefresh = YES;
      }
    }

    if (needRefresh) {
      [self.delegate reloadTableView];
    }
  }];
}

#pragma mark - AIUserPinListener

- (void)userInfoDidChange {
  NSLog(@"%@ userInfoDidChange", kClassName);
  [self getAIUserList];
}

#pragma mark - AIUserChangeListener

- (void)onAIUserChanged:(NSArray<V2NIMAIUser *> *)aiUsers {
  if (![IMKitConfigCenter shared].enableAIUser) {
    return;
  }

  [self.aiUserListData removeAllObjects];
  for (V2NIMAIUser *aiUser in aiUsers) {
    if ([[NEAIUserPinManager shared] checkoutUnPinAIUser:aiUser]) {
      NEAIUserModel *model = [[NEAIUserModel alloc] init];
      model.aiUser = aiUser;
      [self.aiUserListData addObject:model];
    }
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
}

#pragma mark - Notification

- (void)_handleDeleteConversationNoti:(NSNotification *)noti {
  NSString *conversationId = noti.object;
  if ([conversationId isKindOfClass:[NSString class]] && conversationId.length > 0) {
    __weak typeof(self) weakSelf = self;
    [self.dataSource deleteConversation:conversationId clearMessage:NO completion:^(NSError * _Nullable error) {
      NSLog(@"%@ deleteConversationNoti result: %@", kClassName, error.localizedDescription ?: @"success");
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      // 删除回调会通过 onDataSourceConversationDeleted 处理
    }];
  }
}

- (void)_handleAtMessageChangeNoti:(NSNotification *)noti {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
}

#pragma mark - Private: Raw Conversation 工具方法

- (void)executeOnMain:(dispatch_block_t)work {
  if (!work) return;
  if ([NSThread isMainThread]) work();
  else dispatch_async(dispatch_get_main_queue(), work);
}

- (void)backfillP2PConversationProfiles:(NSArray<NSString *> *)accountIds
                         requestVersion:(uint64_t)requestVersion {
  if (accountIds.count == 0) return;

  NSArray<NSString *> *accountIdSnapshot = [accountIds copy];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;

    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      NSMutableArray<NSString *> *nonFriendIds = [NSMutableArray array];
      for (NSString *accountId in accountIdSnapshot) {
        if (![[NEFriendUserCache shared] isFriend:accountId]) {
          [nonFriendIds addObject:accountId];
        }
      }
      if (nonFriendIds.count == 0) return;

      [[NEFriendUserCache shared] loadShowName:nonFriendIds
                                    showAlias:YES
                                    completion:^(NSArray<NEUserWithFriend *> * _Nullable users) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSMutableArray<NSString *> *conversationIds = [NSMutableArray arrayWithCapacity:nonFriendIds.count];
        for (NSString *accountId in nonFriendIds) {
          NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
          if (conversationId.length > 0) [conversationIds addObject:conversationId];
        }
        [self.dataSource getRawConversationsByIds:conversationIds
                                      completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
          __strong typeof(weakSelf) self = weakSelf;
          if (!self || !rawConversations) return;
          dispatch_async(dispatch_get_main_queue(), ^{
            for (id rawConversation in rawConversations) {
              NSString *conversationId = [self _conversationIdFromRaw:rawConversation];
              if (conversationId.length == 0) continue;
              [self applyRawConversation:rawConversation
                          conversationId:conversationId
                                   isAdd:NO
                          requestVersion:requestVersion];
            }
            [self.delegate reloadTableView];
          });
        }];
      }];
      return;
    }

    [[ContactRepo shared] getUserListFromCloud:accountIdSnapshot
                                    completion:^(NSArray<NEUserWithFriend *> * _Nullable users,
                                                 NSError * _Nullable error) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      NSMutableArray<NSString *> *conversationIds = [NSMutableArray arrayWithCapacity:accountIdSnapshot.count];
      for (NSString *accountId in accountIdSnapshot) {
        NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
        if (conversationId.length > 0) [conversationIds addObject:conversationId];
      }
      [self.dataSource getRawConversationsByIds:conversationIds
                                    completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable rawError) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !rawConversations) return;
        dispatch_async(dispatch_get_main_queue(), ^{
          for (id rawConversation in rawConversations) {
            NSString *conversationId = [self _conversationIdFromRaw:rawConversation];
            if (conversationId.length > 0) {
              [self _addOrUpdateWithRawConversation:rawConversation
                                     conversationId:conversationId
                                              isAdd:NO];
            }
          }
          [self.delegate reloadTableView];
        });
      }];
    }];
  });
}

- (void)refreshP2PConversationsForAccountIds:(NSArray<NSString *> *)accountIds {
  if (accountIds.count == 0) return;

  NSMutableArray<NSString *> *conversationIds = [NSMutableArray array];
  NSMutableSet<NSString *> *seenConversationIds = [NSMutableSet set];
  for (NSString *accountId in accountIds) {
    if (accountId.length == 0) continue;
    NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
    if (conversationId.length == 0 ||
        !self.conversationDic[conversationId] ||
        [seenConversationIds containsObject:conversationId]) {
      continue;
    }
    [seenConversationIds addObject:conversationId];
    [conversationIds addObject:conversationId];
  }

  [self refreshRawConversationsForConversationIds:conversationIds];
}

- (void)refreshRawConversationsForConversationIds:(NSArray<NSString *> *)conversationIds {
  if (conversationIds.count == 0) return;

  __weak typeof(self) weakSelf = self;
  [self.dataSource getRawConversationsByIds:conversationIds
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || error || rawConversations.count == 0) return;

    [self executeOnMain:^{
      BOOL didUpdate = NO;
      for (id rawConversation in rawConversations) {
        NSString *conversationId = [self _conversationIdFromRaw:rawConversation];
        if (conversationId.length == 0 || !self.conversationDic[conversationId]) continue;
        [self _addOrUpdateWithRawConversation:rawConversation
                               conversationId:conversationId
                                        isAdd:NO];
        didUpdate = YES;
      }
      if (didUpdate) {
        [self.delegate reloadTableView];
      }
    }];
  }];
}

- (void)refreshConversationNameIfNeeded:(id)rawConversation
                         conversationId:(NSString *)conversationId {
  if ([self _conversationTypeFromRaw:rawConversation] != V2NIM_CONVERSATION_TYPE_P2P) return;

  NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
  NSString *conversationName = self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud
      ? ((V2NIMConversation *)rawConversation).name
      : ((V2NIMLocalConversation *)rawConversation).name;
  if (accountId.length == 0 || ![conversationName isEqualToString:accountId]) return;

  __weak typeof(self) weakSelf = self;
  [[NEFriendUserCache shared] loadShowName:@[accountId]
                                showAlias:YES
                                completion:^(NSArray<NEUserWithFriend *> * _Nullable users) {
    BOOL containsAccount = NO;
    for (NEUserWithFriend *userInfo in users) {
      if ([userInfo.user.accountId isEqualToString:accountId]) {
        containsAccount = YES;
        break;
      }
    }
    if (!containsAccount) return;

    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    [self.dataSource getRawConversationsByIds:@[conversationId]
                                  completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
      __strong typeof(weakSelf) self = weakSelf;
      id refreshedConversation = rawConversations.firstObject;
      if (!self || !refreshedConversation) return;
      dispatch_async(dispatch_get_main_queue(), ^{
        NEConversationListModel *model = self.conversationDic[conversationId];
        if (!model) return;
        if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
          [model updateWithCloudConversation:(V2NIMConversation *)refreshedConversation];
        } else {
          [model updateWithLocalConversation:(V2NIMLocalConversation *)refreshedConversation];
        }
        [self.delegate reloadTableView];
      });
    }];
  }];
}

- (void)recordConversationUpdate:(NSString *)conversationId {
  if (conversationId.length == 0) return;
  self.conversationStateVersion += 1;
  self.conversationEventVersions[conversationId] = @(self.conversationStateVersion);
  [self.deletedConversationEventVersions removeObjectForKey:conversationId];
}

- (void)recordConversationDeletion:(NSString *)conversationId {
  if (conversationId.length == 0) return;
  self.conversationStateVersion += 1;
  self.conversationEventVersions[conversationId] = @(self.conversationStateVersion);
  self.deletedConversationEventVersions[conversationId] = @(self.conversationStateVersion);
}

- (BOOL)canApplySnapshotForConversationId:(NSString *)conversationId requestVersion:(uint64_t)requestVersion {
  uint64_t eventVersion = self.conversationEventVersions[conversationId].unsignedLongLongValue;
  uint64_t deletedVersion = self.deletedConversationEventVersions[conversationId].unsignedLongLongValue;
  return eventVersion <= requestVersion && deletedVersion <= requestVersion;
}

- (void)applyRawConversation:(id)rawConv
              conversationId:(NSString *)conversationId
                       isAdd:(BOOL)isAdd
              requestVersion:(uint64_t)requestVersion {
  if (![self canApplySnapshotForConversationId:conversationId requestVersion:requestVersion]) return;
  [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:isAdd];
}

/// 从原始对象中提取 conversationId
- (nullable NSString *)_conversationIdFromRaw:(id)rawConv {
  if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMConversation")]) {
    return [(V2NIMConversation *)rawConv conversationId];
  } else if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMLocalConversation")]) {
    return [(V2NIMLocalConversation *)rawConv conversationId];
  }
  return nil;
}

/// 从原始对象中提取 type
- (NSInteger)_conversationTypeFromRaw:(id)rawConv {
  if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMConversation")]) {
    return (NSInteger)[(V2NIMConversation *)rawConv type];
  } else if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMLocalConversation")]) {
    return (NSInteger)[(V2NIMLocalConversation *)rawConv type];
  }
  return 0;
}

- (NSInteger)_unreadCountFromRaw:(id)rawConv {
  if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMConversation")]) {
    return (NSInteger)[(V2NIMConversation *)rawConv unreadCount];
  } else if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMLocalConversation")]) {
    return (NSInteger)[(V2NIMLocalConversation *)rawConv unreadCount];
  }
  return 0;
}

- (nullable V2NIMLastMessage *)_lastMessageFromRaw:(id)rawConv {
  if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMConversation")]) {
    return [(V2NIMConversation *)rawConv lastMessage];
  } else if ([rawConv isKindOfClass:NSClassFromString(@"V2NIMLocalConversation")]) {
    return [(V2NIMLocalConversation *)rawConv lastMessage];
  }
  return nil;
}

- (BOOL)_checkDismissTeamNoti:(id)rawConv conversationId:(NSString *)conversationId {
  if (![IMKitConfigCenter shared].enableDismissTeamDeleteConversation) {
    return NO;
  }

  if ([self _conversationTypeFromRaw:rawConv] != V2NIM_CONVERSATION_TYPE_TEAM) {
    return NO;
  }

  V2NIMLastMessage *lastMessage = [self _lastMessageFromRaw:rawConv];
  if (lastMessage.messageType != V2NIM_MESSAGE_TYPE_NOTIFICATION ||
      ![lastMessage.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
    return NO;
  }

  V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)lastMessage.attachment;
  NSString *senderId = lastMessage.messageRefer.senderId;
  BOOL shouldDelete = content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS ||
                      (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_KICK &&
                       [content.targetIds containsObject:[[IMKitClient instance] account]]) ||
                      (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE &&
                       [[IMKitClient instance] isMe:senderId]);
  if (!shouldDelete) {
    return NO;
  }

  NSLog(@"%@ _checkDismissTeamNoti delete conversation: %@", kClassName, conversationId);
  [self.dataSource deleteConversation:conversationId clearMessage:NO completion:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"%@ _checkDismissTeamNoti delete error: %@", kClassName, error.localizedDescription);
    }
  }];
  [self.conversationDic removeObjectForKey:conversationId];
  if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
    [self recordConversationDeletion:conversationId];
  }
  [self.conversationListData filterUsingPredicate:
   [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
    return ![model.conversationId isEqualToString:conversationId];
  }]];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
  return YES;
}

/// 添加或更新模型（内部核心方法）
- (void)_addOrUpdateWithRawConversation:(id)rawConv
                         conversationId:(NSString *)conversationId
                                  isAdd:(BOOL)isAdd {
  if ([self _unreadCountFromRaw:rawConv] <= 0 &&
      [NEAtMessageManager.instance isAtCurrentUserConversationId:conversationId]) {
    [NEAtMessageManager.instance clearAtRecord:conversationId];
  }

  NEConversationListModel *cached = self.conversationDic[conversationId];

  if (cached) {
    int64_t previousSortOrder = cached.sortOrder;
    // 更新已有模型
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      [cached updateWithCloudConversation:(V2NIMConversation *)rawConv];
    } else {
      [cached updateWithLocalConversation:(V2NIMLocalConversation *)rawConv];
    }

    // （未读数、草稿等）触发行重插。本地会话仍按 sortOrder 重排。
    BOOL sortOrderChanged = cached.sortOrder != previousSortOrder;
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud &&
        NEAdaptiveDeviceGate.adaptiveHostActive && !sortOrderChanged) {
      return;
    }

    // 从列表中移除旧位置
    [self.conversationListData filterUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
      return ![model.conversationId isEqualToString:conversationId];
    }]];

    // 重新按排序插入
    [self compareToInsert:cached];
  } else {
    // 创建新模型
    NEConversationListModel *model;
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      model = [NEConversationListModel modelWithCloudConversation:(V2NIMConversation *)rawConv];
    } else {
      model = [NEConversationListModel modelWithLocalConversation:(V2NIMLocalConversation *)rawConv];
    }
    self.conversationDic[conversationId] = model;

    // Swift always uses the conversation sort order for new models, including
    // models arriving from a paged snapshot.
    [self compareToInsert:model];
  }
}

@end
