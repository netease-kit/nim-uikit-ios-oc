// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactUserViewModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/ContactRepo.h>

@implementation ContactUserViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactRepo = [ContactRepo shared];
  }
  return self;
}

- (void)addFriend:(NSString *)account completion:(void (^)(NSError *_Nullable))completion {
  V2NIMFriendAddParams *params = [[V2NIMFriendAddParams alloc] init];
  params.addMode = V2NIM_FRIEND_MODE_TYPE_APPLAY;
  [self.contactRepo addFriend:account params:params completion:completion];
}

- (void)deleteFriend:(NSString *)account completion:(void (^)(NSError *_Nullable))completion {
  V2NIMFriendDeleteParams *params = [[V2NIMFriendDeleteParams alloc] init];
  params.deleteAlias = YES;
  [self.contactRepo deleteFriend:account params:params completion:completion];
}

- (void)removeBlackList:(NSString *)account completion:(void (^)(NSError *_Nullable))completion {
  [self.contactRepo removeBlockList:account completion:completion];
}

- (void)updateAlias:(NSString *)accountId
              alias:(NSString *)alias
         completion:(void (^)(NSError *_Nullable))completion {
  V2NIMFriendSetParams *params = [[V2NIMFriendSetParams alloc] init];
  params.alias = alias;
  [self.contactRepo setFriendInfo:accountId params:params completion:completion];
}

- (void)getUserInfo:(NSString *)uid
         completion:(void (^)(NEUserWithFriend *_Nullable, NSError *_Nullable))completion {
  [self.contactRepo getUserWithFriend:@[uid] completion:^(NSArray<NEUserWithFriend *> *_Nullable userFriends, NSError *_Nullable error) {
    completion(userFriends.firstObject, error);
  }];
}

@end
