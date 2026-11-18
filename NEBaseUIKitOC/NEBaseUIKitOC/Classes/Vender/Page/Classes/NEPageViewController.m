// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPageViewController.h"
#import "NEPageViewManager.h"
#import "NEPagingOptions.h"

@interface NEPageViewController () <UIScrollViewDelegate, NEPageViewManagerDataSource, NEPageViewManagerDelegate>

@property (nonatomic, strong, readwrite) UIScrollView *scrollView;
@property (nonatomic, strong) NEPageViewManager *manager;

@end

@implementation NEPageViewController

- (void)commonInitWithOptions:(nullable NEPagingOptions *)options {
  _options = [options copy] ?: [[NEPagingOptions alloc] init];
  _manager = [[NEPageViewManager alloc] init];
  _manager.delegate = self;
  _manager.dataSource = self;
}

- (instancetype)init {
  return [self initWithOptions:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInitWithOptions:nil];
  }
  return self;
}

- (instancetype)initWithOptions:(NEPagingOptions *)options {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    [self commonInitWithOptions:options];
  }
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [self initWithOptions:nil];
}

- (void)setOptions:(NEPagingOptions *)options {
  _options = [options copy] ?: [[NEPagingOptions alloc] init];
  if (!self.isViewLoaded) {
    return;
  }

  switch (_options.contentNavigationOrientation) {
    case NEPagingNavigationOrientationVertical:
      self.scrollView.alwaysBounceHorizontal = NO;
      self.scrollView.alwaysBounceVertical = YES;
      break;
    case NEPagingNavigationOrientationHorizontal:
      self.scrollView.alwaysBounceHorizontal = YES;
      self.scrollView.alwaysBounceVertical = NO;
      break;
  }
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

- (UIViewController *)beforeViewController {
  return self.manager.previousViewController;
}

- (UIViewController *)selectedViewController {
  return self.manager.selectedViewController;
}

- (UIViewController *)afterViewController {
  return self.manager.nextViewController;
}

- (CGFloat)pageSize {
  return self.options.contentNavigationOrientation == NEPagingNavigationOrientationVertical ? CGRectGetHeight(self.view.bounds) : CGRectGetWidth(self.view.bounds);
}

- (CGSize)contentSize {
  NSInteger count = NEPageViewStateCount(self.manager.state);
  if (self.options.contentNavigationOrientation == NEPagingNavigationOrientationHorizontal) {
    return CGSizeMake(count * CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
  }
  return CGSizeMake(CGRectGetWidth(self.view.bounds), count * CGRectGetHeight(self.view.bounds));
}

- (CGFloat)contentOffsetValue {
  return self.options.contentNavigationOrientation == NEPagingNavigationOrientationHorizontal ? self.scrollView.contentOffset.x : self.scrollView.contentOffset.y;
}

- (void)setContentOffsetValue:(CGFloat)contentOffsetValue {
  CGPoint point = self.options.contentNavigationOrientation == NEPagingNavigationOrientationHorizontal ? CGPointMake(contentOffsetValue, 0) : CGPointMake(0, contentOffsetValue);
  self.scrollView.contentOffset = point;
}

- (BOOL)isRightToLeft {
  if (self.options.contentNavigationOrientation == NEPagingNavigationOrientationVertical) {
    return NO;
  }
  return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.pagingEnabled = YES;
  self.scrollView.scrollsToTop = NO;
  self.scrollView.bounces = YES;
  self.scrollView.translatesAutoresizingMaskIntoConstraints = YES;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.delegate = self;
  self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  [self.view addSubview:self.scrollView];
  [self setOptions:self.options];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.scrollView.frame = self.view.bounds;
  [self.manager viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.manager viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.manager viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.manager viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self.manager viewDidDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
    [self.manager viewWillTransitionSize];
  } completion:nil];
}

- (void)selectViewController:(UIViewController *)viewController
                   direction:(NEPageViewDirection)direction
                    animated:(BOOL)animated {
  [self.manager selectViewController:viewController direction:direction animated:animated];
}

- (void)selectNextWithAnimated:(BOOL)animated {
  [self.manager selectNextAnimated:animated];
}

- (void)selectPreviousWithAnimated:(BOOL)animated {
  [self.manager selectPreviousAnimated:animated];
}

- (void)selectNextAnimated:(BOOL)animated {
  [self selectNextWithAnimated:animated];
}

- (void)selectPreviousAnimated:(BOOL)animated {
  [self selectPreviousWithAnimated:animated];
}

- (void)removeAll {
  [self.manager removeAll];
}

- (void)setAnimatedContentOffset:(CGFloat)value {
  CGPoint point = self.options.contentNavigationOrientation == NEPagingNavigationOrientationHorizontal ? CGPointMake(value, 0) : CGPointMake(0, value);
  [self.scrollView setContentOffset:point animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self.manager willBeginDragging];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
  [self.manager willEndDragging];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat distance = self.pageSize;
  if (distance <= 0) {
    return;
  }
  CGFloat contentOffset = self.contentOffsetValue;
  CGFloat progress = 0;
  if (self.isRightToLeft) {
    switch (self.manager.state) {
      case NEPageViewStateLast:
      case NEPageViewStateEmpty:
      case NEPageViewStateSingle:
        progress = -(contentOffset / distance);
        break;
      case NEPageViewStateCenter:
      case NEPageViewStateFirst:
        progress = -((contentOffset - distance) / distance);
        break;
    }
  } else {
    switch (self.manager.state) {
      case NEPageViewStateFirst:
      case NEPageViewStateEmpty:
      case NEPageViewStateSingle:
        progress = contentOffset / distance;
        break;
      case NEPageViewStateCenter:
      case NEPageViewStateLast:
        progress = (contentOffset - distance) / distance;
        break;
    }
  }
  [self.manager didScrollProgress:progress];
}

- (UIViewController *)viewControllerAfter:(UIViewController *)viewController {
  return [self.dataSource pageViewController:self viewControllerAfterViewController:viewController];
}

- (UIViewController *)viewControllerBefore:(UIViewController *)viewController {
  return [self.dataSource pageViewController:self viewControllerBeforeViewController:viewController];
}

- (void)scrollForward {
  if (self.isRightToLeft) {
    switch (self.manager.state) {
      case NEPageViewStateFirst:
      case NEPageViewStateCenter:
        [self setAnimatedContentOffset:0];
        break;
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
      case NEPageViewStateLast:
        break;
    }
  } else {
    switch (self.manager.state) {
      case NEPageViewStateFirst:
        [self setAnimatedContentOffset:self.pageSize];
        break;
      case NEPageViewStateCenter:
        [self setAnimatedContentOffset:self.pageSize * 2];
        break;
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
      case NEPageViewStateLast:
        break;
    }
  }
}

- (void)scrollReverse {
  if (self.isRightToLeft) {
    switch (self.manager.state) {
      case NEPageViewStateLast:
        [self setAnimatedContentOffset:self.pageSize];
        break;
      case NEPageViewStateCenter:
        [self setAnimatedContentOffset:self.pageSize * 2];
        break;
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
      case NEPageViewStateFirst:
        break;
    }
  } else {
    switch (self.manager.state) {
      case NEPageViewStateLast:
      case NEPageViewStateCenter:
        [self setAnimatedContentOffset:0];
        break;
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
      case NEPageViewStateFirst:
        break;
    }
  }
}

- (void)layoutViewsForViewControllers:(NSArray<UIViewController *> *)viewControllers
                    keepContentOffset:(BOOL)keepContentOffset {
  NSArray<UIViewController *> *layoutViewControllers = self.isRightToLeft ? [[viewControllers reverseObjectEnumerator] allObjects] : viewControllers;
  [self.view layoutIfNeeded];
  [layoutViewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
    if (self.options.contentNavigationOrientation == NEPagingNavigationOrientationHorizontal) {
      viewController.view.frame = CGRectMake(idx * CGRectGetWidth(self.scrollView.bounds),
                                             0,
                                             CGRectGetWidth(self.scrollView.bounds),
                                             CGRectGetHeight(self.scrollView.bounds));
    } else {
      viewController.view.frame = CGRectMake(0,
                                             idx * CGRectGetHeight(self.scrollView.bounds),
                                             CGRectGetWidth(self.scrollView.bounds),
                                             CGRectGetHeight(self.scrollView.bounds));
    }
  }];

  CGFloat diff = 0;
  if (keepContentOffset) {
    if (self.contentOffsetValue > self.pageSize * 2) {
      diff = self.contentOffsetValue - self.pageSize * 2;
    } else if (self.contentOffsetValue > self.pageSize && self.contentOffsetValue < self.pageSize * 2) {
      diff = self.contentOffsetValue - self.pageSize;
    } else if (self.contentOffsetValue < self.pageSize && self.contentOffsetValue < 0) {
      diff = self.contentOffsetValue;
    }
  }

  self.scrollView.contentSize = self.contentSize;
  if (self.isRightToLeft) {
    switch (self.manager.state) {
      case NEPageViewStateFirst:
      case NEPageViewStateCenter:
        self.contentOffsetValue = self.pageSize + diff;
        break;
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
      case NEPageViewStateLast:
        self.contentOffsetValue = diff;
        break;
    }
  } else {
    switch (self.manager.state) {
      case NEPageViewStateFirst:
      case NEPageViewStateSingle:
      case NEPageViewStateEmpty:
        self.contentOffsetValue = diff;
        break;
      case NEPageViewStateLast:
      case NEPageViewStateCenter:
        self.contentOffsetValue = self.pageSize + diff;
        break;
    }
  }
}

- (void)addViewController:(UIViewController *)viewController {
  [viewController willMoveToParentViewController:self];
  [self addChildViewController:viewController];
  [self.scrollView addSubview:viewController.view];
  [viewController didMoveToParentViewController:self];
}

- (void)removeViewController:(UIViewController *)viewController {
  [viewController willMoveToParentViewController:nil];
  [viewController.view removeFromSuperview];
  [viewController removeFromParentViewController];
}

- (void)beginAppearanceTransitionIsAppearing:(BOOL)isAppearing
                              viewController:(UIViewController *)viewController
                                    animated:(BOOL)animated {
  [viewController beginAppearanceTransition:isAppearing animated:animated];
}

- (void)endAppearanceTransitionForViewController:(UIViewController *)viewController {
  [viewController endAppearanceTransition];
}

- (void)willScrollFromViewController:(UIViewController *)selectedViewController
                    toViewController:(UIViewController *)destinationViewController {
  [self.delegate pageViewController:self
            willStartScrollingFrom:selectedViewController
         destinationViewController:destinationViewController];
}

- (void)didFinishScrollingFromViewController:(UIViewController *)selectedViewController
                            toViewController:(UIViewController *)destinationViewController
                      transitionSuccessful:(BOOL)transitionSuccessful {
  [self.delegate pageViewController:self
           didFinishScrollingFrom:selectedViewController
        destinationViewController:destinationViewController
          transitionSuccessful:transitionSuccessful];
}

- (void)isScrollingFromViewController:(UIViewController *)selectedViewController
                     toViewController:(UIViewController *)destinationViewController
                             progress:(CGFloat)progress {
  [self.delegate pageViewController:self
                    isScrollingFrom:selectedViewController
          destinationViewController:destinationViewController
                           progress:progress];
}

@end
