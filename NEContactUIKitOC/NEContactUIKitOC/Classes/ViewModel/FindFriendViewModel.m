// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FindFriendViewModel.h"
#import "ContactConst.h"

#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEChatKit.h>

@implementation FindFriendViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactRepo = [ContactRepo shared];
  }
  return self;
}

- (void)searchFriend:(NSString *)text
          completion:(void (^)(NEUserWithFriend *_Nullable, NSError *_Nullable))completion {
  [self.contactRepo getUserWithFriend:@[text] completion:^(NSArray<NEUserWithFriend *> *_Nullable userFriends, NSError *_Nullable error) {
    completion(userFriends.firstObject, error);
  }];
}

- (void)searchFriend:(NSString *)text
                     :(void (^)(NEUserWithFriend *_Nullable, NSError *_Nullable))completion {
  [self searchFriend:text completion:completion];
}

@end
