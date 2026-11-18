// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MediaSectionModel.h"

@implementation MediaSectionModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _time = @"";
        _messageModels = [NSMutableArray array];
    }
    return self;
}

@end
