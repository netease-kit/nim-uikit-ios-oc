// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEViewExtension.h"

@implementation UIView (NEViewExtension)

- (CGFloat)left { return self.frame.origin.x; }
- (void)setLeft:(CGFloat)left {
  CGRect frame = self.frame;
  frame.origin.x = left;
  self.frame = frame;
}

- (CGFloat)top { return self.frame.origin.y; }
- (void)setTop:(CGFloat)top {
  CGRect frame = self.frame;
  frame.origin.y = top;
  self.frame = frame;
}

- (CGFloat)width { return self.frame.size.width; }
- (void)setWidth:(CGFloat)width {
  CGRect frame = self.frame;
  frame.size.width = width;
  self.frame = frame;
}

- (CGFloat)height { return self.frame.size.height; }
- (void)setHeight:(CGFloat)height {
  CGRect frame = self.frame;
  frame.size.height = height;
  self.frame = frame;
}

- (CGFloat)right { return self.left + self.width; }
- (CGFloat)bottom { return self.top + self.height; }

- (CGFloat)centerX { return self.center.x; }
- (void)setCenterX:(CGFloat)centerX {
  CGPoint center = self.center;
  center.x = centerX;
  self.center = center;
}

- (CGFloat)centerY { return self.center.y; }
- (void)setCenterY:(CGFloat)centerY {
  CGPoint center = self.center;
  center.y = centerY;
  self.center = center;
}

- (void)addCorner:(UIRectCorner)corners radius:(CGFloat)radius {
  UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                 byRoundingCorners:corners
                                                       cornerRadii:CGSizeMake(radius, radius)];
  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  maskLayer.fillColor = UIColor.redColor.CGColor;
  maskLayer.frame = self.bounds;
  maskLayer.path = maskPath.CGPath;
  self.layer.mask = maskLayer;
}

- (NSLayoutConstraint *)getLayoutConstraintWithFirstItem:(UIView *)firstItem
                                              secondItem:(UIView *)secondItem
                                               attribute:(NSLayoutAttribute)attribute {
  for (NSLayoutConstraint *constraint in self.constraints) {
    UIView *constraintFirstItem = [constraint.firstItem isKindOfClass:[UIView class]] ? (UIView *)constraint.firstItem : nil;
    UIView *constraintSecondItem = [constraint.secondItem isKindOfClass:[UIView class]] ? (UIView *)constraint.secondItem : nil;

    if (constraintFirstItem == firstItem &&
        constraintSecondItem == secondItem &&
        constraint.firstAttribute == attribute) {
      return constraint;
    }

    if (!secondItem &&
        constraintFirstItem == firstItem &&
        constraint.firstAttribute == attribute) {
      return constraint;
    }
  }
  return nil;
}

- (void)updateLayoutConstraintWithFirstItem:(UIView *)firstItem
                                 secondItem:(UIView *)secondItem
                                  attribute:(NSLayoutAttribute)attribute
                                   constant:(CGFloat)constant {
  NSLayoutConstraint *constraint = [self getLayoutConstraintWithFirstItem:firstItem
                                                               secondItem:secondItem
                                                                attribute:attribute];
  constraint.constant = constant;
}

- (void)removeLayoutConstraintWithFirstItem:(UIView *)firstItem
                                 secondItem:(UIView *)secondItem
                                  attribute:(NSLayoutAttribute)attribute {
  NSLayoutConstraint *constraint = [self getLayoutConstraintWithFirstItem:firstItem
                                                               secondItem:secondItem
                                                                attribute:attribute];
  if (constraint && [self.constraints containsObject:constraint]) {
    [self removeConstraint:constraint];
  }
}

- (UILabel *)findLabelWithString:(NSString *)string {
  if (string.length == 0) {
    return nil;
  }
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[UILabel class]] && [((UILabel *)subview).text isEqualToString:string]) {
      return (UILabel *)subview;
    }
    UILabel *foundLabel = [subview findLabelWithString:string];
    if (foundLabel) {
      return foundLabel;
    }
  }
  return nil;
}

@end

