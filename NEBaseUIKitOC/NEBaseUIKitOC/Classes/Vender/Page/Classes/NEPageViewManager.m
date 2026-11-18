// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPageViewManager.h"

typedef NS_ENUM(NSInteger, NEAppearanceState) {
  NEAppearanceStateAppearing = 0,
  NEAppearanceStateDisappearing = 1,
  NEAppearanceStateDisappeared = 2,
  NEAppearanceStateAppeared = 3,
};

@interface NEPageViewManager ()

@property (nonatomic, weak, readwrite, nullable) UIViewController *previousViewController;
@property (nonatomic, weak, readwrite, nullable) UIViewController *selectedViewController;
@property (nonatomic, weak, readwrite, nullable) UIViewController *nextViewController;
@property (nonatomic, assign) NEAppearanceState appearanceState;
@property (nonatomic, assign) BOOL appearanceAnimated;
@property (nonatomic, assign) BOOL didReload;
@property (nonatomic, assign) BOOL didSelect;
@property (nonatomic, assign) NEPageViewDirection initialDirection;

@end

@implementation NEPageViewManager

- (instancetype)init {
  self = [super init];
  if (self) {
    _appearanceState = NEAppearanceStateDisappeared;
    _initialDirection = NEPageViewDirectionNone;
  }
  return self;
}

- (NEPageViewState)state {
  if (!self.previousViewController && !self.nextViewController && !self.selectedViewController) {
    return NEPageViewStateEmpty;
  }
  if (!self.previousViewController && !self.nextViewController) {
    return NEPageViewStateSingle;
  }
  if (!self.nextViewController) {
    return NEPageViewStateLast;
  }
  if (!self.previousViewController) {
    return NEPageViewStateFirst;
  }
  return NEPageViewStateCenter;
}

- (void)selectViewController:(UIViewController *)viewController
                   direction:(NEPageViewDirection)direction
                    animated:(BOOL)animated {
  if (self.state == NEPageViewStateEmpty || animated == NO) {
    [self applySelectedViewController:viewController animated:animated];
    return;
  }

  [self resetState];
  self.didSelect = YES;

  switch (direction) {
    case NEPageViewDirectionForward:
    case NEPageViewDirectionNone:
      if (self.nextViewController) {
        [self.delegate removeViewController:self.nextViewController];
      }
      [self.delegate addViewController:viewController];
      self.nextViewController = viewController;
      [self layoutViewsKeepContentOffset:YES];
      [self.delegate scrollForward];
      break;
    case NEPageViewDirectionReverse:
      if (self.previousViewController) {
        [self.delegate removeViewController:self.previousViewController];
      }
      [self.delegate addViewController:viewController];
      self.previousViewController = viewController;
      [self layoutViewsKeepContentOffset:YES];
      [self.delegate scrollReverse];
      break;
  }
}

- (void)selectNextAnimated:(BOOL)animated {
  if (animated) {
    [self resetState];
    [self.delegate scrollForward];
    return;
  }

  UIViewController *nextViewController = self.nextViewController;
  UIViewController *selectedViewController = self.selectedViewController;
  if (!nextViewController || !selectedViewController) {
    return;
  }

  [self beginAppearanceTransition:NO forViewController:selectedViewController animated:animated];
  [self beginAppearanceTransition:YES forViewController:nextViewController animated:animated];

  UIViewController *newNextViewController = [self.dataSource viewControllerAfter:nextViewController];
  if (self.previousViewController) {
    [self.delegate removeViewController:self.previousViewController];
  }
  if (newNextViewController) {
    [self.delegate addViewController:newNextViewController];
  }

  self.previousViewController = selectedViewController;
  self.selectedViewController = nextViewController;
  self.nextViewController = newNextViewController;

  [self layoutViewsKeepContentOffset:YES];
  [self endAppearanceTransitionForViewController:selectedViewController];
  [self endAppearanceTransitionForViewController:nextViewController];
}

- (void)selectPreviousAnimated:(BOOL)animated {
  if (animated) {
    [self resetState];
    [self.delegate scrollReverse];
    return;
  }

  UIViewController *previousViewController = self.previousViewController;
  UIViewController *selectedViewController = self.selectedViewController;
  if (!previousViewController || !selectedViewController) {
    return;
  }

  [self beginAppearanceTransition:NO forViewController:selectedViewController animated:animated];
  [self beginAppearanceTransition:YES forViewController:previousViewController animated:animated];

  UIViewController *newPreviousViewController = [self.dataSource viewControllerBefore:previousViewController];
  if (self.nextViewController) {
    [self.delegate removeViewController:self.nextViewController];
  }
  if (newPreviousViewController) {
    [self.delegate addViewController:newPreviousViewController];
  }

  self.previousViewController = newPreviousViewController;
  self.selectedViewController = previousViewController;
  self.nextViewController = selectedViewController;

  [self layoutViewsKeepContentOffset:YES];
  [self endAppearanceTransitionForViewController:selectedViewController];
  [self endAppearanceTransitionForViewController:previousViewController];
}

- (void)removeAll {
  UIViewController *oldSelectedViewController = self.selectedViewController;
  if (oldSelectedViewController) {
    [self beginAppearanceTransition:NO forViewController:oldSelectedViewController animated:NO];
    [self.delegate removeViewController:oldSelectedViewController];
  }
  if (self.previousViewController) {
    [self.delegate removeViewController:self.previousViewController];
  }
  if (self.nextViewController) {
    [self.delegate removeViewController:self.nextViewController];
  }
  self.previousViewController = nil;
  self.selectedViewController = nil;
  self.nextViewController = nil;
  [self layoutViewsKeepContentOffset:YES];

  if (oldSelectedViewController) {
    [self endAppearanceTransitionForViewController:oldSelectedViewController];
  }
}

- (void)viewWillLayoutSubviews {
  [self layoutViewsKeepContentOffset:YES];
}

- (void)viewWillAppear:(BOOL)animated {
  self.appearanceState = NEAppearanceStateAppearing;
  self.appearanceAnimated = animated;
  if (self.selectedViewController) {
    [self.delegate beginAppearanceTransitionIsAppearing:YES viewController:self.selectedViewController animated:animated];
  }

  switch (self.state) {
    case NEPageViewStateCenter:
    case NEPageViewStateFirst:
    case NEPageViewStateLast:
    case NEPageViewStateSingle:
      [self layoutViewsKeepContentOffset:YES];
      break;
    case NEPageViewStateEmpty:
      break;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  self.appearanceState = NEAppearanceStateAppeared;
  if (self.selectedViewController) {
    [self.delegate endAppearanceTransitionForViewController:self.selectedViewController];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  self.appearanceState = NEAppearanceStateDisappearing;
  self.appearanceAnimated = animated;
  if (self.selectedViewController) {
    [self.delegate beginAppearanceTransitionIsAppearing:NO viewController:self.selectedViewController animated:animated];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  self.appearanceState = NEAppearanceStateDisappeared;
  if (self.selectedViewController) {
    [self.delegate endAppearanceTransitionForViewController:self.selectedViewController];
  }
}

- (void)willBeginDragging {
  [self resetState];
}

- (void)willEndDragging {
  [self resetState];
}

- (void)viewWillTransitionSize {
  [self layoutViewsKeepContentOffset:NO];
}

- (void)didScrollProgress:(CGFloat)progress {
  NEPageViewDirection currentDirection = progress > 0 ? NEPageViewDirectionForward : (progress < 0 ? NEPageViewDirectionReverse : NEPageViewDirectionNone);
  if (self.initialDirection == NEPageViewDirectionNone) {
    switch (currentDirection) {
      case NEPageViewDirectionForward:
        self.initialDirection = NEPageViewDirectionForward;
        [self onScrollProgress:progress];
        [self willScrollForward];
        break;
      case NEPageViewDirectionReverse:
        self.initialDirection = NEPageViewDirectionReverse;
        [self onScrollProgress:progress];
        [self willScrollReverse];
        break;
      case NEPageViewDirectionNone:
        [self onScrollProgress:progress];
        break;
    }
  } else {
    if (!self.didReload) {
      if (currentDirection == NEPageViewDirectionReverse && self.initialDirection == NEPageViewDirectionForward) {
        self.initialDirection = NEPageViewDirectionReverse;
        [self cancelScrollForward];
        [self onScrollProgress:progress];
        [self willScrollReverse];
      } else if (currentDirection == NEPageViewDirectionForward && self.initialDirection == NEPageViewDirectionReverse) {
        self.initialDirection = NEPageViewDirectionForward;
        [self cancelScrollReverse];
        [self onScrollProgress:progress];
        [self willScrollForward];
      } else {
        [self onScrollProgress:progress];
      }
    } else {
      [self onScrollProgress:progress];
    }
  }

  if (!self.didReload) {
    if (progress >= 1) {
      self.didReload = YES;
      [self didScrollForward];
    } else if (progress <= -1) {
      self.didReload = YES;
      [self didScrollReverse];
    } else if (progress == 0) {
      switch (self.initialDirection) {
        case NEPageViewDirectionForward:
          self.didReload = YES;
          [self cancelScrollForward];
          break;
        case NEPageViewDirectionReverse:
          self.didReload = YES;
          [self cancelScrollReverse];
          break;
        case NEPageViewDirectionNone:
          break;
      }
    }
  }
}

- (void)applySelectedViewController:(UIViewController *)viewController animated:(BOOL)animated {
  UIViewController *oldSelectedViewController = self.selectedViewController;
  UIViewController *newPreviousViewController = [self.dataSource viewControllerBefore:viewController];
  UIViewController *newNextViewController = [self.dataSource viewControllerAfter:viewController];

  // 首次布局 / 重复选中当前页时 oldSelected == viewController，若仍发送 willDisappear，
  // 子控制器会把「页面出现」误判为「页面离开」（例如验证消息页会立即把消息标记已读）。
  if (oldSelectedViewController && oldSelectedViewController != viewController) {
    [self beginAppearanceTransition:NO forViewController:oldSelectedViewController animated:animated];
  }
  if (viewController != self.selectedViewController) {
    [self beginAppearanceTransition:YES forViewController:viewController animated:animated];
  }

  if (self.previousViewController &&
      self.previousViewController != viewController &&
      self.previousViewController != newPreviousViewController &&
      self.previousViewController != newNextViewController) {
    [self.delegate removeViewController:self.previousViewController];
  }
  if (self.selectedViewController &&
      self.selectedViewController != newPreviousViewController &&
      self.selectedViewController != newNextViewController) {
    [self.delegate removeViewController:self.selectedViewController];
  }
  if (self.nextViewController &&
      self.nextViewController != viewController &&
      self.nextViewController != newPreviousViewController &&
      self.nextViewController != newNextViewController) {
    [self.delegate removeViewController:self.nextViewController];
  }

  if (newPreviousViewController &&
      newPreviousViewController != self.selectedViewController &&
      newPreviousViewController != self.previousViewController &&
      newPreviousViewController != self.nextViewController) {
    [self.delegate addViewController:newPreviousViewController];
  }
  if (viewController != self.nextViewController && viewController != self.previousViewController) {
    [self.delegate addViewController:viewController];
  }
  if (newNextViewController &&
      newNextViewController != self.selectedViewController &&
      newNextViewController != self.previousViewController &&
      newNextViewController != self.nextViewController) {
    [self.delegate addViewController:newNextViewController];
  }

  self.previousViewController = newPreviousViewController;
  self.selectedViewController = viewController;
  self.nextViewController = newNextViewController;

  [self layoutViewsKeepContentOffset:YES];

  if (oldSelectedViewController && oldSelectedViewController != viewController) {
    [self endAppearanceTransitionForViewController:oldSelectedViewController];
  }
  if (viewController != oldSelectedViewController) {
    [self endAppearanceTransitionForViewController:viewController];
  }
}

- (void)resetState {
  if (self.didReload) {
    self.initialDirection = NEPageViewDirectionNone;
  }
  self.didReload = NO;
}

- (void)onScrollProgress:(CGFloat)progress {
  if (self.didReload) {
    switch (self.initialDirection) {
      case NEPageViewDirectionForward:
        if (self.previousViewController && self.selectedViewController) {
          [self.delegate isScrollingFromViewController:self.previousViewController
                                      toViewController:self.selectedViewController
                                              progress:progress];
        }
        break;
      case NEPageViewDirectionReverse:
        if (self.nextViewController && self.selectedViewController) {
          [self.delegate isScrollingFromViewController:self.nextViewController
                                      toViewController:self.selectedViewController
                                              progress:progress];
        }
        break;
      case NEPageViewDirectionNone:
        break;
    }
  } else {
    switch (self.initialDirection) {
      case NEPageViewDirectionForward:
        if (self.selectedViewController) {
          [self.delegate isScrollingFromViewController:self.selectedViewController
                                      toViewController:self.nextViewController
                                              progress:progress];
        }
        break;
      case NEPageViewDirectionReverse:
        if (self.selectedViewController) {
          [self.delegate isScrollingFromViewController:self.selectedViewController
                                      toViewController:self.previousViewController
                                              progress:progress];
        }
        break;
      case NEPageViewDirectionNone:
        break;
    }
  }
}

- (void)cancelScrollForward {
  UIViewController *selectedViewController = self.selectedViewController;
  UIViewController *oldNextViewController = self.nextViewController;
  if (!selectedViewController || !oldNextViewController) {
    return;
  }

  [self beginAppearanceTransition:YES forViewController:selectedViewController animated:YES];
  [self beginAppearanceTransition:NO forViewController:oldNextViewController animated:YES];

  if (self.didSelect) {
    UIViewController *newNextViewController = [self.dataSource viewControllerAfter:selectedViewController];
    [self.delegate removeViewController:oldNextViewController];
    if (newNextViewController) {
      [self.delegate addViewController:newNextViewController];
    }
    self.nextViewController = newNextViewController;
    self.didSelect = NO;
    [self layoutViewsKeepContentOffset:YES];
  }

  [self endAppearanceTransitionForViewController:selectedViewController];
  [self endAppearanceTransitionForViewController:oldNextViewController];
  [self.delegate didFinishScrollingFromViewController:selectedViewController
                                     toViewController:oldNextViewController
                               transitionSuccessful:NO];
}

- (void)cancelScrollReverse {
  UIViewController *selectedViewController = self.selectedViewController;
  UIViewController *oldPreviousViewController = self.previousViewController;
  if (!selectedViewController || !oldPreviousViewController) {
    return;
  }

  [self beginAppearanceTransition:YES forViewController:selectedViewController animated:YES];
  [self beginAppearanceTransition:NO forViewController:oldPreviousViewController animated:YES];

  if (self.didSelect) {
    UIViewController *newPreviousViewController = [self.dataSource viewControllerBefore:selectedViewController];
    [self.delegate removeViewController:oldPreviousViewController];
    if (newPreviousViewController) {
      [self.delegate addViewController:newPreviousViewController];
    }
    self.previousViewController = newPreviousViewController;
    self.didSelect = NO;
    [self layoutViewsKeepContentOffset:YES];
  }

  [self endAppearanceTransitionForViewController:selectedViewController];
  [self endAppearanceTransitionForViewController:oldPreviousViewController];
  [self.delegate didFinishScrollingFromViewController:selectedViewController
                                     toViewController:oldPreviousViewController
                               transitionSuccessful:NO];
}

- (void)willScrollForward {
  if (self.selectedViewController && self.nextViewController) {
    [self.delegate willScrollFromViewController:self.selectedViewController toViewController:self.nextViewController];
    [self beginAppearanceTransition:YES forViewController:self.nextViewController animated:YES];
    [self beginAppearanceTransition:NO forViewController:self.selectedViewController animated:YES];
  }
}

- (void)willScrollReverse {
  if (self.selectedViewController && self.previousViewController) {
    [self.delegate willScrollFromViewController:self.selectedViewController toViewController:self.previousViewController];
    [self beginAppearanceTransition:YES forViewController:self.previousViewController animated:YES];
    [self beginAppearanceTransition:NO forViewController:self.selectedViewController animated:YES];
  }
}

- (void)didScrollForward {
  UIViewController *oldSelectedViewController = self.selectedViewController;
  UIViewController *oldNextViewController = self.nextViewController;
  if (!oldSelectedViewController || !oldNextViewController) {
    return;
  }

  [self.delegate didFinishScrollingFromViewController:oldSelectedViewController
                                     toViewController:oldNextViewController
                               transitionSuccessful:YES];

  UIViewController *newNextViewController = [self.dataSource viewControllerAfter:oldNextViewController];
  if (self.previousViewController && self.previousViewController != newNextViewController) {
    [self.delegate removeViewController:self.previousViewController];
  }
  if (newNextViewController && newNextViewController != self.previousViewController) {
    [self.delegate addViewController:newNextViewController];
  }

  if (self.didSelect) {
    UIViewController *newPreviousViewController = [self.dataSource viewControllerBefore:oldNextViewController];
    if (self.selectedViewController) {
      [self.delegate removeViewController:self.selectedViewController];
    }
    if (newPreviousViewController) {
      [self.delegate addViewController:newPreviousViewController];
    }
    self.previousViewController = newPreviousViewController;
    self.didSelect = NO;
  } else {
    self.previousViewController = oldSelectedViewController;
  }

  self.selectedViewController = oldNextViewController;
  self.nextViewController = newNextViewController;
  [self layoutViewsKeepContentOffset:YES];

  [self endAppearanceTransitionForViewController:oldSelectedViewController];
  [self endAppearanceTransitionForViewController:oldNextViewController];
}

- (void)didScrollReverse {
  UIViewController *oldSelectedViewController = self.selectedViewController;
  UIViewController *oldPreviousViewController = self.previousViewController;
  if (!oldSelectedViewController || !oldPreviousViewController) {
    return;
  }

  [self.delegate didFinishScrollingFromViewController:oldSelectedViewController
                                     toViewController:oldPreviousViewController
                               transitionSuccessful:YES];

  UIViewController *newPreviousViewController = [self.dataSource viewControllerBefore:oldPreviousViewController];
  if (self.nextViewController && self.nextViewController != newPreviousViewController) {
    [self.delegate removeViewController:self.nextViewController];
  }
  if (newPreviousViewController && newPreviousViewController != self.nextViewController) {
    [self.delegate addViewController:newPreviousViewController];
  }

  if (self.didSelect) {
    UIViewController *newNextViewController = [self.dataSource viewControllerAfter:oldPreviousViewController];
    if (self.selectedViewController) {
      [self.delegate removeViewController:self.selectedViewController];
    }
    if (newNextViewController) {
      [self.delegate addViewController:newNextViewController];
    }
    self.nextViewController = newNextViewController;
    self.didSelect = NO;
  } else {
    self.nextViewController = oldSelectedViewController;
  }

  self.previousViewController = newPreviousViewController;
  self.selectedViewController = oldPreviousViewController;
  [self layoutViewsKeepContentOffset:YES];

  [self endAppearanceTransitionForViewController:oldSelectedViewController];
  [self endAppearanceTransitionForViewController:oldPreviousViewController];
}

- (void)layoutViewsKeepContentOffset:(BOOL)keepContentOffset {
  NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
  if (self.previousViewController) {
    [viewControllers addObject:self.previousViewController];
  }
  if (self.selectedViewController) {
    [viewControllers addObject:self.selectedViewController];
  }
  if (self.nextViewController) {
    [viewControllers addObject:self.nextViewController];
  }
  [self.delegate layoutViewsForViewControllers:[viewControllers copy] keepContentOffset:keepContentOffset];
}

- (void)beginAppearanceTransition:(BOOL)isAppearing
                forViewController:(UIViewController *)viewController
                         animated:(BOOL)animated {
  switch (self.appearanceState) {
    case NEAppearanceStateAppeared:
      [self.delegate beginAppearanceTransitionIsAppearing:isAppearing viewController:viewController animated:animated];
      break;
    case NEAppearanceStateAppearing:
      [self.delegate beginAppearanceTransitionIsAppearing:isAppearing viewController:viewController animated:self.appearanceAnimated];
      break;
    case NEAppearanceStateDisappearing:
      [self.delegate beginAppearanceTransitionIsAppearing:NO viewController:viewController animated:self.appearanceAnimated];
      break;
    case NEAppearanceStateDisappeared:
      break;
  }
}

- (void)endAppearanceTransitionForViewController:(UIViewController *)viewController {
  if (self.appearanceState == NEAppearanceStateAppeared) {
    [self.delegate endAppearanceTransitionForViewController:viewController];
  }
}

@end
