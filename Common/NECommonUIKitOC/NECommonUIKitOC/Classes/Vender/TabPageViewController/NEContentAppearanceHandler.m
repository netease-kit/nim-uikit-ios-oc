// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContentAppearanceHandler.h"

@interface NEContentsAppearanceHandler ()

@property (nonatomic, strong, nullable) NSNumber *disappearingIndex;

@end

@implementation NEContentsAppearanceHandler

- (nullable UIViewController *)viewControllerAtIndex:(NSInteger)index {
  NSArray *viewControllers = self.contentsDequeueHandler ? self.contentsDequeueHandler() : nil;
  if (index < 0 || index >= (NSInteger)viewControllers.count) {
    return nil;
  }
  id item = viewControllers[index];
  return [item isKindOfClass:UIViewController.class] ? item : nil;
}

- (void)beginDraggingAtIndex:(NSInteger)index {
  UIViewController *viewController = [self viewControllerAtIndex:index];
  if (!viewController) {
    return;
  }

  UIViewController *previousViewController = [self viewControllerAtIndex:self.disappearingIndex.integerValue];
  if (previousViewController) {
    [previousViewController endAppearanceTransition];
  }

  [viewController beginAppearanceTransition:NO animated:NO];
  self.disappearingIndex = @(index);
}

- (void)stopScrollingAtIndex:(NSInteger)index {
  UIViewController *viewController = [self viewControllerAtIndex:index];
  if (!viewController) {
    return;
  }

  UIViewController *previousViewController = [self viewControllerAtIndex:self.disappearingIndex.integerValue];
  if (previousViewController) {
    [previousViewController endAppearanceTransition];
  }

  [viewController beginAppearanceTransition:YES animated:NO];
  [viewController endAppearanceTransition];
  self.disappearingIndex = nil;
}

- (void)callAppearance:(NEContentsAppearance)appearance
              animated:(BOOL)animated
               atIndex:(NSInteger)index {
  UIViewController *viewController = [self viewControllerAtIndex:index];
  if (!viewController) {
    return;
  }

  if (self.disappearingIndex &&
      self.disappearingIndex.integerValue == index) {
    UIViewController *previousViewController = [self viewControllerAtIndex:index];
    [previousViewController endAppearanceTransition];
  }
  self.disappearingIndex = nil;

  switch (appearance) {
    case NEContentsAppearanceViewDidAppear:
    case NEContentsAppearanceViewDidDisappear:
      [viewController endAppearanceTransition];
      break;
    case NEContentsAppearanceViewWillAppear:
      [viewController beginAppearanceTransition:YES animated:animated];
      break;
    case NEContentsAppearanceViewWillDisappear:
      [viewController beginAppearanceTransition:NO animated:animated];
      break;
  }
}

- (void)preReloadAtIndex:(NSInteger)index {
  UIViewController *viewController = [self viewControllerAtIndex:index];
  if (!viewController) {
    return;
  }
  [viewController beginAppearanceTransition:NO animated:NO];
  [viewController endAppearanceTransition];
}

- (void)postReloadAtIndex:(NSInteger)index {
  UIViewController *viewController = [self viewControllerAtIndex:index];
  if (!viewController) {
    return;
  }
  [viewController beginAppearanceTransition:YES animated:NO];
  [viewController endAppearanceTransition];
}

@end
