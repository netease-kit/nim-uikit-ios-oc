// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingContentViewController.h"

#import "NEContentAppearanceHandler.h"
#import "NEPagingKitProxy.h"
#import "UIView+constraints.h"

@interface NEExplicitPaging : NSObject

@property (nonatomic, assign, readonly) BOOL paging;

- (instancetype)initWithOneTimeHandler:(dispatch_block_t)oneTimeHandler;
- (void)start;
- (void)fireOneTimeHandlerIfNeeded;
- (void)stop;

@end

@implementation NEExplicitPaging {
  dispatch_block_t _oneTimeHandler;
}

- (instancetype)initWithOneTimeHandler:(dispatch_block_t)oneTimeHandler {
  self = [super init];
  if (self) {
    _oneTimeHandler = [oneTimeHandler copy];
  }
  return self;
}

- (void)start {
  _paging = YES;
}

- (void)fireOneTimeHandlerIfNeeded {
  if (_oneTimeHandler) {
    _oneTimeHandler();
    _oneTimeHandler = nil;
  }
}

- (void)stop {
  _paging = NO;
}

@end

@interface NEPagingContentViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *cachedViewControllers;
@property (nonatomic, assign) NSInteger leftSidePageIndex;
@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, strong, nullable) NEExplicitPaging *explicitPaging;
@property (nonatomic, strong) id<NEContentsAppearanceHandlerProtocol> appearanceHandler;
@property (nonatomic, strong, readwrite) UIScrollView *scrollView;

@end

@implementation NEPagingContentViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _cachedViewControllers = [NSMutableArray array];
    _appearanceHandler = [[NEContentsAppearanceHandler alloc] init];
    _enabledPreloadContent = YES;
  }
  return self;
}

- (CGFloat)leftSidePagingPercent {
  CGFloat width = CGRectGetWidth(self.scrollView.bounds);
  if (width <= 0) {
    return 0;
  }
  CGFloat rawPagingPercent = fmod(self.scrollView.contentOffset.x, width) / width;
  return rawPagingPercent;
}

- (CGFloat)contentOffsetRatio {
  CGFloat denominator = self.scrollView.contentSize.width - CGRectGetWidth(self.scrollView.bounds);
  if (denominator <= 0) {
    return 0;
  }
  return self.scrollView.contentOffset.x / denominator;
}

- (NSInteger)currentPageIndex {
  return [self calcCurrentPageIndexFromLeftSidePageIndex:self.leftSidePageIndex
                                           pagingPercent:self.leftSidePagingPercent];
}

- (CGFloat)currentPagingPercent {
  return [self calcCurrentPagingPercent:self.leftSidePagingPercent];
}

- (NSInteger)adjucentPageIndex {
  CGFloat percent = [self calcCurrentPagingPercent:self.leftSidePagingPercent];
  return percent < 0 ? self.currentPageIndex - 1 : self.currentPageIndex + 1;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.pagingEnabled = YES;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.scrollView.bounces = NO;
  self.scrollView.backgroundColor = UIColor.clearColor;
  self.scrollView.delegate = self;
  if (@available(iOS 11.0, *)) {
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }

  [self.view addSubview:self.scrollView];
  [self.view constrainToEdges:self.scrollView];
  self.view.backgroundColor = UIColor.clearColor;

  __weak typeof(self) weakSelf = self;
  self.appearanceHandler.contentsDequeueHandler = ^NSArray *{
    return weakSelf.cachedViewControllers;
  };
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.appearanceHandler callAppearance:NEContentsAppearanceViewWillAppear
                                animated:animated
                                 atIndex:self.leftSidePageIndex];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.appearanceHandler callAppearance:NEContentsAppearanceViewDidAppear
                                animated:animated
                                 atIndex:self.leftSidePageIndex];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.appearanceHandler callAppearance:NEContentsAppearanceViewWillDisappear
                                animated:animated
                                 atIndex:self.leftSidePageIndex];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self.appearanceHandler callAppearance:NEContentsAppearanceViewDidDisappear
                                animated:animated
                                 atIndex:self.leftSidePageIndex];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * self.numberOfPages,
                                           CGRectGetHeight(self.scrollView.bounds));
  self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * self.leftSidePageIndex, 0);

  [self.cachedViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj isKindOfClass:UIViewController.class]) {
      UIViewController *viewController = obj;
      CGRect frame = self.scrollView.bounds;
      frame.origin.x = CGRectGetWidth(self.scrollView.bounds) * idx;
      viewController.view.frame = frame;
    }
  }];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [self scrollToPage:self.leftSidePageIndex animated:NO completion:nil];
  } completion:nil];
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

- (void)reloadData {
  [self reloadDataWithPage:nil completion:nil];
}

- (void)reloadDataWithCompletion:(dispatch_block_t)completion {
  [self reloadDataWithPage:nil completion:completion];
}

- (void)reloadDataWithPage:(NSNumber *)page completion:(dispatch_block_t)completion {
  [self removeAll];
  [self.appearanceHandler preReloadAtIndex:self.leftSidePageIndex];
  NSInteger preferredPage = page ? page.integerValue : self.leftSidePageIndex;
  self.leftSidePageIndex = preferredPage;
  [self initialLoadWithPage:preferredPage];

  __weak typeof(self) weakSelf = self;
  [NEPagingKitProxy catchLayoutCompletionWithLayout:^{
    [weakSelf.view setNeedsLayout];
    [weakSelf.view layoutIfNeeded];
  } completion:^(BOOL finished) {
    [weakSelf scrollToPage:preferredPage animated:NO completion:^(BOOL innerFinished) {
      [weakSelf.appearanceHandler postReloadAtIndex:preferredPage];
      if (completion) {
        completion();
      }
    }];
  }];
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated {
  [self scrollToPage:page animated:animated completion:nil];
}

- (void)scrollToPage:(NSInteger)page
            animated:(BOOL)animated
          completion:(NEPagingKitAnimationCompletion)completion {
  [self scrollToPage:page needsCallAppearance:YES animated:animated completion:completion];
}

- (void)scrollToPage:(NSInteger)page
  needsCallAppearance:(BOOL)needsCallAppearance
            animated:(BOOL)animated
          completion:(NEPagingKitAnimationCompletion)completion {
  BOOL isScrollingToAnotherPage = self.leftSidePageIndex != page;
  if (isScrollingToAnotherPage &&
      [self.delegate respondsToSelector:@selector(contentViewController:willBeginPagingAt:animated:)]) {
    [self.delegate contentViewController:self willBeginPagingAt:self.leftSidePageIndex animated:animated];
  }

  if (needsCallAppearance) {
    [self.appearanceHandler beginDraggingAtIndex:self.leftSidePageIndex];
  }

  [self loadPagesIfNeeded:page];
  self.leftSidePageIndex = page;

  if (isScrollingToAnotherPage &&
      [self.delegate respondsToSelector:@selector(contentViewController:willFinishPagingAt:animated:)]) {
    [self.delegate contentViewController:self willFinishPagingAt:self.leftSidePageIndex animated:animated];
  }

  __weak typeof(self) weakSelf = self;
  [self moveToPage:page animated:animated completion:^(BOOL finished) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || !finished) {
      if (completion) {
        completion(NO);
      }
      return;
    }

    if (needsCallAppearance) {
      [strongSelf.appearanceHandler stopScrollingAtIndex:strongSelf.leftSidePageIndex];
    }

    if (isScrollingToAnotherPage &&
        [strongSelf.delegate respondsToSelector:@selector(contentViewController:didFinishPagingAt:animated:)]) {
      [strongSelf.delegate contentViewController:strongSelf didFinishPagingAt:strongSelf.leftSidePageIndex animated:animated];
    }

    if (completion) {
      completion(YES);
    }
  }];
}

- (void)moveToPage:(NSInteger)page
          animated:(BOOL)animated
        completion:(NEPagingKitAnimationCompletion)completion {
  CGFloat offsetX = CGRectGetWidth(self.scrollView.bounds) * page;
  if (animated) {
    [self stopScrolling];
    [NEPagingKitProxy performSystemAnimation:^{
      self.scrollView.contentOffset = CGPointMake(offsetX, 0);
    } completion:completion];
    return;
  }

  [NEPagingKitProxy catchLayoutCompletionWithLayout:^{
    self.scrollView.contentOffset = CGPointMake(offsetX, 0);
  } completion:completion ?: ^(BOOL finished) {
  }];
}

- (void)preloadContentIfNeededWithScrollingPercent:(CGFloat)scrollingPercent {
  if (!self.enabledPreloadContent) {
    return;
  }
  if (scrollingPercent > 0.5) {
    [self loadPagesIfNeeded:self.leftSidePageIndex + 1];
  } else {
    [self loadPagesIfNeeded:self.leftSidePageIndex];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  if (scrollView.isDragging && scrollView.isDecelerating) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  NSInteger leftSidePageIndex = self.leftSidePageIndex;
  self.explicitPaging = [[NEExplicitPaging alloc] initWithOneTimeHandler:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if ([strongSelf.delegate respondsToSelector:@selector(contentViewController:willBeginPagingAt:animated:)]) {
      [strongSelf.delegate contentViewController:strongSelf willBeginPagingAt:leftSidePageIndex animated:NO];
    }
    [strongSelf.explicitPaging start];
    [strongSelf.appearanceHandler beginDraggingAtIndex:leftSidePageIndex];
  }];
  self.leftSidePageIndex = (NSInteger)(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));

  if ([self.delegate respondsToSelector:@selector(contentViewController:willBeginManualScrollOn:)]) {
    [self.delegate contentViewController:self willBeginManualScrollOn:self.leftSidePageIndex];
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (!self.explicitPaging) {
    return;
  }

  [self.explicitPaging fireOneTimeHandlerIfNeeded];
  self.leftSidePageIndex = (NSInteger)(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
  CGFloat normalizedPercent = [self calcCurrentPagingPercent:self.leftSidePagingPercent];
  NSInteger currentIndex = [self calcCurrentPageIndexFromLeftSidePageIndex:self.leftSidePageIndex
                                                             pagingPercent:self.leftSidePagingPercent];
  if ([self.delegate respondsToSelector:@selector(contentViewController:didManualScrollOn:percent:)]) {
    [self.delegate contentViewController:self didManualScrollOn:currentIndex percent:normalizedPercent];
  }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  if (self.explicitPaging.paging &&
      [self.delegate respondsToSelector:@selector(contentViewController:willFinishPagingAt:animated:)]) {
    [self.delegate contentViewController:self willFinishPagingAt:self.currentPageIndex animated:YES];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (CGRectGetMinX(scrollView.bounds) < 0 ||
      CGRectGetMaxX(scrollView.bounds) > scrollView.contentSize.width) {
    return;
  }

  if (self.explicitPaging) {
    self.leftSidePageIndex = (NSInteger)(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
    [self loadPagesIfNeeded:self.leftSidePageIndex];
    if ([self.delegate respondsToSelector:@selector(contentViewController:didEndManualScrollOn:)]) {
      [self.delegate contentViewController:self didEndManualScrollOn:self.leftSidePageIndex];
    }
    if (self.explicitPaging.paging) {
      [self.appearanceHandler stopScrollingAtIndex:self.leftSidePageIndex];
      if ([self.delegate respondsToSelector:@selector(contentViewController:didFinishPagingAt:animated:)]) {
        [self.delegate contentViewController:self didFinishPagingAt:self.leftSidePageIndex animated:YES];
      }
    }
  }
  self.explicitPaging = nil;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (decelerate) {
    return;
  }

  if (self.explicitPaging) {
    self.leftSidePageIndex = (NSInteger)(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
    [self loadPagesIfNeeded:self.leftSidePageIndex];
    if ([self.delegate respondsToSelector:@selector(contentViewController:didEndManualScrollOn:)]) {
      [self.delegate contentViewController:self didEndManualScrollOn:self.leftSidePageIndex];
    }
    if (self.explicitPaging.paging) {
      [self.appearanceHandler stopScrollingAtIndex:self.leftSidePageIndex];
      if ([self.delegate respondsToSelector:@selector(contentViewController:willFinishPagingAt:animated:)]) {
        [self.delegate contentViewController:self willFinishPagingAt:self.leftSidePageIndex animated:NO];
      }
      if ([self.delegate respondsToSelector:@selector(contentViewController:didFinishPagingAt:animated:)]) {
        [self.delegate contentViewController:self didFinishPagingAt:self.leftSidePageIndex animated:NO];
      }
    }
  }
  self.explicitPaging = nil;
}

#pragma mark - Private

- (void)removeAll {
  for (UIViewController *child in self.childViewControllers) {
    [child willMoveToParentViewController:nil];
    [child.view removeFromSuperview];
    [child removeFromParentViewController];
  }
  [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)initialLoadWithPage:(NSInteger)page {
  self.numberOfPages = [self.dataSource numberOfItemsForContentViewController:self];
  self.cachedViewControllers = [NSMutableArray arrayWithCapacity:self.numberOfPages];
  for (NSInteger idx = 0; idx < self.numberOfPages; idx++) {
    [self.cachedViewControllers addObject:NSNull.null];
  }

  [self loadScrollViewWithPage:page - 1];
  [self loadScrollViewWithPage:page];
  [self loadScrollViewWithPage:page + 1];
}

- (void)loadScrollViewWithPage:(NSInteger)page {
  if (page < 0 || page >= self.cachedViewControllers.count) {
    return;
  }

  id cachedItem = self.cachedViewControllers[page];
  if (![cachedItem isKindOfClass:NSNull.class]) {
    return;
  }

  UIViewController *viewController = [self.dataSource contentViewController:self viewControllerAt:page];
  [self addChildViewController:viewController];
  CGRect frame = self.scrollView.bounds;
  frame.origin.x = CGRectGetWidth(self.scrollView.bounds) * page;
  viewController.view.frame = frame;
  [self.scrollView addSubview:viewController.view];
  [viewController didMoveToParentViewController:self];
  self.cachedViewControllers[page] = viewController;
}

- (void)loadPagesIfNeeded:(NSInteger)page {
  NSInteger loadingPage = page;
  [self loadScrollViewWithPage:loadingPage - 1];
  [self loadScrollViewWithPage:loadingPage];
  [self loadScrollViewWithPage:loadingPage + 1];
}

- (void)stopScrolling {
  self.explicitPaging = nil;
  [self.scrollView.layer removeAllAnimations];
  [self.scrollView setContentOffset:self.scrollView.contentOffset animated:NO];
}

- (NSInteger)calcCurrentPageIndexFromLeftSidePageIndex:(NSInteger)leftSidePageIndex
                                         pagingPercent:(CGFloat)pagingPercent {
  BOOL scrollToRightSide = (pagingPercent >= 0.5);
  NSInteger rightSidePageIndex = MIN(MAX((NSInteger)self.cachedViewControllers.count - 1, 0),
                                     leftSidePageIndex + 1);
  return scrollToRightSide ? rightSidePageIndex : leftSidePageIndex;
}

- (CGFloat)calcCurrentPagingPercent:(CGFloat)leftSidePagingPercent {
  if (leftSidePagingPercent >= 0.5) {
    return leftSidePagingPercent - 1.0;
  }
  return leftSidePagingPercent;
}

@end
