// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatLoaderService.h"
#import "NEChatService.h"
#import <NEChatKitOC/ChatKitClient.h>

@interface NEChatLoaderService ()

@property(nonatomic, assign) BOOL didRegisterService;

@end

@implementation NEChatLoaderService

+ (instancetype)shared {
  static NEChatLoaderService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEChatLoaderService alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  return self;
}

- (void)setupInit {
  [self setupInitWithFunUI:NO];
}

- (void)setupInitWithFunUI:(BOOL)isFun {
  ChatKitClient *client = [ChatKitClient shared];
  if (!self.didRegisterService) {
    [client registerInit:[NEChatService shared]];
    self.didRegisterService = YES;
  }
  [client setupInit:isFun];
}

@end
