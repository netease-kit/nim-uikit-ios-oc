// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CommonUIConfig.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/NECommonLoader.h>

@implementation CommonUIConfig

+ (CommonUIConfig *)shared {
  static CommonUIConfig *_shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shared = [[CommonUIConfig alloc] init];
  });
  return _shared;
}

- (instancetype)init {
  if (self = [super init]) {
    _backArrowImage = [coreLoader() loadImage:@"back_arrow"];
  }
  return self;
}

@end