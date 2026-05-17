// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageAtCacheModel.h"

@implementation MessageAtCacheModel

- (instancetype)initWithAtModel:(MessageAtInfoModel *)atModel accid:(NSString *)accid {
  self = [super init];
  if (self) {
    _atModel = atModel;
    _accid = [accid copy];
  }
  return self;
}

@end
