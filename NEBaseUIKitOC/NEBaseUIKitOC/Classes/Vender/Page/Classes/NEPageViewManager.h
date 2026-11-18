// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPageViewDirection.h"
#import "NEPageViewState.h"
#import "NEPageViewManagerDataSource.h"
#import "NEPageViewManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPageViewManager : NSObject

@property (nonatomic, weak, nullable) id<NEPageViewManagerDataSource> dataSource;
@property (nonatomic, weak, nullable) id<NEPageViewManagerDelegate> delegate;
@property (nonatomic, weak, readonly, nullable) UIViewController *previousViewController;
@property (nonatomic, weak, readonly, nullable) UIViewController *selectedViewController;
@property (nonatomic, weak, readonly, nullable) UIViewController *nextViewController;
@property (nonatomic, assign, readonly) NEPageViewState state;

- (void)selectViewController:(UIViewController *)viewController
                   direction:(NEPageViewDirection)direction
                    animated:(BOOL)animated;
- (void)selectNextAnimated:(BOOL)animated;
- (void)selectPreviousAnimated:(BOOL)animated;
- (void)removeAll;
- (void)viewWillLayoutSubviews;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)willBeginDragging;
- (void)willEndDragging;
- (void)viewWillTransitionSize;
- (void)didScrollProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
