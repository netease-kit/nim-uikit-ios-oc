// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingViewController;
@protocol NEPagingItem;

@protocol NEPagingViewControllerInfiniteDataSource <NSObject>

- (UIViewController *)pagingViewController:(NEPagingViewController *)pagingViewController
                     viewControllerForItem:(id<NEPagingItem>)pagingItem;
- (nullable id<NEPagingItem>)pagingViewController:(NEPagingViewController *)pagingViewController
                                     itemBefore:(id<NEPagingItem>)pagingItem;
- (nullable id<NEPagingItem>)pagingViewController:(NEPagingViewController *)pagingViewController
                                      itemAfter:(id<NEPagingItem>)pagingItem;

@end

NS_ASSUME_NONNULL_END
