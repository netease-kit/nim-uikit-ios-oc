// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEActionSheetDismissalController.h"

@implementation NEActionSheetDismissalController

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
  return transitionContext.isInteractive ? 0.6 : 0.2;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  if (!fromVC) return;

  NSTimeInterval duration = [self transitionDuration:transitionContext];
  UIViewAnimationOptions curve = transitionContext.isInteractive
    ? UIViewAnimationOptionCurveLinear
    : UIViewAnimationOptionTransitionFlipFromBottom;

  [UIView animateWithDuration:duration delay:0 options:curve animations:^{
    fromVC.view.transform = CGAffineTransformMakeTranslation(0, fromVC.view.frame.size.height);
  } completion:^(BOOL finished) {
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
  }];
}

@end
