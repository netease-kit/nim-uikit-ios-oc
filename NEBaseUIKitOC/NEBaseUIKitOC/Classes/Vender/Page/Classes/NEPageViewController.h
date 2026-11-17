// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPageViewControllerDataSource.h"
#import "NEPageViewControllerDelegate.h"
#import "NEPageViewDirection.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;

@interface NEPageViewController : UIViewController

@property (nonatomic, weak, nullable) id<NEPageViewControllerDataSource> dataSource;
@property (nonatomic, weak, nullable) id<NEPageViewControllerDelegate> delegate;
@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly, nullable) UIViewController *beforeViewController;
@property (nonatomic, strong, readonly, nullable) UIViewController *selectedViewController;

- (instancetype)initWithOptions:(nullable NEPagingOptions *)options;
- (void)selectViewController:(UIViewController *)viewController
                   direction:(NEPageViewDirection)direction
                    animated:(BOOL)animated;
- (void)selectNextWithAnimated:(BOOL)animated;
- (void)selectPreviousWithAnimated:(BOOL)animated;
- (void)selectNextAnimated:(BOOL)animated;
- (void)selectPreviousAnimated:(BOOL)animated;
- (void)removeAll;

@end

NS_ASSUME_NONNULL_END
