// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingStaticDataSource.h"
#import "NEPagingIndexItem.h"

@interface NEPagingStaticDataSource ()

@property (nonatomic, copy, readwrite) NSArray<id<NEPagingItem>> *items;
@property (nonatomic, copy) NSArray<UIViewController *> *viewControllers;

@end

@implementation NEPagingStaticDataSource

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers {
  self = [super init];
  if (self) {
    _viewControllers = [viewControllers copy] ?: @[];
    [self reloadItems];
  }
  return self;
}

- (id<NEPagingItem>)pagingItemAtIndex:(NSInteger)index {
  return self.items[index];
}

- (void)reloadItems {
  NSMutableArray<id<NEPagingItem>> *items = [NSMutableArray arrayWithCapacity:self.viewControllers.count];
  [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
    [items addObject:[[NEPagingIndexItem alloc] initWithIndex:(NSInteger)idx title:viewController.title ?: @""]];
  }];
  self.items = [items copy];
}

- (UIViewController *)pagingViewController:(NEPagingViewController *)pagingViewController
                     viewControllerForItem:(id<NEPagingItem>)pagingItem {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    return [item isEqualToPagingItem:pagingItem];
  }];
  NSAssert(index != NSNotFound, @"pagingViewController:viewControllerForItem: PagingItem does not exist");
  return self.viewControllers[index];
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
