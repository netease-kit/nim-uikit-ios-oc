// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEActionSheetPresentationController.h"

@interface NEActionSheetPresentationController ()
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, weak) UIViewController *toViewController;
@property (nonatomic, weak) UITapGestureRecognizer *dismissGesture;
@property (nonatomic, weak) UIPanGestureRecognizer *dismissDrivenGesture;
@end

@implementation NEActionSheetPresentationController

- (instancetype)init {
  self = [super init];
  if (self) {
    _dismissOnTouchOutside = YES;
    _interactiveDismissalDistance = 30;
  }
  return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
  return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  if (!toVC) return;

  CGSize preferedSize = toVC.preferredContentSize;
  UIView *containerView = transitionContext.containerView;
  NSTimeInterval duration = [self transitionDuration:transitionContext];

  toVC.view.frame = CGRectMake(0,
                                containerView.bounds.size.height - preferedSize.height,
                                preferedSize.width,
                                preferedSize.height);
  toVC.view.transform = CGAffineTransformMakeTranslation(0, preferedSize.height);
  [containerView addSubview:toVC.view];
  self.containerView = containerView;
  self.toViewController = toVC;

  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
    toVC.view.transform = CGAffineTransformIdentity;
  } completion:^(BOOL finished) {
    if (self.dismissOnTouchOutside) {
      UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissTap:)];
      tapGesture.delegate = self;
      tapGesture.numberOfTapsRequired = 1;
      tapGesture.numberOfTouchesRequired = 1;
      [containerView addGestureRecognizer:tapGesture];
      self.dismissGesture = tapGesture;
    }
    if (self.interactiveDismissalDistance > 0) {
      UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissDrive:)];
      panGesture.delegate = self;
      panGesture.minimumNumberOfTouches = 1;
      [containerView addGestureRecognizer:panGesture];
      self.dismissDrivenGesture = panGesture;
    }
    [transitionContext completeTransition:finished];
  }];
}

#pragma mark - Gesture Handlers

- (void)handleDismissTap:(UITapGestureRecognizer *)sender {
  [self.toViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleDismissDrive:(UIPanGestureRecognizer *)sender {
  switch (sender.state) {
    case UIGestureRecognizerStateBegan:
      [self.toViewController dismissViewControllerAnimated:YES completion:nil];
      break;
    case UIGestureRecognizerStateChanged: {
      CGFloat height = self.toViewController.view.frame.size.height;
      if (height > 0) {
        CGFloat translateY = [sender translationInView:self.containerView].y;
        CGFloat progress = translateY / height;
        [self.dismissAnimator updateInteractiveTransition:progress];
      }
      break;
    }
    case UIGestureRecognizerStateEnded: {
      CGFloat toHeight = self.toViewController.view.frame.size.height;
      CGFloat containerHeight = self.containerView.frame.size.height;
      CGFloat maxPercent = containerHeight > 0 ? toHeight / containerHeight : 0;
      if (self.dismissAnimator.percentComplete / (maxPercent > 0 ? maxPercent : 1) > 0.3) {
        [self.dismissAnimator finishInteractiveTransition];
      } else {
        [self.dismissAnimator cancelInteractiveTransition];
      }
      self.dismissAnimator = nil;
      break;
    }
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
      [self.dismissAnimator cancelInteractiveTransition];
      self.dismissAnimator = nil;
      break;
    default:
      break;
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (!self.toViewController) return NO;
  if (gestureRecognizer == self.dismissGesture) {
    CGPoint location = [gestureRecognizer locationInView:self.toViewController.view];
    return !CGRectContainsPoint(self.toViewController.view.bounds, location);
  }
  if (gestureRecognizer == self.dismissDrivenGesture) {
    CGPoint location = [gestureRecognizer locationInView:self.toViewController.view];
    BOOL shouldStart = location.y >= 0 && location.y <= self.interactiveDismissalDistance;
    if (shouldStart) {
      self.dismissAnimator = [[UIPercentDrivenInteractiveTransition alloc] init];
    }
    return shouldStart;
  }
  return NO;
}

@end
