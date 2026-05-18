// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingItems.h"
#import "AnyPagingItem.h"

@interface NEPagingItems ()

@property (nonatomic, copy, readwrite) NSArray<id<NEPagingItem>> *items;
@property (nonatomic, assign, readwrite) BOOL hasItemsBefore;
@property (nonatomic, assign, readwrite) BOOL hasItemsAfter;
@property (nonatomic, copy) NSDictionary<NSNumber *, id<NEPagingItem>> *cachedItems;

@end

@implementation NEPagingItems

- (instancetype)initWithItems:(NSArray<id<NEPagingItem>> *)items
               hasItemsBefore:(BOOL)hasItemsBefore
                hasItemsAfter:(BOOL)hasItemsAfter {
  self = [super init];
  if (self) {
    _items = [items copy] ?: @[];
    _hasItemsBefore = hasItemsBefore;
    _hasItemsAfter = hasItemsAfter;
    NSMutableDictionary<NSNumber *, id<NEPagingItem>> *cache = [NSMutableDictionary dictionary];
    for (id<NEPagingItem> item in _items) {
      cache[@(item.identifier)] = item;
    }
    _cachedItems = [cache copy];
  }
  return self;
}

- (nullable NSIndexPath *)indexPathForPagingItem:(id<NEPagingItem>)pagingItem {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> obj, NSUInteger idx, BOOL *stop) {
    return [obj isEqualToPagingItem:pagingItem];
  }];
  if (index == NSNotFound) {
    return nil;
  }
  return [NSIndexPath indexPathForItem:(NSInteger)index inSection:0];
}

- (id<NEPagingItem>)pagingItemForIndexPath:(NSIndexPath *)indexPath {
  return self.items[indexPath.item];
}

- (PagingDirection *)directionFrom:(id<NEPagingItem>)from
                                to:(id<NEPagingItem>)to {
  if ([from isBeforePagingItem:to]) {
    return [PagingDirection forwardWithSibling:[self isSiblingFrom:from to:to]];
  }
  if ([to isBeforePagingItem:from]) {
    return [PagingDirection reverseWithSibling:[self isSiblingFrom:from to:to]];
  }
  return [PagingDirection noneDirection];
}

- (BOOL)containsPagingItem:(id<NEPagingItem>)pagingItem {
  return self.cachedItems[@(pagingItem.identifier)] != nil;
}

- (NSArray<id<NEPagingItem>> *)unionWithItems:(NSArray<id<NEPagingItem>> *)newItems {
  NSMutableOrderedSet<AnyPagingItem *> *set = [NSMutableOrderedSet orderedSet];
  for (id<NEPagingItem> item in self.items) {
    [set addObject:[[AnyPagingItem alloc] initWithBase:item]];
  }
  for (id<NEPagingItem> item in newItems) {
    [set addObject:[[AnyPagingItem alloc] initWithBase:item]];
  }
  NSArray<AnyPagingItem *> *sorted = [[set array] sortedArrayUsingComparator:^NSComparisonResult(AnyPagingItem *lhs, AnyPagingItem *rhs) {
    if ([lhs.base isBeforePagingItem:rhs.base]) {
      return NSOrderedAscending;
    }
    if ([rhs.base isBeforePagingItem:lhs.base]) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  NSMutableArray<id<NEPagingItem>> *items = [NSMutableArray arrayWithCapacity:sorted.count];
  for (AnyPagingItem *item in sorted) {
    [items addObject:item.base];
  }
  return [items copy];
}

- (BOOL)isSiblingFrom:(id<NEPagingItem>)from
                   to:(id<NEPagingItem>)to {
  NSUInteger fromIndex = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> obj, NSUInteger idx, BOOL *stop) {
    return [obj isEqualToPagingItem:from];
  }];
  NSUInteger toIndex = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> obj, NSUInteger idx, BOOL *stop) {
    return [obj isEqualToPagingItem:to];
  }];
  if (fromIndex == NSNotFound || toIndex == NSNotFound) {
    return NO;
  }
  return (fromIndex + 1 == toIndex) || (toIndex + 1 == fromIndex);
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithItems:self.items
                                           hasItemsBefore:self.hasItemsBefore
                                            hasItemsAfter:self.hasItemsAfter];
}

@end
