// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatMessageDeletionResult.h"

@interface NEChatMessageDeletionResult ()

@property(nonatomic, copy, readwrite) NSArray<NSNumber *> *deletedIndexes;
@property(nonatomic, copy, readwrite) NSArray<NSNumber *> *reloadedIndexes;

@end


@implementation NEChatMessageDeletionResult

- (instancetype)initWithDeletedIndexes:(NSArray<NSNumber *> *)deletedIndexes
                        reloadedIndexes:(NSArray<NSNumber *> *)reloadedIndexes {
  self = [super init];
  if (self) {
    _deletedIndexes = [deletedIndexes copy];
    _reloadedIndexes = [reloadedIndexes copy];
  }
  return self;
}

@end
