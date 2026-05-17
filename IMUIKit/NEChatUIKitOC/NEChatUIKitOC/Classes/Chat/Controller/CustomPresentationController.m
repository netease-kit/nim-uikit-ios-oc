// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomPresentationController.h"

@interface CustomPresentationController ()
@property (nonatomic, strong) UIView *dimmingView;
@end

@implementation CustomPresentationController

- (UIView *)dimmingView {
    if (!_dimmingView) {
        _dimmingView = [[UIView alloc] init];
        _dimmingView.translatesAutoresizingMaskIntoConstraints = NO;
        _dimmingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(handleTap:)];
        [_dimmingView addGestureRecognizer:recognizer];
    }
    return _dimmingView;
}

- (CGRect)frameOfPresentedViewInContainerView {
    CGRect frame = CGRectZero;
    CGSize size = [self sizeForChildContentContainer:self.presentedViewController
                             withParentContainerSize:self.containerView.bounds.size];
    frame.size = size;
    frame.origin.y = size.height - 404;
    return frame;
}

- (void)presentationTransitionWillBegin {
    UIView *containerView = self.containerView;
    if (!containerView) return;
    
    [containerView insertSubview:self.dimmingView atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [self.dimmingView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [self.dimmingView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [self.dimmingView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [self.dimmingView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
    ]];
    
    id<UIViewControllerTransitionCoordinator> coordinator = self.presentedViewController.transitionCoordinator;
    if (!coordinator) {
        self.dimmingView.alpha = 1.0;
        return;
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 1.0;
    } completion:nil];
}

- (void)dismissalTransitionWillBegin {
    id<UIViewControllerTransitionCoordinator> coordinator = self.presentedViewController.transitionCoordinator;
    if (!coordinator) {
        self.dimmingView.alpha = 0.0;
        return;
    }
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 0.0;
    } completion:nil];
}

- (void)containerViewWillLayoutSubviews {
    self.presentedView.frame = self.frameOfPresentedViewInContainerView;
}

- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container
               withParentContainerSize:(CGSize)parentSize {
    return CGSizeMake(parentSize.width, parentSize.height);
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
