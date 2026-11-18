// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveBottomSheetController.h"

@implementation NEAdaptiveBottomSheetController {
  __weak UIViewController *_columnPresenter;
  __weak UIView *_columnContainerView;
  id _columnGeometryObserver;
}

- (void)embedInColumnWithPresenter:(UIViewController *)presenter container:(UIView *)container {
  _columnPresenter = presenter;
  _columnContainerView = container;
  [self updateColumnFrame];
  __weak typeof(self) weakSelf = self;
  _columnGeometryObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:@"NEAdaptiveGeometryDidChange"
                                                        object:nil
                                                         queue:[NSOperationQueue mainQueue]
                                                    usingBlock:^(NSNotification *note) {
    [weakSelf scheduleColumnRefresh];
  }];
}

- (void)detachFromColumn {
  if (_columnGeometryObserver) {
    [[NSNotificationCenter defaultCenter] removeObserver:_columnGeometryObserver];
    _columnGeometryObserver = nil;
  }
  _columnPresenter = nil;
  _columnContainerView = nil;
  self.columnDismissHandler = nil;
}

- (void)dealloc {
  if (_columnGeometryObserver) {
    [[NSNotificationCenter defaultCenter] removeObserver:_columnGeometryObserver];
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self updateColumnFrame];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
  if (!self.columnDismissHandler) {
    [super dismissViewControllerAnimated:flag completion:completion];
    return;
  }
  self.columnDismissHandler();
  if (completion) {
    completion();
  }
}

- (void)scheduleColumnRefresh {
  [self updateColumnFrame];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf updateColumnFrame];
  });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [weakSelf updateColumnFrame];
  });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [weakSelf updateColumnFrame];
  });
}

- (void)updateColumnFrame {
  UIViewController *host = _columnPresenter;
  UIView *container = _columnContainerView;
  if (!host || !host.isViewLoaded || host.view.window == nil || !container) {
    return;
  }
  CGRect target = [host.view convertRect:host.view.bounds toView:container];
  if (target.size.width >= CGRectGetWidth(container.bounds) - 1) {
    target.size.width = MAX(0, target.size.width - MAX(0, container.safeAreaInsets.right));
  }
  if (CGRectEqualToRect(self.view.frame, target)) {
    return;
  }
  self.view.frame = target;
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
  for (UIView *subview in self.view.subviews) {
    [subview setNeedsDisplay];
  }
}

@end
