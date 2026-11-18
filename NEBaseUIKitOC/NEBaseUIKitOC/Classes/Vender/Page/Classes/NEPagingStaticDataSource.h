// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEPagingViewControllerInfiniteDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingStaticDataSource : NSObject <NEPagingViewControllerInfiniteDataSource>

@property (nonatomic, copy, readonly) NSArray<id<NEPagingItem>> *items;
@property (nonatomic, copy, readonly) NSArray<UIViewController *> *viewControllers;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers;
- (id<NEPagingItem>)pagingItemAtIndex:(NSInteger)index;
- (void)reloadItems;

@end

NS_ASSUME_NONNULL_END
