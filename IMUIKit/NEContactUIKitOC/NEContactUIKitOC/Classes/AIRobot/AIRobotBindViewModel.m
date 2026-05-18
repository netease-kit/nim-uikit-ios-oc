// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotBindViewModel.h"
#import <NEChatKitOC/AIRepo.h>
#import <NEChatKitOC/NEAIRobotManager.h>

@implementation AIRobotBindViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _bots = [NSMutableArray array];
  }
  return self;
}

- (void)loadBots:(void (^)(NSError *_Nullable error))completion {
  [self fetchPageWithToken:nil accumulated:@[] completion:completion];
}

- (void)fetchPageWithToken:(nullable NSString *)pageToken
               accumulated:(NSArray<V2NIMUserAIBot *> *)accumulated
                completion:(void (^)(NSError *_Nullable error))completion {
  V2NIMGetUserAIBotListParams *params = [[V2NIMGetUserAIBotListParams alloc] init];
  if (pageToken.length > 0) {
    params.pageToken = pageToken;
  }
  params.limit = 100;

  __weak typeof(self) weakSelf = self;
  [[AIRepo shared] getUserAIBotList:params completion:^(V2NIMGetUserAIBotListResult *_Nullable result, NSError *_Nullable error) {
    if (error) {
      if (completion) {
        completion(error);
      }
      return;
    }

    NSArray<V2NIMUserAIBot *> *merged = [accumulated arrayByAddingObjectsFromArray:result.bots ?: @[]];
    if (result.hasMore && result.nextToken.length > 0) {
      [weakSelf fetchPageWithToken:result.nextToken accumulated:merged completion:completion];
      return;
    }

    [[NEAIRobotManager shared] replaceAllWithBots:merged];
    weakSelf.bots = [[[NEAIRobotManager shared].sortedBots mutableCopy] ?: [NSMutableArray array] mutableCopy];
    if (completion) {
      completion(nil);
    }
  }];
}

- (void)bindBot:(V2NIMUserAIBot *)bot
         qrCode:(NSString *)qrCode
     completion:(void (^)(NSError *_Nullable error))completion {
  [[AIRepo shared] bindUserAIBotWithAccid:bot.accid
                                    token:bot.token ?: @""
                                   qrCode:qrCode
                               completion:^(NSError *_Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

@end
