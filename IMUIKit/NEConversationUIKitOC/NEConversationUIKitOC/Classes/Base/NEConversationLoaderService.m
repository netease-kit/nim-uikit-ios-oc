// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationLoaderService.h"
#import "NEConversationService.h"
#import <NEChatKit/ChatKitClient.h>

@interface NEConversationLoaderService ()
@property (nonatomic, assign) BOOL didRegisterService;
@end

@implementation NEConversationLoaderService

+ (NEConversationLoaderService *)shared {
  static NEConversationLoaderService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEConversationLoaderService alloc] init];
  });
  return instance;
}

- (void)setupInit {
  ChatKitClient *client = [ChatKitClient shared];
  if (!self.didRegisterService) {
    [client registerInit:[NEConversationService shared]];
    [client buryDataPoints:@"ConversationUIKitOC" language:@"oc"];
    self.didRegisterService = YES;
  }
}

@end
