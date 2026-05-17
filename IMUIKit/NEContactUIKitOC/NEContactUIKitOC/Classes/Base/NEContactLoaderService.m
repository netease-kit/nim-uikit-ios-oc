// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactLoaderService.h"
#import "NEContactService.h"
#import <NEChatKitOC/ChatKitClient.h>

@interface NEContactLoaderService ()

@property(nonatomic, assign) BOOL didRegisterService;

@end

@implementation NEContactLoaderService

+ (NEContactLoaderService *)shared {
  static NEContactLoaderService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEContactLoaderService alloc] init];
  });
  return instance;
}

- (void)setupInit {
  [self setupInitWithFunUI:NO];
}

- (void)setupInitWithFunUI:(BOOL)isFun {
  ChatKitClient *client = [ChatKitClient shared];
  if (!self.didRegisterService) {
    [client registerInit:[NEContactService shared]];
    self.didRegisterService = YES;
  }
  [client setupInit:isFun];
}

@end
