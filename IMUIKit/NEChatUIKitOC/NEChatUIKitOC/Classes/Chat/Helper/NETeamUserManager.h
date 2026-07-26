// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/NEChatKitOC.h>

@class V2NIMTeam;
@class V2NIMTeamMember;
@class V2NIMUser;
@class NEUserWithFriend;
@class NETeamMemberInfoModel;

NS_ASSUME_NONNULL_BEGIN

/// Team chat cache delegate, includes team info update and team member update
@protocol NETeamChatUserCacheListener <NETeamListener>
@optional
/// Team info updated
- (void)onTeamInfoUpdate:(NSString *)teamId;
/// Team member updated
- (void)onTeamMemberUpdate:(NSString *)accountId;
@end

/// Team chat cache class, caches team member info and non-friend user info
@interface NETeamUserManager : NSObject

@property (class, nonatomic, readonly) NETeamUserManager *shared;

- (void)addListener:(id<NETeamChatUserCacheListener>)listener;
- (void)removeListener:(id<NETeamChatUserCacheListener>)listener;

/// Load cache for team
- (void)loadData:(NSString *)teamId;

/// Refresh current team info and self member info for permission-sensitive UI.
- (void)refreshTeamInfoAndSelfMember:(NSString *)teamId completion:(void (^)(void))completion;

/// Update current team info
- (void)updateTeamInfo:(nullable V2NIMTeam *)team;

/// Update team member info
- (void)updateTeamMemberInfo:(nullable V2NIMTeamMember *)teamMember;
- (void)updateTeamMemberInfo:(nullable V2NIMTeamMember *)teamMember notify:(BOOL)notify;

/// Update non-friend user info (V2NIMUser)
- (void)updateUserInfoWithUser:(nullable V2NIMUser *)user;

/// Update non-friend user info (NEUserWithFriend)
- (void)updateUserInfoWithFriend:(nullable NEUserWithFriend *)userWithFriend;

/// Get cached team info
- (nullable V2NIMTeam *)getTeamInfo;

/// Get cached team member info
- (nullable V2NIMTeamMember *)getTeamMemberInfo:(NSString *)accountId;

/// Check if is current team member
- (BOOL)isCurrentMember:(NSString *)accountId;

/// Check if is team owner
- (BOOL)isOwner:(NSString *)accountId;

/// Get all cached team members
- (nullable NSArray<V2NIMTeamMember *> *)getAllTeamMembers;

/// Get all cached team member models
- (nullable NSArray<NETeamMemberInfoModel *> *)getAllTeamMemberModels;

/// Get cached non-friend user info
- (nullable NEUserWithFriend *)getUserInfo:(NSString *)accountId;

/// Remove team member info cache
- (void)removeTeamMemberInfo:(NSString *)accountId;

/// Remove all team info cache
- (void)removeAllTeamInfo;

/// Get display name for team member: alias > teamNick > nickname > ID
- (NSString *)getShowName:(NSString *)accountId;
- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias;

/// Get team members and user info for given account IDs
- (void)getTeamMembers:(NSArray<NSString *> *)accountIds
                notify:(BOOL)notify
            completion:(void (^)(void))completion;

/// Get all team members
- (void)getAllTeamMembers:(NSString *)teamId
               queryType:(V2NIMTeamMemberRoleQueryType)queryType
              completion:(void (^)(NSArray<NEUserWithFriend *> *))completion;

@end

NS_ASSUME_NONNULL_END
