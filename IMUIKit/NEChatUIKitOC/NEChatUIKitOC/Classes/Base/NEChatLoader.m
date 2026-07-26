// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatLoader.h"
#import "NEChatLoaderService.h"

@implementation NEChatLoader

+ (instancetype)shareInstance {
  static NEChatLoader *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEChatLoader alloc] init];
  });
  return instance;
}

+ (void)load {
  NSLog(@"NEChatUIKitOC load");
  [[NEChatLoaderService shared] setupInit];
}

@end
