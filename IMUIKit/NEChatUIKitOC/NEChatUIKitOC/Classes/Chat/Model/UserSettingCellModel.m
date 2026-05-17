// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserSettingCellModel.h"

@implementation UserSettingCellModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _rowHeight = 49;
    _cornerType = CornerTypeNone;
    _switchOpen = NO;
    _type = UserSettingTypeSwitchType;
  }
  return self;
}

@end
