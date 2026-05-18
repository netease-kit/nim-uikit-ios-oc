// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SettingSectionModel.h"
#import "SettingCellModel.h"

@implementation SettingSectionModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _cellModels = [NSMutableArray array];
  }
  return self;
}

- (void)setCornerType {
  NSUInteger count = self.cellModels.count;
  [self.cellModels enumerateObjectsUsingBlock:^(SettingCellModel * _Nonnull model, NSUInteger idx, __unused BOOL * _Nonnull stop) {
    if (idx == 0) {
      model.cornerType = CornerTypeTopLeft | CornerTypeTopRight;
      if (idx == count - 1) {
        model.cornerType = CornerTypeTopLeft | CornerTypeTopRight | CornerTypeBottomLeft | CornerTypeBottomRight;
      }
    } else if (idx == count - 1) {
      model.cornerType = CornerTypeBottomLeft | CornerTypeBottomRight;
    } else {
      model.cornerType = CornerTypeNone;
    }
  }];
}

@end
