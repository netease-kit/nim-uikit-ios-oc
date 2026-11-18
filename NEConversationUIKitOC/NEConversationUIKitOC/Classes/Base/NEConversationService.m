// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationService.h"
#import "ConversationRouter.h"
#import "NEAtMessageManager.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NIMSDK/NIMSDK.h>

@implementation NEConversationService

+ (instancetype)shared {
  static NEConversationService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  return [super init];
}

- (void)setupInit:(NSDictionary<NSString *,id> * _Nullable)params {
  [self registerRouter:params];
}

- (void)registerRouter:(NSDictionary<NSString *,id> * _Nullable)param {
  if ([IMKitConfigCenter shared].enableAtMessage) {
    [NEAtMessageManager setupInstance];
  }
  NSNumber *isFun = param[@"isFun"];
  if (isFun && [isFun boolValue]) {
    [ConversationRouter registerFun];
  } else {
    [ConversationRouter register];
  }
}

@end
