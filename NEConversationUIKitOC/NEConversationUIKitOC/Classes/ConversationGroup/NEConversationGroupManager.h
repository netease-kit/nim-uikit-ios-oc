// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit-Swift.h>

@class NEConversationListModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEConversationGroupKind) {
  NEConversationGroupKindAll,
  NEConversationGroupKindAtMe,
  NEConversationGroupKindUnread,
  NEConversationGroupKindCustom,
};

typedef NS_ENUM(NSInteger, NEConversationGroupType) {
  NEConversationGroupTypeAll,
  NEConversationGroupTypeAtMe,
  NEConversationGroupTypeUnread,
  NEConversationGroupTypeCustom,
};

@interface NEConversationGroupModel : NSObject
@property(nonatomic, assign, readonly) NEConversationGroupType type;
@property(nonatomic, copy) NSString *groupId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger unreadCount;
@property(nonatomic, strong, nullable) V2NIMConversationGroup *sdkGroup;
@property(nonatomic, assign, readonly) BOOL canEdit;
@property(nonatomic, assign, readonly) BOOL canHide;
@property(nonatomic, assign, readonly) BOOL canDrag;
@property(nonatomic, copy, readonly) NSString *displayName;
- (instancetype)initWithType:(NEConversationGroupType)type
                     groupId:(NSString *)groupId
                        name:(NSString *)name
                 unreadCount:(NSInteger)unreadCount
                    sdkGroup:(nullable V2NIMConversationGroup *)sdkGroup NS_DESIGNATED_INITIALIZER;
+ (NSString *)allId;
+ (NSString *)atMeId;
+ (NSString *)unreadId;
- (instancetype)init NS_UNAVAILABLE;
@end

/// 旧版 OC 内部模型，保留给兼容入口使用。
@interface NEConversationGroupItem : NEConversationGroupModel
@property(nonatomic, assign) NEConversationGroupKind kind;
@property(nonatomic, assign, getter=isHidden) BOOL hidden;
- (instancetype)init;
@end

@protocol NEConversationGroupManagerDelegate <NSObject>
- (void)conversationGroupManagerDidReload;
- (void)conversationGroupManagerSelectionDidChange;
@end

@interface NEConversationGroupManager : NSObject

@property(nonatomic, weak, nullable) id<NEConversationGroupManagerDelegate> delegate;
@property(nonatomic, copy, readonly) NSArray<NEConversationGroupItem *> *groups;
@property(nonatomic, copy, readonly) NSArray<NEConversationGroupItem *> *visibleGroups;
@property(nonatomic, copy, readonly) NSArray<NEConversationGroupItem *> *hiddenGroups;
@property(nonatomic, strong, readonly, nullable) NEConversationGroupItem *selectedGroup;
@property(nonatomic, copy, readonly) NSArray<NEConversationListModel *> *displayedConversations;
@property(nonatomic, copy, readonly) NSArray<NEConversationListModel *> *allConversations;
/// Whether conversation groups are enabled by both the UIKit configuration and the SDK cloud-conversation option.
@property(nonatomic, assign, readonly, getter=isEnabled) BOOL enabled;
@property(nonatomic, assign, readonly) BOOL selectedGroupFinished;
@property(nonatomic, assign, readonly) BOOL selectedUnreadFinished;
@property(nonatomic, assign, readonly) BOOL selectedCustomGroupNeedsReload;

- (BOOL)syncEnabledState;
- (void)updateAllConversations:(NSArray<NEConversationListModel *> *)conversations;
- (void)refreshVirtualCounts:(NSArray<NEConversationListModel *> *)allData;
- (void)refreshUnreadCounts;
- (void)refreshLocalizedDefaultGroupNames;
- (void)loadGroups:(void (^_Nullable)(NSError *_Nullable error))completion;
- (void)selectGroup:(NEConversationGroupItem *)group;
/// 展开态右列仍在展示的会话在当前分组内保留（传 nil 释放）；返回是否变化。
- (BOOL)setRetainedConversation:(nullable NSString *)conversationId;
- (void)loadMoreSelectedGroup:(void (^_Nullable)(NSError *_Nullable error, BOOL finished))completion;
- (void)loadMoreSelectedUnreadGroup:(void (^_Nullable)(NSError *_Nullable error, BOOL finished))completion;

- (void)createGroup:(NSString *)name completion:(void (^)(V2NIMConversationGroup *_Nullable group, NSError *_Nullable error))completion;
- (void)renameGroup:(NEConversationGroupItem *)group name:(NSString *)name completion:(void (^)(NSError *_Nullable error))completion;
- (void)deleteGroup:(NEConversationGroupItem *)group completion:(void (^)(NSError *_Nullable error))completion;
- (void)setGroup:(NEConversationGroupItem *)group hidden:(BOOL)hidden;
- (void)moveVisibleGroupFromIndex:(NSInteger)source toIndex:(NSInteger)destination;
- (void)addConversationIds:(NSArray<NSString *> *)conversationIds toGroup:(NEConversationGroupItem *)group completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *_Nullable results, NSError *_Nullable error))completion;
- (void)removeConversationIds:(NSArray<NSString *> *)conversationIds fromGroup:(NEConversationGroupItem *)group completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *_Nullable results, NSError *_Nullable error))completion;
- (void)reloadSelectedCustomGroup;
- (void)refreshSelectedCustomGroup:(void (^_Nullable)(void))completion;
- (void)loadConversationsForGroup:(NEConversationGroupItem *)group
                       completion:(void (^)(NSArray<NEConversationListModel *> *conversations, NSError *_Nullable error))completion;
- (void)loadConversationsForGroup:(NEConversationGroupItem *)group
                           offset:(int64_t)offset
                            limit:(NSInteger)limit
                       completion:(void (^)(NSArray<NEConversationListModel *> *conversations,
                                            int64_t nextOffset,
                                            BOOL finished,
                                            NSError *_Nullable error))completion;
- (void)loadAllConversationIdsForGroup:(NEConversationGroupItem *)group
                            completion:(void (^)(NSSet<NSString *> *_Nullable conversationIds,
                                                 NSError *_Nullable error))completion;

- (BOOL)setRetainedConversation:(nullable NSString *)conversationId;

@end

@interface ConversationGroupAddViewModel : NSObject
@property(nonatomic, copy, readonly) NSArray<NEConversationListModel *> *allData;
@property(nonatomic, copy, readonly) NSArray<NEConversationListModel *> *displayData;
@property(nonatomic, copy, readonly) NSSet<NSString *> *selectedIds;
@property(nonatomic, assign) int64_t offset;
@property(nonatomic, assign) BOOL finished;
@property(nonatomic, assign) NSInteger pageSize;
@property(nonatomic, copy, readonly) NSString *groupId;
@property(nonatomic, assign, readonly) NSInteger existingCount;
- (instancetype)initWithGroupId:(NSString *)groupId
                    existingIds:(NSSet<NSString *> *)existingIds NS_DESIGNATED_INITIALIZER;
- (void)loadMore:(void (^)(NSError *_Nullable error, BOOL finished))completion;
- (void)search:(nullable NSString *)text;
- (void)toggle:(NSString *)conversationId;
- (instancetype)init NS_UNAVAILABLE;
@end

@protocol ConversationGroupViewModelDelegate <NSObject>
- (void)conversationGroupDidReload;
- (void)conversationGroupSelectionChanged;
@end

@interface ConversationGroupViewModel : NSObject <NEConversationGroupListener, NEConversationListener>
@property(nonatomic, weak, nullable) id<ConversationGroupViewModelDelegate> delegate;
@property(nonatomic, copy, readonly) NSArray<NEConversationGroupModel *> *commonGroups;
@property(nonatomic, copy, readonly) NSArray<NEConversationGroupModel *> *hiddenGroups;
@property(nonatomic, strong, readonly, nullable) NEConversationGroupModel *selectedGroup;
@property(nonatomic, copy, readonly) NSArray<NEConversationListModel *> *selectedCustomData;
@property(nonatomic, assign, readonly) int64_t selectedCustomOffset;
@property(nonatomic, assign, readonly) BOOL selectedCustomFinished;
@property(nonatomic, assign, readonly) BOOL selectedCustomGroupNeedsReload;
@property(nonatomic, assign, readonly) BOOL isEnabled;
- (instancetype)initWithManager:(NEConversationGroupManager *)manager;
- (void)loadGroups:(void (^_Nullable)(NSError *_Nullable error))completion;
- (void)selectGroup:(NEConversationGroupModel *)group;
- (BOOL)setRetainedConversation:(nullable NSString *)conversationId;
- (NSArray<NEConversationListModel *> *)displayedDataFrom:(NSArray<NEConversationListModel *> *)allData;
- (void)loadMoreSelectedCustomGroup:(void (^_Nullable)(NSError *_Nullable error, BOOL finished))completion;
- (void)loadGroupConversationsWithGroupId:(NSString *)groupId
                                   offset:(int64_t)offset
                                    limit:(NSInteger)limit
                               completion:(void (^)(NSArray<NEConversationListModel *> *models,
                                                    int64_t nextOffset,
                                                    BOOL finished,
                                                    NSError *_Nullable error))completion;
- (void)loadAllGroupConversationIdsWithGroupId:(NSString *)groupId
                                     completion:(void (^)(NSSet<NSString *> *_Nullable ids,
                                                          NSError *_Nullable error))completion;
- (void)createGroupWithName:(NSString *)name
                  completion:(void (^)(V2NIMConversationGroup *_Nullable group,
                                       NSError *_Nullable error))completion;
- (void)updateGroupNameWithGroupId:(NSString *)groupId
                              name:(NSString *)name
                        completion:(void (^)(NSError *_Nullable error))completion;
- (void)deleteGroupWithGroupId:(NSString *)groupId
                     completion:(void (^)(NSError *_Nullable error))completion;
- (void)addConversationsWithGroupId:(NSString *)groupId
                    conversationIds:(NSArray<NSString *> *)conversationIds
                          completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *_Nullable results,
                                               NSError *_Nullable error))completion;
- (void)removeConversationsWithGroupId:(NSString *)groupId
                       conversationIds:(NSArray<NSString *> *)conversationIds
                             completion:(void (^)(NSArray<V2NIMConversationOperationResult *> *_Nullable results,
                                                  NSError *_Nullable error))completion;
- (void)refreshSelectedCustomGroup:(void (^_Nullable)(void))completion;
- (void)moveCommonToHidden:(NEConversationGroupModel *)group;
- (void)moveHiddenToCommon:(NEConversationGroupModel *)group;
- (void)updateCommonOrder:(NSArray<NEConversationGroupModel *> *)groups;
- (NSString *)groupErrorMessage:(nullable NSError *)error;
- (void)refreshVirtualCountsWithAllData:(NSArray<NEConversationListModel *> *)allData;
@end

NS_ASSUME_NONNULL_END
