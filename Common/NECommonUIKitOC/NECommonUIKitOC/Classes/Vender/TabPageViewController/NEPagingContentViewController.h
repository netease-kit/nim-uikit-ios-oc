// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEPagingKitProxy.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingContentViewController;

@protocol NEPagingContentViewControllerDelegate <NSObject>
@optional

- (void)contentViewController:(NEPagingContentViewController *)viewController
   willBeginManualScrollOn:(NSInteger)index;
- (void)contentViewController:(NEPagingContentViewController *)viewController
           didManualScrollOn:(NSInteger)index
                     percent:(CGFloat)percent;
- (void)contentViewController:(NEPagingContentViewController *)viewController
      didEndManualScrollOn:(NSInteger)index;
- (void)contentViewController:(NEPagingContentViewController *)viewController
          willBeginPagingAt:(NSInteger)index
                    animated:(BOOL)animated;
- (void)contentViewController:(NEPagingContentViewController *)viewController
         willFinishPagingAt:(NSInteger)index
                    animated:(BOOL)animated;
- (void)contentViewController:(NEPagingContentViewController *)viewController
          didFinishPagingAt:(NSInteger)index
                    animated:(BOOL)animated;

@end

@protocol NEPagingContentViewControllerDataSource <NSObject>

- (NSInteger)numberOfItemsForContentViewController:(NEPagingContentViewController *)viewController;
- (UIViewController *)contentViewController:(NEPagingContentViewController *)viewController
                           viewControllerAt:(NSInteger)index;

@end

@interface NEPagingContentViewController : UIViewController

@property (nonatomic, weak, nullable) id<NEPagingContentViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<NEPagingContentViewControllerDataSource> dataSource;
@property (nonatomic, assign) BOOL enabledPreloadContent;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, assign, readonly) CGFloat contentOffsetRatio;
@property (nonatomic, assign, readonly) NSInteger currentPageIndex;
@property (nonatomic, assign, readonly) CGFloat currentPagingPercent;
@property (nonatomic, assign, readonly) NSInteger adjucentPageIndex;

- (void)reloadData;
- (void)reloadDataWithCompletion:(nullable dispatch_block_t)completion;
- (void)reloadDataWithPage:(nullable NSNumber *)page completion:(nullable dispatch_block_t)completion;
- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;
- (void)scrollToPage:(NSInteger)page
            animated:(BOOL)animated
          completion:(nullable NEPagingKitAnimationCompletion)completion;
- (void)preloadContentIfNeededWithScrollingPercent:(CGFloat)scrollingPercent;

@end

NS_ASSUME_NONNULL_END
