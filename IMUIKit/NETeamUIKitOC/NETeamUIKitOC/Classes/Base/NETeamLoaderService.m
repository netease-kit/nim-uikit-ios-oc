// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamLoaderService.h"
#import "NETeamService.h"
#import <NEChatKit/ChatKitClient.h>

@interface NETeamLoaderService ()

@property(nonatomic, assign) BOOL didRegisterService;

@end

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
  ChatKitClient *client = [ChatKitClient shared];
  if (!self.didRegisterService) {
    [client registerInit:[NETeamService shared]];
    [client buryDataPoints:@"TeamUIKitOC" language:@"oc"];
    self.didRegisterService = YES;
  }
}

@end
