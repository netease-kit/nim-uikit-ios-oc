// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BlackListViewModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>

@interface BlackListViewModel () <NEContactListener>
@end

@implementation BlackListViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactRepo = [ContactRepo shared];
    _blockList = [NSMutableArray array];
    NSLog(@"ContactKit log");

    [_contactRepo addContactListener:self];
  }
  return self;
}

- (void)dealloc {
  [_contactRepo removeContactListener:self];
}

- (void)getBlackList {
  NSLog(@"ContactKit log");

  NSArray<NSString *> *blockAccountIds = [[NEFriendUserCache shared] getBlocklist];
  if (blockAccountIds) {
    [[NEFriendUserCache shared] loadShowName:blockAccountIds showAlias:YES completion:^(NSArray<NEUserWithFriend *> *_Nullable users) {
      if (users) {
        self.blockList = [users mutableCopy];
      }
      [self.delegate tableViewReload];
    }];
  }
}

- (void)removeFromBlackList:(NSString *)account completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"ContactKit log");

  [self.contactRepo removeBlockList:account completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"ContactKit log");
      completion(error);
    } else {
      [[NEFriendUserCache shared] removeBlockAccount:account];
      completion(nil);
    }
  }];
}

- (void)addBlackList:(NSArray<NEUserWithFriend *> *)users completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"ContactKit log");

  for (NEUserWithFriend *user in users) {
    [self.contactRepo addBlockList:user.user.accountId ?: @"" completion:^(NSError *_Nullable error) {
      if (error) {
        NSLog(@"ContactKit log");
        completion(error);
      } else {
        completion(nil);
      }
    }];
  }
}

#pragma mark - NEContactListener

- (void)onBlockListRemoved:(NSString *)accountId {
  for (NSInteger index = 0; index < (NSInteger)self.blockList.count; index++) {
    NEUserWithFriend *friendUser = self.blockList[index];
    if ([friendUser.user.accountId isEqualToString:accountId]) {
      [self.blockList removeObjectAtIndex:index];
      [self.delegate tableViewReload];
    }
  }
}

- (void)onContactChange:(NEContactChangeType)changeType
                contacts:(NSArray<NEUserWithFriend *> *)contacts {
  for (NEUserWithFriend *contact in contacts) {
    // 添加黑名单
    if (changeType == NEContactChangeTypeAddBlock) {
      BOOL exists = NO;
      for (NEUserWithFriend *existing in self.blockList) {
        if ([existing.user.accountId isEqualToString:contact.user.accountId]) {
          exists = YES;
          break;
        }
      }
      if (!exists) {
        [self.blockList addObject:contact];
        [self.delegate tableViewReload];
      }
    }

    for (NSInteger index = 0; index < (NSInteger)self.blockList.count; index++) {
      NEUserWithFriend *friendUser = self.blockList[index];

      // 用户信息更新
      if (changeType == NEContactChangeTypeUpdate &&
          [friendUser.user.accountId isEqualToString:contact.user.accountId]) {
        self.blockList[index] = contact;
        [self.delegate tableViewReload];
      }

      // 移除黑名单
      if (changeType == NEContactChangeTypeRemoveBlock &&
          [friendUser.user.accountId isEqualToString:contact.user.accountId]) {
        [self.blockList removeObjectAtIndex:index];
        [self.delegate tableViewReload];
      }

      // 删除好友
      if (changeType == NEContactChangeTypeDeleteFriend &&
          [friendUser.user.accountId isEqualToString:contact.user.accountId]) {
        [self.blockList removeObjectAtIndex:index];
        [self.delegate tableViewReload];
      }
    }
  }
}

@end
