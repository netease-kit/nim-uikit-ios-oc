// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PinMessageFileModel.h"

@implementation PinMessageFileModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _progress = 0;
    _size = 0;
    _state = DownloadStateSuccess;
  }
  return self;
}

@end
