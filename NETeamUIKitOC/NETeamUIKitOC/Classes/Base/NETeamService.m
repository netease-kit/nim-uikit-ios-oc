// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamService.h"
#import "TeamRouter.h"

@implementation NETeamService

+ (instancetype)shared {
  static NETeamService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NETeamService alloc] init];
  });
  return instance;
}

- (void)setupInit:(NSDictionary<NSString *,id> *)params {
  [self registerRouter:params];
}

- (void)registerRouter:(NSDictionary<NSString *,id> *)param {
  NSNumber *isFun = param[@"isFun"];
  if (isFun && [isFun boolValue]) {
    [TeamRouter registerFun];
  } else {
    [TeamRouter register];
  }
}

@end
