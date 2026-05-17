// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEPageViewManagerDelegate <NSObject>

- (void)scrollForward;
- (void)scrollReverse;
- (void)layoutViewsForViewControllers:(NSArray<UIViewController *> *)viewControllers
                    keepContentOffset:(BOOL)keepContentOffset;
- (void)addViewController:(UIViewController *)viewController;
- (void)removeViewController:(UIViewController *)viewController;
- (void)beginAppearanceTransitionIsAppearing:(BOOL)isAppearing
                              viewController:(UIViewController *)viewController
                                    animated:(BOOL)animated;
- (void)endAppearanceTransitionForViewController:(UIViewController *)viewController;
- (void)willScrollFromViewController:(UIViewController *)selectedViewController
                    toViewController:(UIViewController *)destinationViewController;
- (void)isScrollingFromViewController:(UIViewController *)selectedViewController
                     toViewController:(nullable UIViewController *)destinationViewController
                             progress:(CGFloat)progress;
- (void)didFinishScrollingFromViewController:(UIViewController *)selectedViewController
                            toViewController:(UIViewController *)destinationViewController
                      transitionSuccessful:(BOOL)transitionSuccessful;

@end

NS_ASSUME_NONNULL_END
