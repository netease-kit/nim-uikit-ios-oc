// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationViewModel.h"
#import "NEAtMessageManager.h"
#import "NEConversationListModel.h"
#import "NECloudConversationDataSource.h"
#import "NELocalConversationDataSource.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NEAIUserModel.h>
#import <NEChatKitOC/NEAIUserManager.h>
#import <NEChatKitOC/NEAIUserPinManager.h>
#import <NEChatKitOC/NESubscribeManager.h>
#import <NEChatKitOC/SubscribeRepo.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

static NSString * const kClassName = @"ConversationViewModel";

@interface ConversationViewModel () <NEIMKitClientListener, NETeamListener, NEContactListener, NESubscribeListener, AIUserPinListener, AIUserChangeListener>

/// 网络断开标志
@property (nonatomic, assign) BOOL networkBroken;

/// 同步完成前暂存的回调
@property (nonatomic, copy, nullable) ConversationCallBack pendingCallBack;

/// 单聊账号 id
@property (nonatomic, strong) NSMutableSet<NSString *> *p2pAccountIds;

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
  }
  return self;
}

+ (instancetype)cloudViewModel {
  NECloudConversationDataSource *ds = [[NECloudConversationDataSource alloc] init];
  return [[ConversationViewModel alloc] initWithDataSource:ds];
}

+ (instancetype)localViewModel {
  NELocalConversationDataSource *ds = [[NELocalConversationDataSource alloc] init];
  return [[ConversationViewModel alloc] initWithDataSource:ds];
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
  if (!self.syncFinished) {
    self.pendingCallBack = completion;
  }

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

    if (!error && conversationIds.count > 0) {
      // 更新 offset
      if (newOffset) {
        self.offset = newOffset.longLongValue;
      }

      // 通过 DataSource 获取原始对象并建模
      [self.dataSource getRawConversationsByIds:conversationIds
                                    completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable rawError) {
        if (rawError || !rawConversations) {
          completion(rawError, finished);
          return;
        }

        for (id rawConv in rawConversations) {
          NSString *cid = [self _conversationIdFromRaw:rawConv];
          if (!cid) continue;

          [self _addOrUpdateWithRawConversation:rawConv conversationId:cid isAdd:NO];

          // 收集单聊 account
          NSInteger convType = [self _conversationTypeFromRaw:rawConv];
          if (convType == 1) { // CONVERSATION_TYPE_P2P
            NSString *targetId = [V2NIMConversationIdUtil conversationTargetId:cid];
            if (targetId) {
              [self.p2pAccountIds addObject:targetId];
            }
          }
        }

        if ([IMKitConfigCenter shared].enableOnlineStatus && self.p2pAccountIds.count > 0) {
          [self subscribeOnlineStatus:self.p2pAccountIds.allObjects];
        }

        NSArray<NSString *> *p2pAccountIds = self.p2pAccountIds.allObjects;
        if (p2pAccountIds.count > 0) {
          __weak typeof(self) weakUserInfoSelf = self;
          [[ContactRepo shared] getUserListFromCloud:p2pAccountIds completion:^(NSArray * _Nullable users, NSError * _Nullable userError) {
            __strong typeof(weakUserInfoSelf) self = weakUserInfoSelf;
            if (!self) return;
            [self _refreshP2PConversationsForAccountIds:p2pAccountIds];
          }];
        }

        [self.delegate reloadTableView];
        completion(nil, finished);
      }];
    } else {
      completion(error, finished);
    }
  }];
}

- (void)retrieveConversationDatas {
  NSInteger limit = self.conversationDic.count > (NSUInteger)self.page ? self.conversationDic.count : self.page;

  __weak typeof(self) weakSelf = self;
  [self.dataSource getConversationList:0
                                 limit:limit
                            completion:^(NSArray<NSString *> * _Nullable conversationIds,
                                         NSNumber * _Nullable newOffset,
                                         NSNumber * _Nullable finished,
                                         NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;

    if (!error && conversationIds) {
      if (newOffset) {
        self.offset = newOffset.longLongValue;
      }

      // 清理旧数据
      [self.conversationListData removeAllObjects];
      [self.conversationDic removeAllObjects];
      [self.p2pAccountIds removeAllObjects];
      [self.onlineStatusDic removeAllObjects];

      [self.dataSource getRawConversationsByIds:conversationIds
                                    completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable rawError) {
        if (rawConversations) {
          for (id rawConv in rawConversations) {
            NSString *cid = [self _conversationIdFromRaw:rawConv];
            if (!cid) continue;
            [self _addOrUpdateWithRawConversation:rawConv conversationId:cid isAdd:NO];
            if ([self _conversationTypeFromRaw:rawConv] == V2NIM_CONVERSATION_TYPE_P2P) {
              NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:cid];
              if (accountId.length > 0) {
                [self.p2pAccountIds addObject:accountId];
              }
            }
          }
        }

        if ([IMKitConfigCenter shared].enableOnlineStatus && self.p2pAccountIds.count > 0) {
          [self subscribeOnlineStatus:self.p2pAccountIds.allObjects];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate reloadTableView];
          if (finished) {
            [self.delegate loadMoreStateChange:finished.boolValue];
          }
        });
      }];
    }
  }];
}

#pragma mark - 数据操作

- (void)addOrUpdateConversationById:(NSString *)conversationId isAdd:(BOOL)isAdd {
  [self.dataSource getRawConversationsByIds:@[conversationId]
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    if (rawConversations.count > 0) {
      id rawConv = rawConversations.firstObject;
      [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:isAdd];
    }
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
      [self.conversationDic removeObjectForKey:conversationId];
      [self.conversationListData filterUsingPredicate:
       [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
        return ![model.conversationId isEqualToString:conversationId];
      }]];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadTableView];
      });
    }
  }];
}

#pragma mark - NEConversationDataSourceListener

- (void)onDataSourceSyncStarted {
  NSLog(@"%@ onDataSourceSyncStarted", kClassName);
}

- (void)onDataSourceSyncFinished {
  NSLog(@"%@ [Performance] onDataSourceSyncFinished", kClassName);
  self.syncFinished = YES;

  if (self.pendingCallBack) {
    ConversationCallBack cb = self.pendingCallBack;
    self.pendingCallBack = nil;
    [self getConversationListByPage:cb];
  }
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

    id rawConv = rawConversations.firstObject;
    if ([self _checkDismissTeamNoti:rawConv conversationId:conversationId]) {
      return;
    }
    [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:YES];

    if ([IMKitConfigCenter shared].enableOnlineStatus &&
        [self _conversationTypeFromRaw:rawConv] == V2NIM_CONVERSATION_TYPE_P2P) {
      NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
      if (accountId.length > 0) {
        [self.p2pAccountIds addObject:accountId];
        [self subscribeOnlineStatus:@[accountId]];
      }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }];
}

- (void)onDataSourceConversationDeleted:(NSArray<NSString *> *)conversationIds {
  NSMutableSet *removeSet = [NSMutableSet setWithArray:conversationIds];
  for (NSString *cid in conversationIds) {
    [self.conversationDic removeObjectForKey:cid];
  }
  [self.conversationListData filterUsingPredicate:
   [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
    return ![removeSet containsObject:model.conversationId];
  }]];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
}

- (void)onDataSourceConversationChanged:(NSArray<NSString *> *)conversationIds {
  if (conversationIds.count == 0) return;

  __weak typeof(self) weakSelf = self;
  [self.dataSource getRawConversationsByIds:conversationIds
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || !rawConversations) return;

    for (id rawConv in rawConversations) {
      NSString *cid = [self _conversationIdFromRaw:rawConv];
      if (!cid) continue;
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
      [self subscribeOnlineStatus:self.p2pAccountIds.allObjects];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }];
}

- (void)onDataSourceTotalUnreadCountChanged:(NSInteger)unreadCount {
  // UI 层可通过 KVO 或 Notification 监听，此处暂不做额外处理
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
  // V2NIMConnectStatus: WAITING = 0, CONNECTED = 1, DISCONNECTED = 2
  if (status == 0) { // CONNECT_STATUS_WAITING
    self.networkBroken = YES;
  }

  if (status == 1 && self.networkBroken) { // CONNECT_STATUS_CONNECTED
    self.networkBroken = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      if (!self.pendingCallBack) {
        NSLog(@"%@ retrieveConversationDatas after reconnect", kClassName);
        [self retrieveConversationDatas];
      }
    });
  }
}

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    [self.p2pAccountIds removeAllObjects];
    [self.onlineStatusDic removeAllObjects];
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
  [self _refreshP2PConversationsForAccountIds:accountIds];
}

- (void)onFriendDeleted:(NSString *)accountId deletionType:(V2NIMFriendDeletionType)deletionType {
  [self _refreshP2PConversationsForAccountIds:accountId.length > 0 ? @[accountId] : @[]];
}

- (void)onFriendInfoChanged:(V2NIMFriend *)friendInfo {
  NSLog(@"%@ onFriendInfoChanged: %@", kClassName, friendInfo.accountId);
  [self _refreshP2PConversationsForAccountIds:friendInfo.accountId.length > 0 ? @[friendInfo.accountId] : @[]];
}

#pragma mark - NESubscribeListener

- (void)subscribeOnlineStatus:(NSArray<NSString *> *)accountIds {
  NSMutableArray<NSString *> *subscribeList = [NSMutableArray array];
  __block BOOL needRefresh = NO;
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
      self.onlineStatusDic[conversationId] = @(event.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
      needRefresh = YES;
    } else {
      [subscribeList addObject:accountId];
    }
  }

  if (needRefresh) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
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
  BOOL needRefresh = NO;
  for (V2NIMUserStatus *status in data) {
    if (![self.p2pAccountIds containsObject:status.accountId]) {
      continue;
    }

    NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:status.accountId];
    if (conversationId.length == 0) {
      continue;
    }

    self.onlineStatusDic[conversationId] = @(status.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
    needRefresh = YES;
  }

  if (needRefresh) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }
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
  [self.conversationListData filterUsingPredicate:
   [NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
    return ![model.conversationId isEqualToString:conversationId];
  }]];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate reloadTableView];
  });
  return YES;
}

- (void)_refreshP2PConversationsForAccountIds:(NSArray<NSString *> *)accountIds {
  if (accountIds.count == 0) {
    return;
  }

  NSMutableArray<NSString *> *conversationIds = [NSMutableArray array];
  NSMutableSet<NSString *> *dedupSet = [NSMutableSet set];
  for (NSString *accountId in accountIds) {
    if (accountId.length == 0) {
      continue;
    }

    NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accountId];
    if (conversationId.length == 0 ||
        !self.conversationDic[conversationId] ||
        [dedupSet containsObject:conversationId]) {
      continue;
    }

    [dedupSet addObject:conversationId];
    [conversationIds addObject:conversationId];
  }

  [self _refreshRawConversationsForConversationIds:conversationIds];
}

- (void)_refreshRawConversationsForConversationIds:(NSArray<NSString *> *)conversationIds {
  if (conversationIds.count == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.dataSource getRawConversationsByIds:conversationIds
                                completion:^(NSArray * _Nullable rawConversations, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || rawConversations.count == 0) {
      return;
    }

    for (id rawConv in rawConversations) {
      NSString *conversationId = [self _conversationIdFromRaw:rawConv];
      if (conversationId.length == 0 || !self.conversationDic[conversationId]) {
        continue;
      }
      [self _addOrUpdateWithRawConversation:rawConv conversationId:conversationId isAdd:NO];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }];
}

/// 添加或更新模型（内部核心方法）
- (void)_addOrUpdateWithRawConversation:(id)rawConv
                         conversationId:(NSString *)conversationId
                                  isAdd:(BOOL)isAdd {
  if ([self _unreadCountFromRaw:rawConv] <= 0 &&
      [[NEAtMessageManager sharedManager] isAtCurrentUserConversationId:conversationId]) {
    [[NEAtMessageManager sharedManager] clearAtRecord:conversationId];
  }

  NEConversationListModel *cached = self.conversationDic[conversationId];

  if (cached) {
    // 更新已有模型
    if (self.dataSource.dataSourceType == NEConversationDataSourceTypeCloud) {
      [cached updateWithCloudConversation:(V2NIMConversation *)rawConv];
    } else {
      [cached updateWithLocalConversation:(V2NIMLocalConversation *)rawConv];
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

    if (isAdd) {
      [self compareToInsert:model];
    } else {
      [self.conversationListData addObject:model];
    }
  }
}

@end
