// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingViewController;
@protocol NEPagingItem;

@protocol NEPagingViewControllerDataSource <NSObject>

- (NSInteger)numberOfViewControllersInPagingViewController:(NEPagingViewController *)pagingViewController;
- (UIViewController *)pagingViewController:(NEPagingViewController *)pagingViewController
                        viewControllerAtIndex:(NSInteger)index;
- (id<NEPagingItem>)pagingViewController:(NEPagingViewController *)pagingViewController
                            pagingItemAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
