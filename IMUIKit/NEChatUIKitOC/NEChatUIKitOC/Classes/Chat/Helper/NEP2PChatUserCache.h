// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class NEUserWithFriend;
@class V2NIMUser;

NS_ASSUME_NONNULL_BEGIN

@protocol NEP2PChatUserCacheListener <NSObject>
@optional
/// Non-friend P2P user info cache updated
- (void)onUserInfoUpdate:(NSString *)accountId;
@end

/// Stranger user info cache, only caches non-friend P2P chat users
@interface NEP2PChatUserCache : NSObject

@property (class, nonatomic, readonly) NEP2PChatUserCache *shared;

/// Non-friend cache, cleared when chat page is destroyed
@property (nonatomic, strong) NSMutableDictionary<NSString *, NEUserWithFriend *> *noUserCache;

- (void)addListener:(id<NEP2PChatUserCacheListener>)listener;
- (void)removeListener:(id<NEP2PChatUserCacheListener>)listener;

/// Add/update non-friend user info (V2NIMUser)
- (void)updateUserInfoWithUser:(nullable V2NIMUser *)user;

/// Add/update non-friend user info (NEUserWithFriend)
- (void)updateUserInfoWithFriend:(nullable NEUserWithFriend *)user;

/// Get cached non-friend user info
- (nullable NEUserWithFriend *)getUserInfo:(NSString *)accountId;

/// Remove non-friend user info cache
- (void)removeUserInfo:(NSString *)accountId;

/// Remove all non-friend user info caches
- (void)removeAllUserInfo;

/// Get cached user display name, p2p: alias > nickname > ID
- (NSString *)getShowName:(NSString *)userId;
- (NSString *)getShowName:(NSString *)userId showAlias:(BOOL)showAlias;

@end

NS_ASSUME_NONNULL_END
