// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamKitConfigCenter.h"

@implementation TeamKitConfigCenter

+ (instancetype)shared {
  static TeamKitConfigCenter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[TeamKitConfigCenter alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamAgreeMode = V2NIM_TEAM_AGREE_MODE_NO_AUTH;
    _teamJoinMode = V2NIM_TEAM_JOIN_MODE_FREE;
  }
  return self;
}

@end
