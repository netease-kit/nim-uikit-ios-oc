// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactService.h"
#import "FunContactRouter.h"
#import "NEBaseContactRouter.h"
#import "NormalContactRouter.h"

@implementation NEContactService

+ (NEContactService *)shared {
  static NEContactService *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEContactService alloc] init];
  });
  return instance;
}

- (void)setupInit:(nullable NSDictionary<NSString *, id> *)params {
  [self registerRouter:params];
}

- (void)registerRouter:(nullable NSDictionary<NSString *, id> *)param {
  NSNumber *isFunNum = param[@"isFun"];
  if (isFunNum && [isFunNum boolValue]) {
    [ContactRouter registerFun];
  } else {
    [ContactRouter registerRouter];
  }
}

@end
