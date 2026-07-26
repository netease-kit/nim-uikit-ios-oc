// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotViewModel.h"
#import "NEAIRobotModel.h"
#import <NEChatKit/AIRepo.h>
#import <NEChatKit/NEAIRobotManager.h>

static NSInteger _AIRobotMaxRobotCount = 10;

@implementation AIRobotViewModel

+ (NSInteger)maxRobotCount {
  return _AIRobotMaxRobotCount;
}

+ (void)setMaxRobotCount:(NSInteger)maxRobotCount {
  _AIRobotMaxRobotCount = maxRobotCount;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _datas = [NSMutableArray array];
    _searchDatas = [NSMutableArray array];
  }
  return self;
}

- (void)getRobots:(void (^)(NSError *_Nullable error))completion {
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
    [weakSelf.datas removeAllObjects];
    [weakSelf.searchDatas removeAllObjects];
    for (V2NIMUserAIBot *bot in [NEAIRobotManager shared].sortedBots) {
      NEAIRobotModel *model = [[NEAIRobotModel alloc] init];
      model.bot = bot;
      [weakSelf.datas addObject:model];
    }

    if (completion) {
      completion(nil);
    }
  }];
}

@end
