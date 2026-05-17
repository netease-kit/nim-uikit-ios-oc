// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamLoaderService.h"
#import "NETeamService.h"
#import <NEChatKitOC/ChatKitClient.h>

@implementation NETeamLoaderService

+ (instancetype)shared {
  static NETeamLoaderService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NETeamLoaderService alloc] init];
  });
  return instance;
}

- (void)setupInit {
  [[ChatKitClient shared] registerInit:[NETeamService shared]];
  [[ChatKitClient shared] buryDataPoints:@"TeamUIKit"];
}

@end
