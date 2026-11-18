// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AnyPagingItem.h"

@implementation AnyPagingItem

- (instancetype)initWithBase:(id<NEPagingItem>)base {
  self = [super init];
  if (self) {
    _base = base;
  }
  return self;
}

- (NSInteger)identifier {
  return self.base.identifier;
}

- (BOOL)isEqualToPagingItem:(id<NEPagingItem>)item {
  return [self.base isEqualToPagingItem:item];
}

- (BOOL)isBeforePagingItem:(id<NEPagingItem>)item {
  return [self.base isBeforePagingItem:item];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithBase:self.base];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[AnyPagingItem class]]) {
    return NO;
  }
  return [self.base isEqualToPagingItem:((AnyPagingItem *)object).base];
}

- (NSUInteger)hash {
  return (NSUInteger)self.base.identifier;
}

@end
