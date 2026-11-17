// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "Array+NSLayoutConstraint.h"

@implementation NSArray (NSLayoutConstraint)

- (NSArray<NSLayoutConstraint *> *)ne_constraintsAnchorFromView:(UIView *)fromView
                                                         toView:(UIView *)toView {
  NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
  for (id item in self) {
    NSLayoutAttribute attribute = (NSLayoutAttribute)[item integerValue];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:fromView
                                                        attribute:attribute
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:toView
                                                        attribute:attribute
                                                       multiplier:1.0
                                                         constant:0]];
  }
  return constraints;
}

@end
