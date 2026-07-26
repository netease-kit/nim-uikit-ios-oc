// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FusionContactSelectedViewModel.h"
#import <NEChatKit/NEChatKitOC.h>
#import "ContactConst.h"
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/NEAIUserManager.h>

@implementation FusionContactSelectedViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _memberDatas = [NSMutableArray array];
    _memberSelectedSet = [NSMutableSet set];
    _contactRepo = [ContactRepo shared];
  }
  return self;
}

- (void)loadMemberDatas:(nullable NSSet<NSString *> *)filters
             completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"ContactKit log");


  // 从缓存中取
  if (![[NEFriendUserCache shared] isEmpty]) {
    NSDictionary<NSString *, NEUserWithFriend *> *friendDict = [[NEFriendUserCache shared] getFriendListNotInBlocklist];
    NSMutableArray<NEUserWithFriend *> *friends = [friendDict.allValues mutableCopy];
    [friends sortUsingComparator:^NSComparisonResult(NEUserWithFriend *model1, NEUserWithFriend *model2) {
      NSTimeInterval time1 = model1.friend.createTime;
      NSTimeInterval time2 = model2.friend.createTime;
      if (time2 > time1) return NSOrderedDescending;
      if (time2 < time1) return NSOrderedAscending;
      return NSOrderedSame;
    }];
    [self.memberDatas removeAllObjects];
    for (NEUserWithFriend *user in friends) {
      NSString *accountId = user.user.accountId;
      if (accountId && filters && [filters containsObject:accountId]) {
        continue;
      }
      NEFusionContactCellModel *model = [[NEFusionContactCellModel alloc] init];
      model.user = user;
      [self.memberDatas addObject:model];
    }
    completion(nil);
    return;
  }
}

- (void)loadAIUserData:(nullable NSSet<NSString *> *)filters {
  NSArray<V2NIMAIUser *> *aiUsers = [[NEAIUserManager shared] getAllAIUsers];
  for (V2NIMAIUser *aiUser in aiUsers) {
    NSString *accountId = aiUser.accountId;
    if (accountId) {
      if (filters && [filters containsObject:accountId]) {
        continue;
      }
      NEFusionContactCellModel *model = [[NEFusionContactCellModel alloc] init];
      model.aiUser = aiUser;
      [self.memberDatas addObject:model];
    }
  }
}

@end
