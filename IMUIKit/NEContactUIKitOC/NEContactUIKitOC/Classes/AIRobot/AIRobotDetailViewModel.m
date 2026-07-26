// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotDetailViewModel.h"
#import <NEChatKit/AIRepo.h>

@implementation AIRobotDetailViewModel

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot {
  self = [super init];
  if (self) {
    _bot = bot;
  }
  return self;
}

- (void)deleteRobot:(void (^)(NSError *_Nullable error))completion {
  NSString *accid = self.bot.accid;
  if (accid.length == 0) {
    if (completion) {
      completion(nil);
    }
    return;
  }

  V2NIMDeleteUserAIBotParams *params = [[V2NIMDeleteUserAIBotParams alloc] init];
  params.accid = accid;
  [[AIRepo shared] deleteUserAIBot:params completion:^(NSError *_Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

- (void)refreshToken:(void (^)(NSString *_Nullable token,
                              NSError *_Nullable error))completion {
  NSString *accid = self.bot.accid;
  if (accid.length == 0) {
    if (completion) {
      completion(nil, nil);
    }
    return;
  }

  V2NIMRefreshUserAIBotTokenParams *params = [[V2NIMRefreshUserAIBotTokenParams alloc] init];
  params.accid = accid;
  __weak typeof(self) weakSelf = self;
  [[AIRepo shared] refreshUserAIBotToken:params completion:^(V2NIMRefreshUserAIBotTokenResult *_Nullable result, NSError *_Nullable error) {
    if (result.token.length > 0) {
      weakSelf.latestToken = result.token;
      if (completion) {
        completion(result.token, nil);
      }
    } else if (completion) {
      completion(nil, error);
    }
  }];
}

@end
