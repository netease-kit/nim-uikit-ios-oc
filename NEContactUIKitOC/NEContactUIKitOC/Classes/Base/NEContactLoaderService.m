// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactLoaderService.h"
#import "NEContactService.h"
#import <NEChatKit/ChatKitClient.h>

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
  ChatKitClient *client = [ChatKitClient shared];
  if (!self.didRegisterService) {
    [client registerInit:[NEContactService shared]];
    NSString *version = [ChatKitClient componentVersionForBundle:[NSBundle bundleForClass:self.class]
                                                          fallback:@""];
    [client buryDataPoints:@"ContactUIKitOC" version:version];
    self.didRegisterService = YES;
  }
}

- (void)setupInitWithFunUI:(BOOL)isFun {
  [self setupInit];
  ChatKitClient *client = [ChatKitClient shared];
  [client setupInit:isFun];
}

@end
