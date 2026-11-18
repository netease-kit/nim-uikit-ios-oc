// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageAtInfoModel.h"

@implementation MessageAtInfoModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _start = 0;
    _end = 0;
    _broken = NO;
  }
  return self;
}

@end
