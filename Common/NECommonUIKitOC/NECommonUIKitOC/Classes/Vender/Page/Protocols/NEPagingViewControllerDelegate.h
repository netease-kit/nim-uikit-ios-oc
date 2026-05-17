// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingViewController;
@protocol NEPagingItem;

@protocol NEPagingViewControllerDelegate <NSObject>

@optional
- (void)pagingViewController:(NEPagingViewController *)pagingViewController
         isScrollingFromItem:(id<NEPagingItem>)currentPagingItem
                      toItem:(nullable id<NEPagingItem>)upcomingPagingItem
      startingViewController:(UIViewController *)startingViewController
   destinationViewController:(nullable UIViewController *)destinationViewController
                    progress:(CGFloat)progress;

- (void)pagingViewController:(NEPagingViewController *)pagingViewController
            willScrollToItem:(id<NEPagingItem>)pagingItem
      startingViewController:(UIViewController *)startingViewController
   destinationViewController:(UIViewController *)destinationViewController;

- (void)pagingViewController:(NEPagingViewController *)pagingViewController
             didScrollToItem:(id<NEPagingItem>)pagingItem
      startingViewController:(nullable UIViewController *)startingViewController
   destinationViewController:(UIViewController *)destinationViewController
      transitionSuccessful:(BOOL)transitionSuccessful;

- (void)pagingViewController:(NEPagingViewController *)pagingViewController
               didSelectItem:(id<NEPagingItem>)pagingItem;

@end

NS_ASSUME_NONNULL_END
