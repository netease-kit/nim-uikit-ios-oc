// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamLoader.h"
#import "NETeamLoaderService.h"

@implementation NETeamLoader

+ (instancetype)shareInstance {
  static NETeamLoader *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NETeamLoader alloc] init];
  });
  return instance;
}

+ (void)load {
  NSLog(@"NETeamUIKitOC load");
  [[NETeamLoaderService shared] setupInit];
}

@end
