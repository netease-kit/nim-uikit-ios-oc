// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEP2PChatUserCache.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

@interface NEP2PChatUserCache () <NEContactListener>
@property (nonatomic, strong) NSHashTable<id<NEP2PChatUserCacheListener>> *listeners;
@end

@implementation NEP2PChatUserCache

+ (NEP2PChatUserCache *)shared {
  static NEP2PChatUserCache *_shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shared = [[NEP2PChatUserCache alloc] initPrivate];
  });
  return _shared;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _noUserCache = [NSMutableDictionary dictionary];
    _listeners = [NSHashTable weakObjectsHashTable];
    [[ContactRepo shared] addContactListener:self];
  }
  return self;
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
}

#pragma mark - Listener Management

- (void)addListener:(id<NEP2PChatUserCacheListener>)listener {
  if (listener) {
    [self.listeners addObject:listener];
  }
}

- (void)removeListener:(id<NEP2PChatUserCacheListener>)listener {
  if (listener) {
    [self.listeners removeObject:listener];
  }
}

#pragma mark - Public

- (void)updateUserInfoWithUser:(V2NIMUser *)user {
  NSString *accid = user.accountId;
  if (!accid) return;

  NEUserWithFriend *existing = self.noUserCache[accid];
  if (existing) {
    existing.user = user;
  }

  NSArray<id<NEP2PChatUserCacheListener>> *listenerSnapshot = self.listeners.allObjects;
  for (id<NEP2PChatUserCacheListener> delegate in listenerSnapshot) {
    if ([delegate respondsToSelector:@selector(onUserInfoUpdate:)]) {
      [delegate onUserInfoUpdate:accid];
    }
  }
}

- (void)updateUserInfoWithFriend:(NEUserWithFriend *)user {
  NSString *accid = user.user.accountId;
  if (!accid) return;
  self.noUserCache[accid] = user;
}

- (NEUserWithFriend *)getUserInfo:(NSString *)accountId {
  return self.noUserCache[accountId];
}

- (void)removeUserInfo:(NSString *)accountId {
  if (self.noUserCache[accountId]) {
    [self.noUserCache removeObjectForKey:accountId];
  }
}

- (void)removeAllUserInfo {
  [self.noUserCache removeAllObjects];
}

- (NSString *)getShowName:(NSString *)userId {
  return [self getShowName:userId showAlias:YES];
}

- (NSString *)getShowName:(NSString *)userId showAlias:(BOOL)showAlias {
  NEUserWithFriend *user = [self getUserInfo:userId];
  if (user) {
    return [user showName:showAlias] ?: userId;
  }
  return userId;
}

#pragma mark - NEContactListener

- (void)onUserProfileChanged:(NSArray<V2NIMUser *> *)users {
  for (V2NIMUser *user in users) {
    NSString *accid = user.accountId;
    if (!accid) continue;

    if (!self.noUserCache[accid]) {
      [self updateUserInfoWithUser:user];
    }
  }
}

@end
