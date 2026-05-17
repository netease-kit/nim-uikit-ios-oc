// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIView+constraints.h"

@implementation UIView (constraints)

- (BOOL)isVisibleInWindow {
  UIWindow *window = self.window;
  if (!window) {
    return NO;
  }
  CGRect frameInWindow = [self convertRect:self.bounds toView:window];
  return CGRectIntersectsRect(window.bounds, frameInWindow);
}

- (void)constrainToEdges:(UIView *)subview {
  subview.translatesAutoresizingMaskIntoConstraints = NO;
  [self addConstraints:@[
    [NSLayoutConstraint constraintWithItem:subview
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0],
    [NSLayoutConstraint constraintWithItem:subview
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0],
    [NSLayoutConstraint constraintWithItem:subview
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0],
    [NSLayoutConstraint constraintWithItem:subview
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0],
  ]];
}

@end
