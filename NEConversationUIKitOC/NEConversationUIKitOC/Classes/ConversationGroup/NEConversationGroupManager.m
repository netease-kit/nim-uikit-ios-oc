// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import "NEConversationGroupManager.h"
#import "NEConversationListModel.h"
#import "NEAtMessageManager.h"
#import <NEChatKit/NEChatKit-Swift.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NECommonLoader.h>

static NSString *const NEGroupAllId = @"conversation_group_all";
static NSString *const NEGroupAtMeId = @"conversation_group_at_me";
static NSString *const NEGroupUnreadId = @"conversation_group_unread";

static NSString *NEGroupManagerText(NSString *key) {
  static NECommonLoader *loader;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEConversationGroupManager class]];
  });
  return [loader localizable:key];
}

static NSString *NEConversationGroupResolvedName(NSString *name, NSString *groupId) {
  NSString *candidate = [name isKindOfClass:[NSString class]] ? name : @"";
  if ([candidate stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
    return groupId ?: @"";
  }
  return candidate;
}

@implementation NEConversationGroupModel

- (instancetype)initWithType:(NEConversationGroupType)type
                     groupId:(NSString *)groupId
                        name:(NSString *)name
                 unreadCount:(NSInteger)unreadCount
                    sdkGroup:(V2NIMConversationGroup *)sdkGroup {
  self = [super init];
  if (self) {
    _type = type;
    _groupId = [groupId copy];
    _name = [name copy];
    _unreadCount = unreadCount;
    _sdkGroup = sdkGroup;
  }
  return self;
}

- (BOOL)canEdit { return self.type == NEConversationGroupTypeCustom; }
- (BOOL)canHide { return self.type != NEConversationGroupTypeAll; }
- (BOOL)canDrag { return self.type != NEConversationGroupTypeAll; }
- (NSString *)displayName {
  if (self.unreadCount <= 0) return self.name ?: @"";
  NSString *count = self.unreadCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)self.unreadCount];
  return [NSString stringWithFormat:@"%@(%@)", self.name ?: @"", count];
}
+ (NSString *)allId { return NEGroupAllId; }
+ (NSString *)atMeId { return NEGroupAtMeId; }
+ (NSString *)unreadId { return NEGroupUnreadId; }
@end

@interface NEConversationGroupManager (ConversationGroupViewModelBridge)
@property(nonatomic, assign, readonly) int64_t selectedOffset;
- (void)onConversationGroupCreated:(V2NIMConversationGroup *)group;
- (void)onConversationGroupDeleted:(NSString *)groupId;
- (void)onConversationGroupChanged:(V2NIMConversationGroup *)group;
- (void)onConversationsAddedToGroup:(NSString *)groupId conversations:(NSArray<V2NIMConversation *> *)conversations;
- (void)onConversationsRemovedFromGroup:(NSString *)groupId conversationIds:(NSArray<NSString *> *)conversationIds;
- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations;
- (void)onConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds;
- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime;
- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds;
- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount;
- (void)onConversationSyncFinished;
- (void)onUnreadCountChangedByFilter:(V2NIMConversationFilter *)filter :(NSInteger)unreadCount;
@end

@interface ConversationGroupAddViewModel ()
@property(nonatomic, copy) NSArray<NEConversationListModel *> *allData;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *displayData;
@property(nonatomic, strong) NSMutableSet<NSString *> *mutableSelectedIds;
@property(nonatomic, copy) NSSet<NSString *> *existingIds;
@property(nonatomic, copy) NSString *groupId;
@property(nonatomic, copy) NSString *keyword;
@property(nonatomic, assign) BOOL loading;
@end

@implementation ConversationGroupAddViewModel

- (instancetype)initWithGroupId:(NSString *)groupId existingIds:(NSSet<NSString *> *)existingIds {
  self = [super init];
  if (self) {
    _groupId = [groupId copy];
    _existingIds = [existingIds copy] ?: [NSSet set];
    _allData = @[];
    _displayData = @[];
    _mutableSelectedIds = [NSMutableSet set];
    _keyword = @"";
    _pageSize = 100;
    _finished = NO;
  }
  return self;
}

- (NSSet<NSString *> *)selectedIds {
  return [self.mutableSelectedIds copy];
}

- (NSInteger)existingCount {
  return self.existingIds.count;
}

- (void)loadMore:(void (^)(NSError *, BOOL))completion {
  if (self.finished || self.loading) return;
  self.loading = YES;
  int64_t requestOffset = self.offset;
  __weak typeof(self) weakSelf = self;
  [[ConversationRepo shared] getConversationList:requestOffset
                                           limit:self.pageSize
                                      completion:^(NSArray<V2NIMConversation *> *conversations,
                                                   NSNumber *nextOffset,
                                                   NSNumber *finished,
                                                   NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      self.loading = NO;
      if ([nextOffset isKindOfClass:[NSNumber class]]) self.offset = nextOffset.longLongValue;
      if (!error) self.finished = [finished isKindOfClass:[NSNumber class]] ? finished.boolValue : YES;
      NSMutableArray *next = [self.allData mutableCopy] ?: [NSMutableArray array];
      NSMutableSet *loadedIds = [NSMutableSet set];
      for (NEConversationListModel *model in next) {
        if (model.conversationId.length > 0) [loadedIds addObject:model.conversationId];
      }
      for (id value in conversations ?: @[]) {
        if (![value isKindOfClass:[V2NIMConversation class]]) continue;
        V2NIMConversation *conversation = value;
        if (conversation.conversationId.length == 0 ||
            [self.existingIds containsObject:conversation.conversationId] ||
            [loadedIds containsObject:conversation.conversationId]) continue;
        [loadedIds addObject:conversation.conversationId];
        [next addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
      }
      self.allData = next;
      [self applySearch];
      if (completion) completion(error, self.finished);
    });
  }];
}

- (void)search:(NSString *)text {
  self.keyword = [[text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
  [self applySearch];
}

- (void)applySearch {
  if (self.keyword.length == 0) {
    self.displayData = self.allData;
    return;
  }
  self.displayData = [self.allData filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *bindings) {
    return [model.name rangeOfString:self.keyword options:NSCaseInsensitiveSearch].location != NSNotFound;
  }]];
}

- (void)toggle:(NSString *)conversationId {
  if (conversationId.length == 0) return;
  if ([self.mutableSelectedIds containsObject:conversationId]) {
    [self.mutableSelectedIds removeObject:conversationId];
  } else {
    [self.mutableSelectedIds addObject:conversationId];
  }
}

@end

@interface ConversationGroupViewModel () <NEConversationGroupManagerDelegate>
@property(nonatomic, strong) NEConversationGroupManager *manager;
@end

@implementation ConversationGroupViewModel

- (instancetype)init {
  return [self initWithManager:[[NEConversationGroupManager alloc] init]];
}

- (instancetype)initWithManager:(NEConversationGroupManager *)manager {
  self = [super init];
  if (self) {
    _manager = manager ?: [[NEConversationGroupManager alloc] init];
    _manager.delegate = self;
  }
  return self;
}

- (NSArray<NEConversationGroupModel *> *)commonGroups { return (id)self.manager.visibleGroups; }
- (NSArray<NEConversationGroupModel *> *)hiddenGroups { return (id)self.manager.hiddenGroups; }
- (NEConversationGroupModel *)selectedGroup { return self.manager.selectedGroup; }
- (NSArray<NEConversationListModel *> *)selectedCustomData { return self.manager.displayedConversations; }
- (int64_t)selectedCustomOffset { return self.manager.selectedOffset; }
- (BOOL)selectedCustomFinished { return self.manager.selectedGroupFinished; }
- (BOOL)selectedCustomGroupNeedsReload { return self.manager.selectedCustomGroupNeedsReload; }
- (BOOL)isEnabled { return self.manager.isEnabled; }

- (NEConversationGroupItem *)itemForModel:(NEConversationGroupModel *)model {
  for (NEConversationGroupItem *item in self.manager.groups) {
    if (item == model || [item.groupId isEqualToString:model.groupId]) return item;
  }
  if ([model isKindOfClass:[NEConversationGroupItem class]]) return (NEConversationGroupItem *)model;
  NEConversationGroupItem *item = [[NEConversationGroupItem alloc] init];
  item.kind = (NEConversationGroupKind)model.type;
  item.groupId = model.groupId;
  item.name = model.type == NEConversationGroupTypeCustom
      ? NEConversationGroupResolvedName(model.name, model.groupId)
      : model.name;
  item.unreadCount = model.unreadCount;
  item.sdkGroup = model.sdkGroup;
  return item;
}

- (NEConversationGroupItem *)itemForGroupId:(NSString *)groupId {
  for (NEConversationGroupItem *item in self.manager.groups) {
    if ([item.groupId isEqualToString:groupId]) return item;
  }
  NEConversationGroupItem *item = [[NEConversationGroupItem alloc] init];
  item.kind = NEConversationGroupKindCustom;
  item.groupId = groupId ?: @"";
  item.name = item.groupId;
  return item;
}

- (void)loadGroups:(void (^)(NSError *))completion { [self.manager loadGroups:completion]; }
- (void)selectGroup:(NEConversationGroupModel *)group { [self.manager selectGroup:[self itemForModel:group]]; }
- (BOOL)setRetainedConversation:(nullable NSString *)conversationId {
  return [self.manager setRetainedConversation:conversationId];
}
- (NSArray<NEConversationListModel *> *)displayedDataFrom:(NSArray<NEConversationListModel *> *)allData {
  [self.manager updateAllConversations:allData ?: @[]];
  return self.manager.displayedConversations;
}
- (void)loadMoreSelectedCustomGroup:(void (^)(NSError *, BOOL))completion {
  [self.manager loadMoreSelectedGroup:completion];
}
- (void)loadGroupConversationsWithGroupId:(NSString *)groupId
                                   offset:(int64_t)offset
                                    limit:(NSInteger)limit
                               completion:(void (^)(NSArray<NEConversationListModel *> *, int64_t, BOOL, NSError *))completion {
  [self.manager loadConversationsForGroup:[self itemForGroupId:groupId]
                                   offset:offset
                                    limit:limit
                               completion:completion];
}
- (void)loadAllGroupConversationIdsWithGroupId:(NSString *)groupId
                                     completion:(void (^)(NSSet<NSString *> *, NSError *))completion {
  [self.manager loadAllConversationIdsForGroup:[self itemForGroupId:groupId] completion:completion];
}
- (void)createGroupWithName:(NSString *)name
                  completion:(void (^)(V2NIMConversationGroup *, NSError *))completion {
  [self.manager createGroup:name completion:completion];
}
- (void)updateGroupNameWithGroupId:(NSString *)groupId
                              name:(NSString *)name
                        completion:(void (^)(NSError *))completion {
  [self.manager renameGroup:[self itemForGroupId:groupId] name:name completion:completion];
}
- (void)deleteGroupWithGroupId:(NSString *)groupId completion:(void (^)(NSError *))completion {
  [self.manager deleteGroup:[self itemForGroupId:groupId] completion:completion];
}
- (void)addConversationsWithGroupId:(NSString *)groupId
                    conversationIds:(NSArray<NSString *> *)conversationIds
                          completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *, NSError *))completion {
  [self.manager addConversationIds:conversationIds toGroup:[self itemForGroupId:groupId] completion:completion];
}
- (void)removeConversationsWithGroupId:(NSString *)groupId
                       conversationIds:(NSArray<NSString *> *)conversationIds
                             completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *, NSError *))completion {
  [self.manager removeConversationIds:conversationIds fromGroup:[self itemForGroupId:groupId] completion:completion];
}
- (void)refreshSelectedCustomGroup:(void (^)(void))completion {
  [self.manager refreshSelectedCustomGroup:completion];
}
- (void)moveCommonToHidden:(NEConversationGroupModel *)group {
  [self.manager setGroup:[self itemForModel:group] hidden:YES];
}
- (void)moveHiddenToCommon:(NEConversationGroupModel *)group {
  [self.manager setGroup:[self itemForModel:group] hidden:NO];
}
- (void)updateCommonOrder:(NSArray<NEConversationGroupModel *> *)groups {
  for (NSInteger destination = 1; destination < (NSInteger)groups.count; destination++) {
    NSString *groupId = groups[destination].groupId;
    NSInteger source = NSNotFound;
    NSArray<NEConversationGroupItem *> *visible = self.manager.visibleGroups;
    for (NSInteger index = 1; index < (NSInteger)visible.count; index++) {
      if ([visible[index].groupId isEqualToString:groupId]) { source = index; break; }
    }
    if (source != NSNotFound && source != destination) {
      [self.manager moveVisibleGroupFromIndex:source toIndex:destination];
    }
  }
}
- (NSString *)groupErrorMessage:(NSError *)error {
  if (!error) return NEGroupManagerText(@"failed_operation");
  NSDictionary<NSNumber *, NSString *> *keys = @{
    @110304: @"conversation_group_belonged_limit",
    @110404: @"conversation_group_conversation_not_exist",
    @116404: @"conversation_group_not_exist",
    @116435: @"conversation_group_limit",
    @116437: @"conversation_group_members_limit",
  };
  NSString *key = keys[@(error.code)];
  return key ? NEGroupManagerText(key) : (error.localizedDescription ?: NEGroupManagerText(@"failed_operation"));
}
- (void)refreshVirtualCountsWithAllData:(NSArray<NEConversationListModel *> *)allData {
  [self.manager refreshVirtualCounts:allData ?: @[]];
}

- (void)conversationGroupManagerDidReload { [self.delegate conversationGroupDidReload]; }
- (void)conversationGroupManagerSelectionDidChange { [self.delegate conversationGroupSelectionChanged]; }

- (void)onConversationGroupCreated:(V2NIMConversationGroup *)group { [self.manager onConversationGroupCreated:group]; }
- (void)onConversationGroupDeleted:(NSString *)groupId { [self.manager onConversationGroupDeleted:groupId]; }
- (void)onConversationGroupChanged:(V2NIMConversationGroup *)group { [self.manager onConversationGroupChanged:group]; }
- (void)onConversationsAddedToGroup:(NSString *)groupId conversations:(NSArray<V2NIMConversation *> *)conversations {
  [self.manager onConversationsAddedToGroup:groupId conversations:conversations];
}
- (void)onConversationsRemovedFromGroup:(NSString *)groupId conversationIds:(NSArray<NSString *> *)conversationIds {
  [self.manager onConversationsRemovedFromGroup:groupId conversationIds:conversationIds];
}
- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations { [self.manager onConversationChanged:conversations]; }
- (void)onConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds { [self.manager onConversationUnreadCountCleared:conversationIds]; }
- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime { [self.manager onConversationReadTimeUpdated:conversationId :readTime]; }
- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds { [self.manager onConversationDeleted:conversationIds]; }
- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount { [self.manager onTotalUnreadCountChanged:unreadCount]; }
- (void)onConversationSyncFinished { [self.manager onConversationSyncFinished]; }
- (void)onUnreadCountChangedByFilter:(V2NIMConversationFilter *)filter :(NSInteger)unreadCount {
  [self.manager onUnreadCountChangedByFilter:filter :unreadCount];
}

@end

@implementation NEConversationGroupItem
- (instancetype)init {
  self = [super initWithType:NEConversationGroupTypeAll
                     groupId:@""
                        name:@""
                 unreadCount:0
                    sdkGroup:nil];
  return self;
}
- (NEConversationGroupType)type { return (NEConversationGroupType)self.kind; }
@end

@interface NEConversationGroupManager () <NEConversationGroupListener, NEConversationListener>
@property(nonatomic, copy) NSArray<NEConversationGroupItem *> *groups;
@property(nonatomic, strong, nullable) NEConversationGroupItem *selectedGroup;
@property(nonatomic, copy, readwrite) NSArray<NEConversationListModel *> *allConversations;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *customConversations;
@property(nonatomic, assign) int64_t selectedOffset;
@property(nonatomic, assign) BOOL selectedGroupFinished;
@property(nonatomic, assign) BOOL selectedGroupLoading;
@property(nonatomic, assign, readwrite) BOOL selectedCustomGroupNeedsReload;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *unreadConversations;
/// 展开态右列仍在展示的会话：分组过滤后若把它移除了（未读变为已读、@ 被清除），
@property(nonatomic, copy, nullable) NSString *retainedConversationId;
@property(nonatomic, copy, nullable) NSString *retainedConversationGroupId;
@property(nonatomic, assign) int64_t selectedUnreadOffset;
@property(nonatomic, assign) BOOL selectedUnreadFinished;
@property(nonatomic, assign) BOOL selectedUnreadLoading;
@property(nonatomic, assign) NSInteger selectedUnreadRequestID;
@property(nonatomic, assign) BOOL defaultUnreadSubscribed;
@property(nonatomic, strong) NSMutableSet<NSString *> *subscribedUnreadGroupIds;
@property(nonatomic, assign) BOOL listenersRegistered;
- (void)saveConfigOrder:(NSArray<NSString *> *)visibleOrder hidden:(NSArray<NSString *> *)hidden;
- (void)loadUnreadPageWithOption:(V2NIMConversationOption *)option
                        requestID:(NSInteger)requestID
                       completion:(void (^_Nullable)(NSError *_Nullable error, BOOL finished))completion;
- (void)clearGroupState;
- (NSError *)featureDisabledError;
- (void)insertNewVisibleGroup:(V2NIMConversationGroup *)group;
- (void)removeGroup:(NSString *)groupId;
- (void)loadAllConversationIdsForGroupId:(NSString *)groupId
                                  offset:(int64_t)offset
                                     ids:(NSMutableSet<NSString *> *)ids
                              completion:(void (^)(NSSet<NSString *> *_Nullable conversationIds,
                                                   NSError *_Nullable error))completion;
/// The user's explicit order for the Hidden section. Keep this separate from
/// the server's group order so a Common -> Hidden move cannot be promoted to
/// the first hidden row by a listener reload.
@property(nonatomic, strong) NSMutableArray<NSString *> *hiddenOrder;
@end

@implementation NEConversationGroupManager

- (instancetype)init {
  self = [super init];
  if (self) {
    _groups = @[];
    _allConversations = @[];
    _customConversations = @[];
    _unreadConversations = @[];
    _selectedGroupFinished = YES;
    _selectedUnreadFinished = YES;
    _subscribedUnreadGroupIds = [NSMutableSet set];
    _hiddenOrder = [NSMutableArray array];
    [self syncEnabledState];
    // Do not rebuild or persist a placeholder group list before the SDK has
    // returned the server groups. Rebuilding with an empty array here would
    // overwrite the account's saved order/visibility configuration, causing
    // a group moved to Common to become Hidden after a process restart.
  }
  return self;
}

- (void)dealloc {
  if (self.listenersRegistered) {
    [self clearUnreadSubscriptions];
    [[ConversationGroupRepo shared] removeConversationGroupListener:self];
    [[ConversationRepo shared] removeConversationListener:self];
  }
}

- (NSString *)configKey {
  NSString *account = [[IMKitClient instance] account];
  return [NSString stringWithFormat:@"NEConversationGroupConfig_%@", account ?: @""];
}

- (NSString *)legacyConfigKey {
  NSString *account = [[IMKitClient instance] account];
  return [NSString stringWithFormat:@"NEConversationGroupConfig_%@_OC", account ?: @""];
}

- (BOOL)isEnabled {
  return [IMKitConfigCenter shared].enableConversationGroup && [NIMSDK sharedSDK].v2Option.enableV2CloudConversation;
}

- (BOOL)syncEnabledState {
  if (self.isEnabled) {
    if (!self.listenersRegistered) {
      [[ConversationGroupRepo shared] addConversationGroupListener:self];
      [[ConversationRepo shared] addConversationListener:self];
      self.listenersRegistered = YES;
    }
    return YES;
  }

  self.selectedUnreadRequestID += 1;
  if (self.listenersRegistered) {
    [self clearUnreadSubscriptions];
    [[ConversationGroupRepo shared] removeConversationGroupListener:self];
    [[ConversationRepo shared] removeConversationListener:self];
    self.listenersRegistered = NO;
  }
  [self clearGroupState];
  return NO;
}

- (void)clearGroupState {
  self.groups = @[];
  self.selectedGroup = nil;
  self.retainedConversationId = nil;
  self.retainedConversationGroupId = nil;
  self.customConversations = @[];
  self.unreadConversations = @[];
  self.selectedOffset = 0;
  self.selectedGroupFinished = YES;
  self.selectedGroupLoading = NO;
  self.selectedCustomGroupNeedsReload = NO;
  self.selectedUnreadOffset = 0;
  self.selectedUnreadFinished = YES;
  self.selectedUnreadLoading = NO;
}

- (NSDictionary *)storedConfig {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id value = [defaults objectForKey:[self configKey]];
  if (!value) {
    // Older OC builds used a suffixed key and a property-list dictionary. Read
    // it once so an upgrade does not reset the user's group layout.
    value = [defaults objectForKey:[self legacyConfigKey]];
  }
  if ([value isKindOfClass:[NSData class]]) {
    id decoded = [NSJSONSerialization JSONObjectWithData:value options:0 error:nil];
    if ([decoded isKindOfClass:[NSDictionary class]]) {
      NSMutableArray *order = [NSMutableArray array];
      NSMutableArray *hidden = [NSMutableArray array];
      NSArray *items = [decoded[@"items"] isKindOfClass:[NSArray class]] ? decoded[@"items"] : @[];
      NSArray *sortedItems = [items sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"order"] integerValue] < [right[@"order"] integerValue] ? NSOrderedAscending : NSOrderedDescending;
      }];
      for (NSDictionary *item in sortedItems) {
        NSString *groupId = [item[@"groupId"] isKindOfClass:[NSString class]] ? item[@"groupId"] : nil;
        if (groupId.length == 0) continue;
        if ([item[@"hidden"] boolValue]) [hidden addObject:groupId];
        else [order addObject:groupId];
      }
      return @{ @"order": order, @"hidden": hidden };
    }
  }
  if ([value isKindOfClass:[NSDictionary class]]) {
    NSArray *order = [value[@"order"] isKindOfClass:[NSArray class]] ? value[@"order"] : @[];
    NSArray *hidden = [value[@"hidden"] isKindOfClass:[NSArray class]] ? value[@"hidden"] : @[];
    return @{ @"order": order, @"hidden": hidden };
  }
  return @{};
}

- (void)saveConfig {
  // Persist the two sections independently. A Common -> Hidden move must be
  // appended after the existing hidden sequence even when the SDK reload
  // returns groups in a different order.
  NSDictionary *oldConfig = [self storedConfig];
  NSArray *oldHidden = self.hiddenOrder.count > 0
    ? [self.hiddenOrder copy]
    : ([oldConfig[@"hidden"] isKindOfClass:[NSArray class]] ? oldConfig[@"hidden"] : @[]);
  NSMutableSet *currentIds = [NSMutableSet set];
  NSMutableArray *visibleOrder = [NSMutableArray array];
  NSMutableArray *hidden = [NSMutableArray array];
  for (NEConversationGroupItem *item in self.groups) {
    if (item.kind == NEConversationGroupKindAll || item.groupId.length == 0) continue;
    [currentIds addObject:item.groupId];
    if (item.isHidden) continue;
    [visibleOrder addObject:item.groupId];
  }
  for (NSString *groupId in oldHidden) {
    if ([groupId isKindOfClass:[NSString class]] && [currentIds containsObject:groupId]) {
      NEConversationGroupItem *item = [self groupForId:groupId];
      if (item.isHidden && ![hidden containsObject:groupId]) [hidden addObject:groupId];
    }
  }
  // Any newly hidden item, including the one just moved out of Common, is
  // appended after the persisted hidden sequence.
  for (NEConversationGroupItem *item in self.groups) {
    if (item.kind != NEConversationGroupKindAll && item.isHidden && item.groupId.length > 0 && ![hidden containsObject:item.groupId]) {
      [hidden addObject:item.groupId];
    }
  }
  NSMutableArray *order = [visibleOrder mutableCopy];
  [order addObjectsFromArray:hidden];
  self.hiddenOrder = [hidden mutableCopy];
  [self saveConfigOrder:visibleOrder hidden:hidden];
}

- (void)saveConfigOrder:(NSArray<NSString *> *)visibleOrder hidden:(NSArray<NSString *> *)hidden {
  NSMutableArray *items = [NSMutableArray array];
  for (NSUInteger index = 0; index < visibleOrder.count; index++) {
    [items addObject:@{ @"groupId": visibleOrder[index], @"hidden": @NO, @"order": @(index) }];
  }
  for (NSUInteger index = 0; index < hidden.count; index++) {
    [items addObject:@{ @"groupId": hidden[index], @"hidden": @YES, @"order": @(visibleOrder.count + index) }];
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:@{ @"items": items } options:0 error:nil];
  if (data) [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self configKey]];
}

- (NEConversationGroupItem *)groupForId:(NSString *)groupId {
  for (NEConversationGroupItem *item in self.groups) {
    if ([item.groupId isEqualToString:groupId]) return item;
  }
  return nil;
}

- (NSArray<NEConversationGroupItem *> *)visibleGroups {
  return [self.groups filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationGroupItem *item, NSDictionary *_) {
    return !item.isHidden;
  }]];
}

- (NSArray<NEConversationGroupItem *> *)hiddenGroups {
  NSArray<NEConversationGroupItem *> *hidden = [self.groups filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationGroupItem *item, NSDictionary *_) {
    return item.isHidden;
  }]];
  NSArray *storedOrder = self.hiddenOrder.count > 0
    ? [self.hiddenOrder copy]
    : [self storedConfig][@"hidden"];
  if (![storedOrder isKindOfClass:[NSArray class]] || storedOrder.count == 0) return hidden;

  NSMutableDictionary<NSString *, NEConversationGroupItem *> *itemsById = [NSMutableDictionary dictionary];
  for (NEConversationGroupItem *item in hidden) {
    if (item.groupId.length > 0) itemsById[item.groupId] = item;
  }
  NSMutableArray<NEConversationGroupItem *> *ordered = [NSMutableArray arrayWithCapacity:hidden.count];
  for (id value in storedOrder) {
    if (![value isKindOfClass:[NSString class]]) continue;
    NEConversationGroupItem *item = itemsById[value];
    if (!item) continue;
    [ordered addObject:item];
    [itemsById removeObjectForKey:value];
  }
  // Preserve the manager's current order for first-seen hidden groups. A
  // Common -> Hidden move appends the item to self.groups, so it remains the
  // last row even before the next persistence/reload cycle completes.
  for (NEConversationGroupItem *item in hidden) {
    if (item.groupId.length == 0 || itemsById[item.groupId]) {
      [ordered addObject:item];
      if (item.groupId.length > 0) [itemsById removeObjectForKey:item.groupId];
    }
  }
  return ordered;
}

- (void)updateAllConversations:(NSArray<NEConversationListModel *> *)conversations {
  NSMutableArray *safe = [NSMutableArray array];
  for (id value in conversations ?: @[]) {
    if ([value isKindOfClass:[NEConversationListModel class]]) [safe addObject:value];
  }
  self.allConversations = safe;
  [self refreshVirtualCounts:safe];
  [self refreshUnreadCounts];
  if (self.selectedGroup.kind != NEConversationGroupKindCustom && self.selectedGroup.kind != NEConversationGroupKindUnread) {
    [self.delegate conversationGroupManagerSelectionDidChange];
  }
}

- (NSArray<NEConversationListModel *> *)displayedConversations {
  NSArray<NEConversationListModel *> *data;
  switch (self.selectedGroup.kind) {
    case NEConversationGroupKindAtMe:
      data = [self.allConversations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationListModel *model, NSDictionary *_) {
        return model.conversationId.length > 0 &&
          [V2NIMConversationIdUtil conversationType:model.conversationId] == V2NIM_CONVERSATION_TYPE_TEAM &&
          [NEAtMessageManager.instance isAtCurrentUserConversationId:model.conversationId];
      }]];
      break;
    case NEConversationGroupKindUnread:
      data = self.unreadConversations ?: @[];
      break;
    case NEConversationGroupKindCustom:
      data = self.customConversations ?: @[];
      break;
    case NEConversationGroupKindAll:
    default:
      // “全部”分组本身不会过滤掉任何会话，无需合并保留行。
      return self.allConversations ?: @[];
  }
  return [self mergingRetainedConversationInto:data];
}

- (BOOL)setRetainedConversation:(nullable NSString *)conversationId {
  NSString *normalized = conversationId.length > 0 ? conversationId : nil;
  if (self.retainedConversationId == normalized ||
      [self.retainedConversationId isEqualToString:normalized]) {
    return NO;
  }
  self.retainedConversationId = normalized;
  self.retainedConversationGroupId = normalized ? self.selectedGroup.groupId : nil;
  return YES;
}

/// 未读/@我 分组在已读或清除 @ 后会按规则移除该行；展开态右列还展示着它时，
- (NSArray<NEConversationListModel *> *)mergingRetainedConversationInto:(NSArray<NEConversationListModel *> *)data {
  NSArray<NEConversationListModel *> *safeData = data ?: @[];
  NSString *retained = self.retainedConversationId;
  if (retained.length == 0) {
    return safeData;
  }
  NSString *selectedGroupId = self.selectedGroup.groupId ?: @"";
  NSString *retainedGroupId = self.retainedConversationGroupId ?: @"";
  if (![selectedGroupId isEqualToString:retainedGroupId]) {
    return safeData;
  }
  NEConversationListModel *conversation = nil;
  for (NEConversationListModel *model in self.allConversations) {
    if ([model.conversationId isEqualToString:retained]) {
      conversation = model;
      break;
    }
  }
  if (!conversation) {
    return safeData;
  }
  for (NEConversationListModel *model in safeData) {
    if ([model.conversationId isEqualToString:retained]) {
      return safeData;
    }
  }
  NSMutableArray<NEConversationListModel *> *merged = [NSMutableArray arrayWithArray:safeData];
  [merged addObject:conversation];
  [merged sortUsingComparator:^NSComparisonResult(NEConversationListModel *lhs, NEConversationListModel *rhs) {
    if (lhs.sortOrder == rhs.sortOrder) {
      return NSOrderedSame;
    }
    return lhs.sortOrder > rhs.sortOrder ? NSOrderedAscending : NSOrderedDescending;
  }];
  return merged;
}

- (void)loadGroups:(void (^)(NSError *))completion {
  if (![self syncEnabledState]) {
    if (completion) completion(nil);
    return;
  }
  [[ConversationGroupRepo shared] getConversationGroupList:^(NSArray<V2NIMConversationGroup *> *groups, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!self.isEnabled) {
        if (completion) completion(nil);
        return;
      }
      if (!error) [self rebuildGroups:groups ?: @[]];
      if (completion) completion(error);
    });
  }];
}

- (void)refreshLocalizedDefaultGroupNames {
  if (![self syncEnabledState]) return;
  NSDictionary<NSNumber *, NSString *> *names = @{
    @(NEConversationGroupKindAll): NEGroupManagerText(@"conversation_group_all"),
    @(NEConversationGroupKindAtMe): NEGroupManagerText(@"conversation_group_at_me"),
    @(NEConversationGroupKindUnread): NEGroupManagerText(@"conversation_group_unread"),
  };
  BOOL changed = NO;
  for (NEConversationGroupItem *item in self.groups) {
    NSString *name = names[@(item.kind)];
    if (name.length > 0 && ![item.name isEqualToString:name]) {
      item.name = name;
      changed = YES;
    }
  }
  if (changed) [self.delegate conversationGroupManagerDidReload];
}

- (void)refreshVirtualCounts:(NSArray<NEConversationListModel *> *)allData {
  if (![self syncEnabledState]) return;
  NSInteger atMeCount = 0;
  for (NEConversationListModel *model in allData ?: @[]) {
    if (model.conversationId.length > 0 &&
        [V2NIMConversationIdUtil conversationType:model.conversationId] == V2NIM_CONVERSATION_TYPE_TEAM &&
        [NEAtMessageManager.instance isAtCurrentUserConversationId:model.conversationId]) {
      atMeCount += 1;
    }
  }
  for (NEConversationGroupItem *item in self.groups) {
    if (item.kind == NEConversationGroupKindAtMe) item.unreadCount = atMeCount;
  }
}

- (void)rebuildGroups:(NSArray *)sdkValues {
  NSDictionary *config = [self storedConfig];
  NSArray *storedOrder = [config[@"order"] isKindOfClass:[NSArray class]] ? config[@"order"] : @[];
  NSArray *storedHiddenOrder = [config[@"hidden"] isKindOfClass:[NSArray class]] ? config[@"hidden"] : @[];
  // Reconcile persisted order once per SDK reload. Subsequent visibility
  // changes update this array before saveConfig, so the latest move wins over
  // any order returned by the server.
  self.hiddenOrder = [storedHiddenOrder mutableCopy] ?: [NSMutableArray array];
  NSSet *hiddenIds = [NSSet setWithArray:storedHiddenOrder];
  NSMutableArray<NEConversationGroupItem *> *items = [NSMutableArray array];
  [items addObject:[self defaultItem:NEConversationGroupKindAll groupId:NEGroupAllId name:NEGroupManagerText(@"conversation_group_all")]];
  NEConversationGroupItem *atMeItem = [self defaultItem:NEConversationGroupKindAtMe
                                                groupId:NEGroupAtMeId
                                                   name:NEGroupManagerText(@"conversation_group_at_me")];
  atMeItem.hidden = [hiddenIds containsObject:atMeItem.groupId];
  [items addObject:atMeItem];
  NEConversationGroupItem *unreadItem = [self defaultItem:NEConversationGroupKindUnread
                                                  groupId:NEGroupUnreadId
                                                     name:NEGroupManagerText(@"conversation_group_unread")];
  unreadItem.hidden = [hiddenIds containsObject:unreadItem.groupId];
  [items addObject:unreadItem];
  for (id value in sdkValues ?: @[]) {
    if (![value isKindOfClass:[V2NIMConversationGroup class]]) continue;
    V2NIMConversationGroup *sdkGroup = value;
    if (![sdkGroup.groupId isKindOfClass:[NSString class]] || sdkGroup.groupId.length == 0) continue;
    NEConversationGroupItem *item = [[NEConversationGroupItem alloc] init];
    item.kind = NEConversationGroupKindCustom;
    item.groupId = sdkGroup.groupId;
    item.name = NEConversationGroupResolvedName(sdkGroup.name, sdkGroup.groupId);
    item.sdkGroup = sdkGroup;
    // Match the Swift implementation: a server group with no local
    // visibility record is initially placed in Hidden until the user shows it.
    item.hidden = [hiddenIds containsObject:item.groupId] ||
                  (![storedOrder containsObject:item.groupId]);
    [items addObject:item];
  }
  // The hidden sequence is independent from the Common sequence. Older
  // installs may not yet contain a group in `hidden` when a visibility change
  // races the next SDK reload; rank such IDs after every persisted hidden ID
  // so a newly hidden Common group always appears at the end.
  NSMutableDictionary<NSString *, NSNumber *> *hiddenRank = [NSMutableDictionary dictionary];
  NSInteger nextHiddenRank = 0;
  for (NSString *groupId in storedHiddenOrder) {
    if ([groupId isKindOfClass:[NSString class]] && groupId.length > 0 && !hiddenRank[groupId]) {
      hiddenRank[groupId] = @(nextHiddenRank++);
    }
  }
  for (NEConversationGroupItem *item in items) {
    if (item.isHidden && item.groupId.length > 0 && !hiddenRank[item.groupId]) {
      hiddenRank[item.groupId] = @(nextHiddenRank++);
      [self.hiddenOrder addObject:item.groupId];
    }
  }
  [items sortUsingComparator:^NSComparisonResult(NEConversationGroupItem *left, NEConversationGroupItem *right) {
    if (left.kind == NEConversationGroupKindAll) return NSOrderedAscending;
    if (right.kind == NEConversationGroupKindAll) return NSOrderedDescending;
    // Keep visible groups together ahead of hidden groups. The persisted
    // order spans both sections, so comparing it alone can put a newly hidden
    // Common group at the top of Hidden after a reload.
    if (left.isHidden != right.isHidden) {
      return left.isHidden ? NSOrderedDescending : NSOrderedAscending;
    }
    if (left.isHidden && right.isHidden) {
      NSInteger lhi = hiddenRank[left.groupId].integerValue;
      NSInteger rhi = hiddenRank[right.groupId].integerValue;
      if (lhi != rhi) return lhi < rhi ? NSOrderedAscending : NSOrderedDescending;
    }
    NSInteger li = [storedOrder indexOfObject:left.groupId];
    NSInteger ri = [storedOrder indexOfObject:right.groupId];
    li = li == NSNotFound ? NSIntegerMax : li;
    ri = ri == NSNotFound ? NSIntegerMax : ri;
    if (li == ri) return [left.groupId compare:right.groupId];
    return li < ri ? NSOrderedAscending : NSOrderedDescending;
  }];
  NSString *selectedId = self.selectedGroup.groupId;
  self.groups = items;
  self.selectedGroup = [items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEConversationGroupItem *item, NSDictionary *_) {
    return selectedId.length > 0 && [item.groupId isEqualToString:selectedId] && !item.isHidden;
  }]].firstObject ?: items.firstObject;
  [self refreshUnreadCounts];
  [self syncUnreadSubscriptions];
  [self saveConfig];
  [self.delegate conversationGroupManagerDidReload];
  [self.delegate conversationGroupManagerSelectionDidChange];
}

- (NEConversationGroupItem *)defaultItem:(NEConversationGroupKind)kind groupId:(NSString *)groupId name:(NSString *)name {
  NEConversationGroupItem *item = [[NEConversationGroupItem alloc] init];
  item.kind = kind;
  item.groupId = groupId;
  item.name = name;
  return item;
}

- (void)refreshUnreadCounts {
  [self refreshSDKUnreadCounts];
}

- (V2NIMConversationFilter *)unreadFilterForGroupId:(NSString *)groupId {
  V2NIMConversationFilter *filter = [[V2NIMConversationFilter alloc] init];
  filter.conversationGroupId = [groupId isKindOfClass:[NSString class]] && groupId.length > 0 ? groupId : nil;
  filter.ignoreMuted = YES;
  return filter;
}

- (void)refreshSDKUnreadCounts {
  __weak typeof(self) weakSelf = self;
  [[ConversationGroupRepo shared] getUnreadCountByFilter:[self unreadFilterForGroupId:nil] completion:^(NSNumber *count, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !self.isEnabled || error || ![count isKindOfClass:[NSNumber class]]) return;
      BOOL changed = NO;
      for (NEConversationGroupItem *item in self.groups) {
        if (item.kind != NEConversationGroupKindAll && item.kind != NEConversationGroupKindUnread) continue;
        changed = changed || item.unreadCount != count.integerValue;
        item.unreadCount = count.integerValue;
      }
      if (changed) [self.delegate conversationGroupManagerDidReload];
    });
  }];
  for (NEConversationGroupItem *item in self.groups) {
    if (item.kind != NEConversationGroupKindCustom || item.groupId.length == 0) continue;
    NSString *groupId = item.groupId;
    [[ConversationGroupRepo shared] getUnreadCountByFilter:[self unreadFilterForGroupId:groupId] completion:^(NSNumber *count, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.isEnabled || error || ![count isKindOfClass:[NSNumber class]]) return;
        for (NEConversationGroupItem *candidate in self.groups) {
          if (candidate.kind == NEConversationGroupKindCustom && [candidate.groupId isEqualToString:groupId]) {
            candidate.unreadCount = count.integerValue;
          }
        }
        [self.delegate conversationGroupManagerDidReload];
      });
    }];
  }
}

- (void)syncUnreadSubscriptions {
  ConversationGroupRepo *repo = [ConversationGroupRepo shared];
  if (!self.defaultUnreadSubscribed && [repo subscribeUnreadCountByFilter:[self unreadFilterForGroupId:nil]] == nil) {
    self.defaultUnreadSubscribed = YES;
  }
  NSMutableSet *currentIds = [NSMutableSet set];
  for (NEConversationGroupItem *item in self.groups) {
    if (item.kind == NEConversationGroupKindCustom && item.groupId.length > 0) [currentIds addObject:item.groupId];
  }
  for (NSString *groupId in [self.subscribedUnreadGroupIds copy]) {
    if (![currentIds containsObject:groupId]) {
      [repo unsubscribeUnreadCountByFilter:[self unreadFilterForGroupId:groupId]];
      [self.subscribedUnreadGroupIds removeObject:groupId];
    }
  }
  for (NSString *groupId in currentIds) {
    if (![self.subscribedUnreadGroupIds containsObject:groupId] &&
        [repo subscribeUnreadCountByFilter:[self unreadFilterForGroupId:groupId]] == nil) {
      [self.subscribedUnreadGroupIds addObject:groupId];
    }
  }
}

- (void)clearUnreadSubscriptions {
  ConversationGroupRepo *repo = [ConversationGroupRepo shared];
  if (self.defaultUnreadSubscribed) {
    [repo unsubscribeUnreadCountByFilter:[self unreadFilterForGroupId:nil]];
    self.defaultUnreadSubscribed = NO;
  }
  for (NSString *groupId in [self.subscribedUnreadGroupIds copy]) {
    [repo unsubscribeUnreadCountByFilter:[self unreadFilterForGroupId:groupId]];
  }
  [self.subscribedUnreadGroupIds removeAllObjects];
}

- (void)selectGroup:(NEConversationGroupItem *)group {
  if (![self syncEnabledState] || ![group isKindOfClass:[NEConversationGroupItem class]] || group.isHidden) return;
  self.selectedUnreadRequestID += 1;
  self.selectedGroup = group;
  if (group.kind == NEConversationGroupKindCustom) {
    [self reloadSelectedCustomGroup];
  } else if (group.kind == NEConversationGroupKindUnread) {
    self.unreadConversations = @[];
    self.selectedUnreadOffset = 0;
    self.selectedUnreadFinished = NO;
    self.selectedUnreadLoading = NO;
    [self.delegate conversationGroupManagerSelectionDidChange];
    [self loadMoreSelectedUnreadGroup:nil];
  }
  else [self.delegate conversationGroupManagerSelectionDidChange];
  [self.delegate conversationGroupManagerDidReload];
}

- (void)reloadSelectedCustomGroup {
  if (![self syncEnabledState]) return;
  self.customConversations = @[];
  self.selectedOffset = 0;
  self.selectedGroupFinished = NO;
  self.selectedGroupLoading = NO;
  // Clear the previous group's rows before the asynchronous SDK page returns.
  // Without this callback, the old list remains visible until another page
  // lifecycle event triggers a table reload.
  [self.delegate conversationGroupManagerSelectionDidChange];
  [self loadMoreSelectedGroup:nil];
}

- (void)refreshSelectedCustomGroup:(void (^)(void))completion {
  if (![self syncEnabledState] || self.selectedGroup.kind != NEConversationGroupKindCustom) {
    self.selectedCustomGroupNeedsReload = NO;
    if (completion) completion();
    return;
  }
  self.selectedCustomGroupNeedsReload = NO;
  self.customConversations = @[];
  self.selectedOffset = 0;
  self.selectedGroupFinished = NO;
  self.selectedGroupLoading = NO;
  [self.delegate conversationGroupManagerSelectionDidChange];
  [self loadMoreSelectedGroup:^(__unused NSError *error, __unused BOOL finished) {
    if (completion) completion();
  }];
}

- (void)loadMoreSelectedUnreadGroup:(void (^)(NSError *, BOOL))completion {
  if (![self syncEnabledState] || self.selectedGroup.kind != NEConversationGroupKindUnread || self.selectedUnreadFinished || self.selectedUnreadLoading) {
    if (completion) completion(nil, self.selectedUnreadFinished);
    return;
  }
  self.selectedUnreadLoading = YES;
  NSInteger requestID = self.selectedUnreadRequestID;
  V2NIMConversationOption *option = [[V2NIMConversationOption alloc] init];
  option.onlyUnread = YES;
  [self loadUnreadPageWithOption:option requestID:requestID completion:completion];
}

- (void)loadUnreadPageWithOption:(V2NIMConversationOption *)option
                        requestID:(NSInteger)requestID
                       completion:(void (^)(NSError *, BOOL))completion {
  __weak typeof(self) weakSelf = self;
  [[ConversationRepo shared] getConversationListByOption:self.selectedUnreadOffset
                                                   limit:50
                                                  option:option
                                              completion:^(V2NIMConversationResult *result, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !self.isEnabled || requestID != self.selectedUnreadRequestID || self.selectedGroup.kind != NEConversationGroupKindUnread) {
        return;
      }
      if (error) {
        self.selectedUnreadLoading = NO;
        if (completion) completion(error, self.selectedUnreadFinished);
        return;
      }
      int64_t currentOffset = self.selectedUnreadOffset;
      int64_t nextOffset = result ? result.offset : currentOffset;
      self.selectedUnreadOffset = nextOffset;
      self.selectedUnreadFinished = result ? result.finished : YES;
      if (!self.selectedUnreadFinished && nextOffset == currentOffset) {
        self.selectedUnreadFinished = YES;
      }

      NSMutableArray<NEConversationListModel *> *models = [NSMutableArray array];
      for (V2NIMConversation *conversation in result.conversationList ?: @[]) {
        if (conversation.mute || conversation.unreadCount <= 0 || conversation.conversationId.length == 0) continue;
        [models addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
      }
      NSMutableArray *next = [self.unreadConversations mutableCopy] ?: [NSMutableArray array];
      NSMutableSet *existingIds = [NSMutableSet set];
      for (NEConversationListModel *model in next) if (model.conversationId.length > 0) [existingIds addObject:model.conversationId];
      for (NEConversationListModel *model in models) {
        if (![existingIds containsObject:model.conversationId]) {
          [existingIds addObject:model.conversationId];
          [next addObject:model];
        }
      }
      [next sortUsingComparator:^NSComparisonResult(NEConversationListModel *left, NEConversationListModel *right) {
        if (left.sortOrder == right.sortOrder) return NSOrderedSame;
        return left.sortOrder > right.sortOrder ? NSOrderedAscending : NSOrderedDescending;
      }];
      self.unreadConversations = next;
      if (models.count == 0 && !self.selectedUnreadFinished) {
        [self loadUnreadPageWithOption:option requestID:requestID completion:completion];
        return;
      }
      self.selectedUnreadLoading = NO;
      [self.delegate conversationGroupManagerSelectionDidChange];
      if (completion) completion(nil, self.selectedUnreadFinished);
    });
  }];
}

- (void)loadMoreSelectedGroup:(void (^)(NSError *, BOOL))completion {
  if (![self syncEnabledState]) {
    if (completion) completion(nil, YES);
    return;
  }
  if (self.selectedGroup.kind != NEConversationGroupKindCustom || self.selectedGroupFinished || self.selectedGroupLoading) {
    if (completion) completion(nil, self.selectedGroupFinished);
    return;
  }
  NSString *groupId = self.selectedGroup.groupId;
  if (groupId.length == 0) {
    self.selectedGroupFinished = YES;
    if (completion) completion(nil, YES);
    return;
  }
  self.selectedGroupLoading = YES;
  int64_t requestOffset = self.selectedOffset;
  [[ConversationGroupRepo shared] getConversationPageByGroupId:groupId offset:requestOffset limit:50 completion:^(NEConversationGroupPageResult *page, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.selectedGroupLoading = NO;
      if (!error && [page isKindOfClass:[NEConversationGroupPageResult class]]) {
        NSMutableArray *next = [self.customConversations mutableCopy] ?: [NSMutableArray array];
        NSMutableSet *ids = [NSMutableSet setWithArray:[next valueForKey:@"conversationId"] ?: @[]];
        for (id value in page.conversations ?: @[]) {
          if (![value isKindOfClass:[V2NIMConversation class]]) continue;
          V2NIMConversation *conversation = value;
          if (conversation.conversationId.length == 0 || [ids containsObject:conversation.conversationId]) continue;
          [ids addObject:conversation.conversationId];
          [next addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
        }
        [next sortUsingComparator:^NSComparisonResult(NEConversationListModel *left, NEConversationListModel *right) {
          return left.sortOrder > right.sortOrder ? NSOrderedAscending : NSOrderedDescending;
        }];
        self.customConversations = next;
        self.selectedOffset = page.offset;
        self.selectedGroupFinished = page.finished || page.offset == requestOffset;
        [self.delegate conversationGroupManagerSelectionDidChange];
      }
      if (completion) completion(error, self.selectedGroupFinished);
    });
  }];
}

- (void)createGroup:(NSString *)name completion:(void (^)(V2NIMConversationGroup *, NSError *))completion {
  if (![self syncEnabledState]) {
    if (completion) completion(nil, [self featureDisabledError]);
    return;
  }
  NSString *safeName = [[name isKindOfClass:[NSString class]] ? name : @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  [[ConversationGroupRepo shared] createConversationGroup:safeName serverExtension:nil conversationIds:nil :^(V2NIMConversationGroupResult *result, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      V2NIMConversationGroup *group = [result.group isKindOfClass:[V2NIMConversationGroup class]] ? result.group : nil;
      if (!self.isEnabled) {
        if (completion) completion(nil, [self featureDisabledError]);
        return;
      }
      if (group) {
        [self insertNewVisibleGroup:group];
        [self refreshUnreadCounts];
        [self syncUnreadSubscriptions];
        [self.delegate conversationGroupManagerDidReload];
        if (completion) completion(group, nil);
        return;
      }
      if (completion) completion(nil, error);
    });
  }];
}

- (void)renameGroup:(NEConversationGroupItem *)group name:(NSString *)name completion:(void (^)(NSError *))completion {
  if (![self syncEnabledState]) { if (completion) completion([self featureDisabledError]); return; }
  if (group.kind != NEConversationGroupKindCustom || group.groupId.length == 0) { if (completion) completion(nil); return; }
  [[ConversationGroupRepo shared] updateConversationGroup:group.groupId name:name serverExtension:nil :^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{ if (!error) [self loadGroups:nil]; if (completion) completion(error); });
  }];
}

- (void)deleteGroup:(NEConversationGroupItem *)group completion:(void (^)(NSError *))completion {
  if (![self syncEnabledState]) { if (completion) completion([self featureDisabledError]); return; }
  if (group.kind != NEConversationGroupKindCustom || group.groupId.length == 0) { if (completion) completion(nil); return; }
  [[ConversationGroupRepo shared] deleteConversationGroup:group.groupId :^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!self.isEnabled) {
        if (completion) completion([self featureDisabledError]);
        return;
      }
      if (!error) [self removeGroup:group.groupId];
      if (completion) completion(error);
    });
  }];
}

- (void)setGroup:(NEConversationGroupItem *)group hidden:(BOOL)hidden {
  if (![self syncEnabledState]) return;
  if (group.kind == NEConversationGroupKindAll) return;
  // Keep a group moved between sections at the end of its destination. This
  // is especially important for Common -> Hidden: the just-hidden group must
  // not become the first hidden item because the stored common order predates
  // the section move.
  NSMutableArray *next = [self.groups mutableCopy] ?: [NSMutableArray array];
  // The settings controller may hand back a value-equivalent model created
  // from the SDK callback. Locate it by stable groupId instead of object
  // identity so moving between sections is deterministic after a reload.
  NSUInteger index = NSNotFound;
  for (NSUInteger i = 0; i < next.count; i++) {
    NEConversationGroupItem *candidate = next[i];
    if (candidate == group ||
        (candidate.groupId.length > 0 && [candidate.groupId isEqualToString:group.groupId])) {
      index = i;
      group = candidate;
      break;
    }
  }
  if (index != NSNotFound) {
    // The controller can pass an item rebuilt from an SDK callback. Apply the
    // requested state to the object that is actually retained by the manager,
    // otherwise the section filter still sees the old visibility value.
    group.hidden = hidden;
    [next removeObjectAtIndex:index];
    NSUInteger insertion = next.count;
    if (!hidden) {
      NSInteger lastVisible = -1;
      for (NSInteger i = 0; i < next.count; i++) {
        NEConversationGroupItem *item = next[i];
        if (!item.isHidden) lastVisible = i;
      }
      insertion = MIN((NSUInteger)(lastVisible + 1), next.count);
    }
    [next insertObject:group atIndex:insertion];
    self.groups = next;

    // Re-hiding a group must be treated as a new placement in the Hidden
    // section. Older configurations may already contain this ID at an
    // earlier rank; letting saveConfig merge from that stale array would keep
    // the group at the front instead of the end of Hidden.
    if (hidden && group.groupId.length > 0) {
      [self.hiddenOrder removeObject:group.groupId];
      [self.hiddenOrder addObject:group.groupId];
    } else if (!hidden && group.groupId.length > 0) {
      [self.hiddenOrder removeObject:group.groupId];
    }
  }
  if (hidden && self.selectedGroup == group) self.selectedGroup = self.groups.firstObject;
  [self saveConfig];
  [self.delegate conversationGroupManagerDidReload];
  [self.delegate conversationGroupManagerSelectionDidChange];
}

- (void)moveVisibleGroupFromIndex:(NSInteger)source toIndex:(NSInteger)destination {
  NSMutableArray *visible = [self.visibleGroups mutableCopy];
  if (source <= 0 || destination <= 0 || source >= visible.count || destination >= visible.count) return;
  NEConversationGroupItem *item = visible[source];
  [visible removeObjectAtIndex:source];
  [visible insertObject:item atIndex:destination];
  NSMutableArray *next = [visible mutableCopy];
  [next addObjectsFromArray:self.hiddenGroups];
  self.groups = next;
  [self saveConfig];
  [self.delegate conversationGroupManagerDidReload];
}

- (void)addConversationIds:(NSArray<NSString *> *)ids toGroup:(NEConversationGroupItem *)group completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *, NSError *))completion {
  if (![self syncEnabledState]) { if (completion) completion(nil, [self featureDisabledError]); return; }
  NSArray *safe = [self safeStringArray:ids];
  [[ConversationGroupRepo shared] addConversationsToGroup:group.groupId conversationIds:safe :^(NSArray<V2NIMConversationOperationResult *> *results, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSArray *safeResults = [results isKindOfClass:[NSArray class]] ? results : nil;
      BOOL hasSuccessfulResult = NO;
      for (id value in safeResults) {
        if (![value isKindOfClass:[V2NIMConversationOperationResult class]]) continue;
        V2NIMConversationOperationResult *result = value;
        V2NIMError *operationError = [result.error isKindOfClass:[V2NIMError class]] ? result.error : nil;
        if (!operationError || operationError.code == 0 || operationError.code == 200) {
          hasSuccessfulResult = YES;
          break;
        }
      }
      if (!error && hasSuccessfulResult) self.selectedCustomGroupNeedsReload = YES;
      if (completion) completion(safeResults, error);
    });
  }];
}

- (void)removeConversationIds:(NSArray<NSString *> *)ids fromGroup:(NEConversationGroupItem *)group completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *, NSError *))completion {
  if (![self syncEnabledState]) { if (completion) completion(nil, [self featureDisabledError]); return; }
  NSArray *safe = [self safeStringArray:ids];
  [[ConversationGroupRepo shared] removeConversationsFromGroup:group.groupId conversationIds:safe :^(NSArray<V2NIMConversationOperationResult *> *results, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSArray *safeResults = [results isKindOfClass:[NSArray class]] ? results : nil;
      BOOL hasSuccessfulResult = NO;
      for (id value in safeResults) {
        if (![value isKindOfClass:[V2NIMConversationOperationResult class]]) continue;
        V2NIMConversationOperationResult *result = value;
        V2NIMError *operationError = [result.error isKindOfClass:[V2NIMError class]] ? result.error : nil;
        if (!operationError || operationError.code == 0 || operationError.code == 200) {
          hasSuccessfulResult = YES;
          break;
        }
      }
      if (!error && hasSuccessfulResult) self.selectedCustomGroupNeedsReload = YES;
      if (completion) completion(safeResults, error);
    });
  }];
}

- (NSArray<NSString *> *)safeStringArray:(NSArray *)values {
  NSMutableArray *safe = [NSMutableArray array];
  for (id value in values ?: @[]) if ([value isKindOfClass:[NSString class]] && [value length] > 0) [safe addObject:value];
  return safe;
}

- (void)loadConversationsForGroup:(NEConversationGroupItem *)group
                       completion:(void (^)(NSArray<NEConversationListModel *> *, NSError *))completion {
  if (![self syncEnabledState]) { if (completion) completion(@[], nil); return; }
  if (group.kind != NEConversationGroupKindCustom || group.groupId.length == 0) {
    if (completion) completion(@[], nil);
    return;
  }
  NSMutableArray<NEConversationListModel *> *models = [NSMutableArray array];
  NSMutableSet<NSString *> *ids = [NSMutableSet set];
  [self loadConversationsForGroupId:group.groupId offset:0 models:models ids:ids completion:completion];
}

- (void)loadConversationsForGroup:(NEConversationGroupItem *)group
                           offset:(int64_t)offset
                            limit:(NSInteger)limit
                       completion:(void (^)(NSArray<NEConversationListModel *> *, int64_t, BOOL, NSError *))completion {
  if (![self syncEnabledState]) {
    if (completion) completion(@[], offset, YES, nil);
    return;
  }
  if (group.kind != NEConversationGroupKindCustom || group.groupId.length == 0) {
    if (completion) completion(@[], offset, YES, nil);
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[ConversationGroupRepo shared] getConversationPageByGroupId:group.groupId
                                                         offset:offset
                                                          limit:limit
                                                     completion:^(NEConversationGroupPageResult *page, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      if (!self.isEnabled) {
        if (completion) completion(@[], offset, YES, nil);
        return;
      }

      NSMutableArray<NEConversationListModel *> *models = [NSMutableArray array];
      if ([page isKindOfClass:[NEConversationGroupPageResult class]]) {
        for (id value in page.conversations ?: @[]) {
          if (![value isKindOfClass:[V2NIMConversation class]]) continue;
          [models addObject:[NEConversationListModel modelWithCloudConversation:value]];
        }
      }
      int64_t nextOffset = [page isKindOfClass:[NEConversationGroupPageResult class]] ? page.offset : offset;
      BOOL finished = [page isKindOfClass:[NEConversationGroupPageResult class]] ? page.finished : YES;
      if (completion) completion(models, nextOffset, finished, error);
    });
  }];
}

- (void)loadAllConversationIdsForGroup:(NEConversationGroupItem *)group
                            completion:(void (^)(NSSet<NSString *> *, NSError *))completion {
  if (![self syncEnabledState]) {
    if (completion) completion([NSSet set], nil);
    return;
  }
  if (group.kind != NEConversationGroupKindCustom || group.groupId.length == 0) {
    if (completion) completion([NSSet set], nil);
    return;
  }
  [self loadAllConversationIdsForGroupId:group.groupId
                                  offset:0
                                     ids:[NSMutableSet set]
                              completion:completion];
}

- (void)loadAllConversationIdsForGroupId:(NSString *)groupId
                                  offset:(int64_t)offset
                                     ids:(NSMutableSet<NSString *> *)ids
                              completion:(void (^)(NSSet<NSString *> *, NSError *))completion {
  __weak typeof(self) weakSelf = self;
  [[ConversationGroupRepo shared] getConversationPageByGroupId:groupId
                                                         offset:offset
                                                          limit:100
                                                     completion:^(NEConversationGroupPageResult *page, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      if (!self.isEnabled) {
        if (completion) completion([ids copy], nil);
        return;
      }
      if (error) {
        if (completion) completion(nil, error);
        return;
      }
      if (![page isKindOfClass:[NEConversationGroupPageResult class]]) {
        if (completion) completion([ids copy], nil);
        return;
      }
      for (id value in page.conversations ?: @[]) {
        if (![value isKindOfClass:[V2NIMConversation class]]) continue;
        V2NIMConversation *conversation = value;
        if (conversation.conversationId.length > 0) [ids addObject:conversation.conversationId];
      }
      if (!page.finished && page.offset != offset) {
        [self loadAllConversationIdsForGroupId:groupId
                                        offset:page.offset
                                           ids:ids
                                    completion:completion];
      } else if (completion) {
        completion([ids copy], nil);
      }
    });
  }];
}

- (void)loadConversationsForGroupId:(NSString *)groupId
                             offset:(int64_t)offset
                             models:(NSMutableArray<NEConversationListModel *> *)models
                                ids:(NSMutableSet<NSString *> *)ids
                         completion:(void (^)(NSArray<NEConversationListModel *> *, NSError *))completion {
  __weak typeof(self) weakSelf = self;
  [[ConversationGroupRepo shared] getConversationPageByGroupId:groupId offset:offset limit:100 completion:^(NEConversationGroupPageResult *page, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || error || ![page isKindOfClass:[NEConversationGroupPageResult class]]) {
        if (completion) completion(models, error);
        return;
      }
      for (id value in page.conversations ?: @[]) {
        if (![value isKindOfClass:[V2NIMConversation class]]) continue;
        V2NIMConversation *conversation = value;
        if (![conversation.conversationId isKindOfClass:[NSString class]] || conversation.conversationId.length == 0 ||
            [ids containsObject:conversation.conversationId]) continue;
        [ids addObject:conversation.conversationId];
        [models addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
      }
      if (!page.finished && page.offset != offset) {
        [self loadConversationsForGroupId:groupId offset:page.offset models:models ids:ids completion:completion];
      } else if (completion) {
        completion(models, nil);
      }
    });
  }];
}

- (NSError *)featureDisabledError {
  return [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                              code:NSFeatureUnsupportedError
                          userInfo:@{
                            NSLocalizedDescriptionKey: NEGroupManagerText(@"failed_operation")
                          }];
}

- (void)insertNewVisibleGroup:(V2NIMConversationGroup *)group {
  if (group.groupId.length == 0) return;

  NEConversationGroupItem *item = [[NEConversationGroupItem alloc] init];
  item.kind = NEConversationGroupKindCustom;
  item.groupId = group.groupId;
  item.name = NEConversationGroupResolvedName(group.name, group.groupId);
  item.sdkGroup = group;
  item.hidden = NO;

  NSMutableArray<NEConversationGroupItem *> *visible = [self.visibleGroups mutableCopy] ?: [NSMutableArray array];
  NSMutableArray<NEConversationGroupItem *> *hidden = [self.hiddenGroups mutableCopy] ?: [NSMutableArray array];
  NSIndexSet *visibleIndexes = [visible indexesOfObjectsPassingTest:^BOOL(NEConversationGroupItem *candidate, NSUInteger idx, BOOL *stop) {
    return [candidate.groupId isEqualToString:group.groupId];
  }];
  NSIndexSet *hiddenIndexes = [hidden indexesOfObjectsPassingTest:^BOOL(NEConversationGroupItem *candidate, NSUInteger idx, BOOL *stop) {
    return [candidate.groupId isEqualToString:group.groupId];
  }];
  [visible removeObjectsAtIndexes:visibleIndexes];
  [hidden removeObjectsAtIndexes:hiddenIndexes];
  [visible addObject:item];
  [visible addObjectsFromArray:hidden];
  self.groups = visible;
  [self.hiddenOrder removeObject:group.groupId];
  [self saveConfig];
}

- (void)removeGroup:(NSString *)groupId {
  if (groupId.length == 0) return;
  [[ConversationGroupRepo shared] unsubscribeUnreadCountByFilter:[self unreadFilterForGroupId:groupId]];

  NSMutableArray<NEConversationGroupItem *> *next = [self.groups mutableCopy] ?: [NSMutableArray array];
  NSIndexSet *indexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationGroupItem *item, NSUInteger idx, BOOL *stop) {
    return [item.groupId isEqualToString:groupId];
  }];
  if (indexes.count == 0) return;
  [next removeObjectsAtIndexes:indexes];
  self.groups = next;
  [self.hiddenOrder removeObject:groupId];

  if ([self.selectedGroup.groupId isEqualToString:groupId]) {
    self.selectedGroup = self.visibleGroups.firstObject ?: self.groups.firstObject;
    self.customConversations = @[];
    self.selectedOffset = 0;
    self.selectedGroupFinished = YES;
  }
  [self saveConfig];
  [self syncUnreadSubscriptions];
  [self.delegate conversationGroupManagerDidReload];
  [self.delegate conversationGroupManagerSelectionDidChange];
}

#pragma mark - NEConversationGroupListener
- (void)onConversationGroupCreated:(V2NIMConversationGroup *)group {
  if (self.isEnabled && [group isKindOfClass:[V2NIMConversationGroup class]]) [self loadGroups:nil];
}

- (void)onConversationGroupDeleted:(NSString *)groupId {
  if (!self.isEnabled || ![groupId isKindOfClass:[NSString class]]) return;
  [self removeGroup:groupId];
}

- (void)onConversationGroupChanged:(V2NIMConversationGroup *)group {
  if (!self.isEnabled || ![group isKindOfClass:[V2NIMConversationGroup class]] || group.groupId.length == 0) return;
  NEConversationGroupItem *found = [self groupForId:group.groupId];
  if (!found) {
    [self loadGroups:nil];
    return;
  }
  found.name = NEConversationGroupResolvedName(group.name, group.groupId);
  found.sdkGroup = group;
  [self.delegate conversationGroupManagerDidReload];
  [self refreshUnreadCounts];
  if (found.kind == NEConversationGroupKindCustom && [self.selectedGroup.groupId isEqualToString:group.groupId]) {
    self.selectedCustomGroupNeedsReload = YES;
    [self reloadSelectedCustomGroup];
  }
}

- (void)onConversationsAddedToGroup:(NSString *)groupId conversations:(NSArray<V2NIMConversation *> *)conversations {
  if (!self.isEnabled) return;
  if (self.selectedGroup.kind == NEConversationGroupKindCustom && [groupId isEqualToString:self.selectedGroup.groupId]) {
    self.selectedCustomGroupNeedsReload = YES;
    [self reloadSelectedCustomGroup];
  }
  [self refreshUnreadCounts];
}

- (void)onConversationsRemovedFromGroup:(NSString *)groupId conversationIds:(NSArray<NSString *> *)conversationIds {
  if (!self.isEnabled) return;
  if (self.selectedGroup.kind == NEConversationGroupKindCustom && [groupId isEqualToString:self.selectedGroup.groupId]) {
    self.selectedCustomGroupNeedsReload = YES;
    [self reloadSelectedCustomGroup];
  }
  [self refreshUnreadCounts];
}

#pragma mark - NEConversationListener

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  if (!self.isEnabled) return;
  if (self.selectedGroup.kind == NEConversationGroupKindUnread) {
    NSMutableArray *next = [self.unreadConversations mutableCopy] ?: [NSMutableArray array];
    NSMutableDictionary<NSString *, NEConversationListModel *> *byId = [NSMutableDictionary dictionary];
    for (NEConversationListModel *model in next) if (model.conversationId.length > 0) byId[model.conversationId] = model;
    BOOL changed = NO;
    for (V2NIMConversation *conversation in conversations) {
      NEConversationListModel *model = byId[conversation.conversationId];
      BOOL shouldDisplay = conversation.conversationId.length > 0 && conversation.unreadCount > 0 && !conversation.mute;
      if (shouldDisplay) {
        if (model) [model updateWithCloudConversation:conversation];
        else [next addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
        changed = YES;
      } else if (model) {
        [next removeObject:model];
        changed = YES;
      }
    }
    if (changed) {
      [next sortUsingComparator:^NSComparisonResult(NEConversationListModel *left, NEConversationListModel *right) {
        if (left.sortOrder == right.sortOrder) return NSOrderedSame;
        return left.sortOrder > right.sortOrder ? NSOrderedAscending : NSOrderedDescending;
      }];
      self.unreadConversations = next;
      [self.delegate conversationGroupManagerSelectionDidChange];
    } else if (self.unreadConversations.count == 0 && !self.selectedUnreadFinished) {
      [self loadMoreSelectedUnreadGroup:nil];
    }
    return;
  }

  if (self.selectedGroup.kind != NEConversationGroupKindCustom || self.selectedGroup.groupId.length == 0) return;
  NSMutableArray *next = [self.customConversations mutableCopy] ?: [NSMutableArray array];
  NSMutableDictionary<NSString *, NEConversationListModel *> *byId = [NSMutableDictionary dictionary];
  for (NEConversationListModel *model in next) if (model.conversationId.length > 0) byId[model.conversationId] = model;
  BOOL changed = NO;
  for (V2NIMConversation *conversation in conversations) {
    BOOL inGroup = [conversation.groupIds containsObject:self.selectedGroup.groupId];
    NEConversationListModel *model = byId[conversation.conversationId];
    if (inGroup) {
      if (model) [model updateWithCloudConversation:conversation];
      else [next addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
      changed = YES;
    } else if (model) {
      [next removeObject:model];
      changed = YES;
    }
  }
  if (changed) {
    [next sortUsingComparator:^NSComparisonResult(NEConversationListModel *left, NEConversationListModel *right) {
      if (left.sortOrder == right.sortOrder) return NSOrderedSame;
      return left.sortOrder > right.sortOrder ? NSOrderedAscending : NSOrderedDescending;
    }];
    self.customConversations = next;
    [self.delegate conversationGroupManagerSelectionDidChange];
  }
}

- (void)onConversationUnreadCountCleared:(NSArray<NSString *> *)conversationIds {
  if (!self.isEnabled) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    NSSet *ids = [NSSet setWithArray:conversationIds ?: @[]];
    if (self.selectedGroup.kind == NEConversationGroupKindUnread) {
      NSMutableArray *next = [self.unreadConversations mutableCopy];
      NSUInteger oldCount = next.count;
      for (NEConversationListModel *model in [next copy]) if ([ids containsObject:model.conversationId]) [model markUnreadCountCleared];
      NSIndexSet *zeroIndexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationListModel *model, NSUInteger idx, BOOL *stop) {
        return model.unreadCount == 0;
      }];
      [next removeObjectsAtIndexes:zeroIndexes];
      self.unreadConversations = next;
      if (oldCount != next.count) [self.delegate conversationGroupManagerSelectionDidChange];
    } else if (self.selectedGroup.kind == NEConversationGroupKindCustom) {
      BOOL changed = NO;
      for (NEConversationListModel *model in self.customConversations) {
        if (![ids containsObject:model.conversationId]) continue;
        [model markUnreadCountCleared];
        changed = YES;
      }
      if (changed) [self.delegate conversationGroupManagerSelectionDidChange];
    }
  });
}

- (void)onConversationReadTimeUpdated:(NSString *)conversationId :(NSTimeInterval)readTime {
  if (!self.isEnabled) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.selectedGroup.kind == NEConversationGroupKindUnread) {
      NEConversationListModel *matched = nil;
      for (NEConversationListModel *model in self.unreadConversations) {
        if ([model.conversationId isEqualToString:conversationId]) { matched = model; break; }
      }
      if (!matched) return;
      [matched markUnreadCountClearedThrough:readTime];
      NSMutableArray *next = [self.unreadConversations mutableCopy];
      NSIndexSet *zeroIndexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationListModel *model, NSUInteger idx, BOOL *stop) {
        return model.unreadCount == 0;
      }];
      [next removeObjectsAtIndexes:zeroIndexes];
      self.unreadConversations = next;
    } else if (self.selectedGroup.kind == NEConversationGroupKindCustom) {
      NEConversationListModel *matched = nil;
      for (NEConversationListModel *model in self.customConversations) {
        if ([model.conversationId isEqualToString:conversationId]) { matched = model; break; }
      }
      if (!matched) return;
      [matched markUnreadCountClearedThrough:readTime];
    } else {
      return;
    }
    [self.delegate conversationGroupManagerSelectionDidChange];
  });
}

- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds {
  if (!self.isEnabled) return;
  NSSet *ids = [NSSet setWithArray:conversationIds ?: @[]];
  if (self.selectedGroup.kind == NEConversationGroupKindUnread) {
    NSMutableArray *next = [self.unreadConversations mutableCopy];
    NSUInteger oldCount = next.count;
    NSIndexSet *deletedIndexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationListModel *model, NSUInteger idx, BOOL *stop) {
      return [ids containsObject:model.conversationId];
    }];
    [next removeObjectsAtIndexes:deletedIndexes];
    self.unreadConversations = next;
    if (oldCount != next.count) [self.delegate conversationGroupManagerSelectionDidChange];
  } else if (self.selectedGroup.kind == NEConversationGroupKindCustom) {
    NSMutableArray *next = [self.customConversations mutableCopy];
    NSUInteger oldCount = next.count;
    NSIndexSet *deletedIndexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationListModel *model, NSUInteger idx, BOOL *stop) {
      return [ids containsObject:model.conversationId];
    }];
    [next removeObjectsAtIndexes:deletedIndexes];
    self.customConversations = next;
    if (oldCount != next.count) [self.delegate conversationGroupManagerSelectionDidChange];
  }
}

- (void)onConversationSyncFinished {
  if (self.isEnabled) [self refreshUnreadCounts];
}

- (void)onConversationSyncStarted {
}

- (void)onConversationSyncFailed:(V2NIMError *)error {
  (void)error;
}

- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount {
  (void)unreadCount;
}

- (void)onUnreadCountChangedByFilter:(V2NIMConversationFilter *)filter :(NSInteger)unreadCount {
  if (!self.isEnabled) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *groupId = [filter.conversationGroupId isKindOfClass:[NSString class]] ? filter.conversationGroupId : nil;
    for (NEConversationGroupItem *item in self.groups) {
      if (groupId.length == 0 && (item.kind == NEConversationGroupKindAll || item.kind == NEConversationGroupKindUnread)) {
        item.unreadCount = unreadCount;
      } else if (groupId.length > 0 && item.kind == NEConversationGroupKindCustom && [item.groupId isEqualToString:groupId]) {
        item.unreadCount = unreadCount;
      }
    }
    [self.delegate conversationGroupManagerDidReload];
  });
}

@end
