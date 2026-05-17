// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingIndicatorMetric.h"

@implementation NEPagingIndicatorMetric

- (instancetype)initWithFrame:(CGRect)frame spacing:(UIEdgeInsets)spacing {
  return [self initWithFrame:frame
                     spacing:spacing
                   insetKind:NEPagingIndicatorMetricInsetKindNone
                   leftInset:0
                  rightInset:0];
}

- (instancetype)initWithFrame:(CGRect)frame
                      spacing:(UIEdgeInsets)spacing
                    insetKind:(NEPagingIndicatorMetricInsetKind)insetKind
                    leftInset:(CGFloat)leftInset
                   rightInset:(CGFloat)rightInset {
  self = [super init];
  if (self) {
    _frame = frame;
    _spacing = spacing;
    _insetKind = insetKind;
    _leftInset = leftInset;
    _rightInset = rightInset;
  }
  return self;
}

+ (instancetype)metricWithFrame:(CGRect)frame spacing:(UIEdgeInsets)spacing {
  return [[self alloc] initWithFrame:frame spacing:spacing];
}

+ (instancetype)metricWithFrame:(CGRect)frame
                        spacing:(UIEdgeInsets)spacing
                      insetKind:(NEPagingIndicatorMetricInsetKind)insetKind
                      leftInset:(CGFloat)leftInset
                     rightInset:(CGFloat)rightInset {
  return [[self alloc] initWithFrame:frame
                             spacing:spacing
                           insetKind:insetKind
                           leftInset:leftInset
                          rightInset:rightInset];
}

- (CGFloat)x {
  switch (self.insetKind) {
    case NEPagingIndicatorMetricInsetKindLeft:
    case NEPagingIndicatorMetricInsetKindBoth:
      return CGRectGetMinX(self.frame) + MAX(self.leftInset, self.spacing.left);
    case NEPagingIndicatorMetricInsetKindNone:
    case NEPagingIndicatorMetricInsetKindRight:
      return CGRectGetMinX(self.frame) + self.spacing.left;
  }
}

- (CGFloat)width {
  switch (self.insetKind) {
    case NEPagingIndicatorMetricInsetKindLeft:
      return CGRectGetWidth(self.frame) - MAX(self.leftInset, self.spacing.left) - self.spacing.right;
    case NEPagingIndicatorMetricInsetKindRight:
      return CGRectGetWidth(self.frame) - MAX(self.rightInset, self.spacing.right) - self.spacing.left;
    case NEPagingIndicatorMetricInsetKindBoth:
      return CGRectGetWidth(self.frame) - MAX(self.rightInset, self.spacing.right) - MAX(self.leftInset, self.spacing.left);
    case NEPagingIndicatorMetricInsetKindNone:
      return CGRectGetWidth(self.frame) - self.spacing.left - self.spacing.right;
  }
}

@end
