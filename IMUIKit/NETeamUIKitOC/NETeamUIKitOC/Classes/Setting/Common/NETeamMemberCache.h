// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/IMKitClient.h>

NS_ASSUME_NONNULL_BEGIN

@class NETeamInfoModel;
@class NETeamMemberInfoModel;

__attribute__((deprecated("请改用 `NEChatUIKit` 中的 `NETeamChatUserCacheListener` 协议")))
@protocol NETeamMemberCacheListener <NSObject>
@optional
- (void)memberCacheDidChange;
@end

__attribute__((deprecated("请改用 `NEChatUIKit` 中的 `NETeamUserManager` 类")))
@interface NETeamMemberCache : NSObject <NETeamListener, NEIMKitClientListener, NEContactListener>

@property (class, nonatomic, readonly) NETeamMemberCache *shared;

@property (nonatomic, copy) NSString *currentTeamId;
@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, strong) IMKitClient *client;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NETeamMemberInfoModel *> *cacheDic;
@property (nonatomic, strong, nullable) NSTimer *timer;

- (void)addTeamCacheListener:(id<NETeamMemberCacheListener>)listener;
- (void)removeTeamCacheListener:(id<NETeamMemberCacheListener>)listener;
- (void)appDidEnterBackground;
- (void)appWillResignActive;
- (void)didTapHeader:(NSNotification *)notification;
- (void)setCacheMembers:(NSString *)teamId members:(NSArray<NETeamMemberInfoModel *> *)members;
- (nullable NSArray<NETeamMemberInfoModel *> *)getTeamMemberCache:(NSString *)teamId;
- (BOOL)isCurrentMember:(NSString *)accountId;
- (void)onMemberDidChanged:(NSArray<V2NIMTeamMember *> *)members;
- (void)onMemberDidRemove:(NSArray<V2NIMTeamMember *> *)members;
- (void)onMemberDidAdd:(NSArray<V2NIMTeamMember *> *)members;
- (void)clearCache;
- (void)triggerClearCache;
- (void)trigerTimer;
- (void)endTimer;
- (void)updateFinish;
- (void)getAllTeamMemberInfos:(NSString *)teamId
                    queryType:(V2NIMTeamMemberRoleQueryType)queryType
                   completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;
- (void)getAllTeamMemberWithMaxLimit:(NSString *)teamId
                           nextToken:(nullable NSString *)nextToken
                          memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                           queryType:(V2NIMTeamMemberRoleQueryType)queryType
                          completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion;
- (void)splitMembers:(NSArray<V2NIMTeamMember *> *)members
               model:(NETeamInfoModel *)model
       maxSizeByPage:(NSInteger)maxSizeByPage
          completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;
- (void)fetchTeamMemberUserInfos:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                           model:(NETeamInfoModel *)model
                      completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;

@end

NS_ASSUME_NONNULL_END
