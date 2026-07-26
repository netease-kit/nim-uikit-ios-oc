// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactLoader.h"
#import "NEContactLoaderService.h"

@implementation NEContactLoader

+ (instancetype)shareInstance {
  static NEContactLoader *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEContactLoader alloc] init];
  });
  return instance;
}

+ (void)load {
  NSLog(@"NEContactUIKitOC load");
  [[NEContactLoaderService shared] setupInit];
}

@end
