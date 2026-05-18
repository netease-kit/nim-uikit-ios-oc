// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingDiff.h"
#import "NEPagingItems.h"
#import "NEPagingItem.h"

@interface NEPagingDiff ()

@property (nonatomic, strong) NEPagingItems *fromItems;
@property (nonatomic, strong) NEPagingItems *toItems;

@end

@implementation NEPagingDiff

- (instancetype)initWithFromItems:(NEPagingItems *)fromItems
                           toItems:(NEPagingItems *)toItems {
  self = [super init];
  if (self) {
    _fromItems = fromItems;
    _toItems = toItems;
  }
  return self;
}

- (NSArray<NSIndexPath *> *)addedIndexPaths {
  NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
  [self.toItems.items enumerateObjectsUsingBlock:^(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    if (![self.fromItems containsPagingItem:item]) {
      [indexPaths addObject:[NSIndexPath indexPathForItem:(NSInteger)idx inSection:0]];
    }
  }];
  return [indexPaths copy];
}

- (NSArray<NSIndexPath *> *)removedIndexPaths {
  NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
  [self.fromItems.items enumerateObjectsUsingBlock:^(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    if (![self.toItems containsPagingItem:item]) {
      [indexPaths addObject:[NSIndexPath indexPathForItem:(NSInteger)idx inSection:0]];
    }
  }];
  return [indexPaths copy];
}

@end
