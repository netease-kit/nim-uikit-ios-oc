// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPageViewController;

@protocol NEPageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(NEPageViewController *)pageViewController
     willStartScrollingFrom:(UIViewController *)startingViewController
       destinationViewController:(UIViewController *)destinationViewController;
- (void)pageViewController:(NEPageViewController *)pageViewController
          isScrollingFrom:(UIViewController *)startingViewController
    destinationViewController:(nullable UIViewController *)destinationViewController
                   progress:(CGFloat)progress;
- (void)pageViewController:(NEPageViewController *)pageViewController
    didFinishScrollingFrom:(UIViewController *)startingViewController
     destinationViewController:(UIViewController *)destinationViewController
       transitionSuccessful:(BOOL)transitionSuccessful;

@end

NS_ASSUME_NONNULL_END
