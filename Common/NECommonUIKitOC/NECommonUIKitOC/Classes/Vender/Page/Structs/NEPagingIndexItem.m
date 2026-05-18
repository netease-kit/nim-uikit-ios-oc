// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingIndexItem.h"

@implementation NEPagingIndexItem

- (instancetype)initWithIndex:(NSInteger)index title:(NSString *)title {
  self = [super init];
  if (self) {
    _index = index;
    _title = [title copy] ?: @"";
  }
  return self;
}

- (NSInteger)identifier {
  return self.index ^ (NSInteger)self.title.hash;
}

- (BOOL)isEqualToPagingItem:(id<NEPagingItem>)item {
  if (self == item) {
    return YES;
  }
  if (![item isKindOfClass:[NEPagingIndexItem class]]) {
    return NO;
  }
  NEPagingIndexItem *other = (NEPagingIndexItem *)item;
  return self.index == other.index && [self.title isEqualToString:other.title];
}

- (BOOL)isBeforePagingItem:(id<NEPagingItem>)item {
  if ([item isKindOfClass:[NEPagingIndexItem class]]) {
    return self.index < ((NEPagingIndexItem *)item).index;
  }
  return self.identifier < item.identifier;
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithIndex:self.index title:self.title];
}

- (BOOL)isEqual:(id)object {
  return [object conformsToProtocol:@protocol(NEPagingItem)] &&
         [self isEqualToPagingItem:(id<NEPagingItem>)object];
}

- (NSUInteger)hash {
  return (NSUInteger)self.identifier;
}

@end
