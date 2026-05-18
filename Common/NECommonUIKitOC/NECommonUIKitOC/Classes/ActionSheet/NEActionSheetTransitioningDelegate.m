// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEActionSheetTransitioningDelegate.h"
#import "NEActionSheetPresentationController.h"
#import "NEActionSheetDismissalController.h"

@interface NEActionSheetTransitioningDelegate ()
@property (nonatomic, strong) NEActionSheetPresentationController *presentationCtrl;
@property (nonatomic, strong) NEActionSheetDismissalController *dismissalCtrl;
@end

@implementation NEActionSheetTransitioningDelegate

- (instancetype)init {
  self = [super init];
  if (self) {
    _dismissOnTouchOutside = YES;
    _interactiveDismissalDistance = 30;
    _presentationCtrl = [[NEActionSheetPresentationController alloc] init];
    _dismissalCtrl = [[NEActionSheetDismissalController alloc] init];
  }
  return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                           presentingController:(UIViewController *)presenting
                                                                               sourceController:(UIViewController *)source {
  return _presentationCtrl;
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
  return _dismissalCtrl;
}

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
  return _presentationCtrl.dismissAnimator;
}

@end
