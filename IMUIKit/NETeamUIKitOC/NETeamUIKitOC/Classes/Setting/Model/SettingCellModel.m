// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SettingCellModel.h"

@implementation SettingCellModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _type = SettingCellTypeSettingArrowCell;
    _rowHeight = 49.0;
    _titleWidth = 32.0;
    _cornerType = CornerTypeNone;
    _switchOpen = NO;
  }
  return self;
}

@end
