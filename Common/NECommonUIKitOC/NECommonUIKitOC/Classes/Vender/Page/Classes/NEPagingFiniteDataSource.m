// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingFiniteDataSource.h"
#import "NEPagingItem.h"

@implementation NEPagingFiniteDataSource

- (instancetype)init {
  self = [super init];
  if (self) {
    _items = @[];
  }
  return self;
}

- (UIViewController *)pagingViewController:(NEPagingViewController *)pagingViewController
                     viewControllerForItem:(id<NEPagingItem>)pagingItem {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    return [item isEqualToPagingItem:pagingItem];
  }];
  NSAssert(index != NSNotFound, @"pagingViewController:viewControllerForItem: PagingItem does not exist");
  UIViewController *viewController = self.viewControllerForIndex ? self.viewControllerForIndex((NSInteger)index) : nil;
  NSAssert(viewController != nil, @"pagingViewController:viewControllerForItem: No view controller exist for PagingItem");
  return viewController;
}

- (id<NEPagingItem>)pagingViewController:(NEPagingViewController *)pagingViewController
                              itemBefore:(id<NEPagingItem>)pagingItem {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    return [item isEqualToPagingItem:pagingItem];
  }];
  if (index == NSNotFound || index == 0) {
    return nil;
  }
  return self.items[index - 1];
}

- (id<NEPagingItem>)pagingViewController:(NEPagingViewController *)pagingViewController
                               itemAfter:(id<NEPagingItem>)pagingItem {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    return [item isEqualToPagingItem:pagingItem];
  }];
  if (index == NSNotFound || index >= self.items.count - 1) {
    return nil;
  }
  return self.items[index + 1];
}

@end
