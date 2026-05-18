// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiSelectModel.h"

@implementation MultiSelectModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _isSelected = NO;
    _memberCount = 0;
  }
  return self;
}

@end
