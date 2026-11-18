// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationLoaderService.h"
#import "NEConversationService.h"
#import <NEChatKit/ChatKitClient.h>

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
  [client registerInit:[NEConversationService shared]];
  [client buryDataPoints:@"ConversationUIKit" language:@"oc"];
}

@end
