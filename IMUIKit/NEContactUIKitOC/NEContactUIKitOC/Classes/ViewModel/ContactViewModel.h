// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "ContactSection.h"
#import "ContactHeadItem.h"

@class ContactRepo;
@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

@protocol ContactViewModelDelegate <NSObject>
- (void)reloadTableView;
@end

@interface ContactViewModel : NSObject

@property (nonatomic, strong) NSMutableArray<ContactSection *> *contactSections;
@property (nonatomic, strong, nullable) NSArray<NSString *> *indexs;
@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, weak) id<ContactViewModelDelegate> delegate;

/// 在线状态记录，[accountId: 是否在线]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *onlineStatusDic;

@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, copy, nullable) void (^refresh)(void);

- (instancetype)initWithContactHeaders:(nullable NSArray<ContactHeadItem *> *)contactHeaders;

- (void)loadData:(nullable NSSet<NSString *> *)filters
      completion:(void (^)(NSError *_Nullable, NSInteger))completion;

- (void)getContactList:(nullable NSSet<NSString *> *)filters
            completion:(void (^)(NSArray<ContactSection *> *_Nullable, NSError *_Nullable))completion;

- (NSArray<ContactSection *> *)formatData:(nullable NSArray<NEUserWithFriend *> *)friends
                                  filters:(nullable NSSet<NSString *> *)filters;

- (NSArray<ContactSection *> *)getFriendSections;

- (void)getValidationMessage:(nullable void (^)(NSInteger, NSError *_Nullable))completion;

- (nullable ContactSection *)headerSection:(nullable NSArray<ContactHeadItem *> *)headerItem;

- (nullable NSArray<NSString *> *)getIndexs:(nullable NSArray<ContactSection *> *)contactSections;

// NEContactListener
- (void)onContactChange:(NSInteger)changeType
                contacts:(NSArray<NEUserWithFriend *> *)contacts;
- (void)removeFromContacts:(NSString *)accountId;
- (void)onFriendAdded:(V2NIMFriend *)friendInfo;
- (void)onFriendDeleted:(NSString *)accountId
           deletionType:(V2NIMFriendDeletionType)deletionType;
- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application;
- (void)onFriendAddRejected:(V2NIMFriendAddApplication *)rejectionInfo;
- (void)onBlockListAdded:(V2NIMUser *)user;
- (void)onBlockListRemoved:(NSString *)accountId;

// NETeamListener
- (void)onReceive:(V2NIMTeamJoinActionInfo *)joinActionInfo;

// NESubscribeListener
- (void)subscribeOnlineStatus;
- (void)unsubscribeOnlineStatus;
- (void)onUserStatusChanged:(NSArray<V2NIMUserStatus *> *)data;

@end

NS_ASSUME_NONNULL_END
