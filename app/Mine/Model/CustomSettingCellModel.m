// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomSettingCellModel.h"

@implementation CustomSettingCellModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _placeholder = @"请填写";
    _inputKey = @"";
    self.rowHeight = 100.0;
  }
  return self;
}

@end
