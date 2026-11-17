// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIUserViewModel.h"
#import <NEChatKit/AIRepo.h>
#import <NEChatKit/NEAIUserModel.h>

@implementation AIUserViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _datas = [NSMutableArray array];
    _searchDatas = [NSMutableArray array];
  }
  return self;
}

- (void)getAIUsers:(void (^)(NSError *_Nullable error))completion {
  __weak typeof(self) weakSelf = self;
  [[AIRepo shared] getAIUserList:^(NSArray<V2NIMAIUser *> *_Nullable users, NSError *_Nullable error) {
    [weakSelf.datas removeAllObjects];
    [weakSelf.searchDatas removeAllObjects];
    for (V2NIMAIUser *aiUser in users ?: @[]) {
      NEAIUserModel *model = [[NEAIUserModel alloc] init];
      model.aiUser = aiUser;
      [weakSelf.datas addObject:model];
    }
    if (completion) {
      completion(error);
    }
  }];
}

@end
