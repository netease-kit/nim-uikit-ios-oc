// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIView+NECorner.h"

@interface NECornerOverlayView : UIView

@property (nonatomic, assign) UIRectCorner corner;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIColor *fillColor;

- (instancetype)initWithCorner:(UIRectCorner)corner radius:(CGFloat)radius color:(UIColor *)color;

@end

@implementation NECornerOverlayView

- (instancetype)initWithCorner:(UIRectCorner)corner radius:(CGFloat)radius color:(UIColor *)color {
  self = [super initWithFrame:CGRectMake(0, 0, radius, radius)];
  if (self) {
    _corner = corner;
    _radius = radius;
    _fillColor = color ?: UIColor.whiteColor;
    self.backgroundColor = UIColor.clearColor;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context) {
    return;
  }
  [self.fillColor set];
  CGContextSetLineWidth(context, 1.0);
  switch (self.corner) {
    case UIRectCornerBottomLeft:
      CGContextMoveToPoint(context, self.radius, self.radius);
      CGContextAddLineToPoint(context, 0, self.radius);
      CGContextAddLineToPoint(context, 0, 0);
      CGContextAddArc(context, self.radius, 0, self.radius, M_PI, M_PI_2, 1);
      break;
    case UIRectCornerBottomRight:
      CGContextMoveToPoint(context, self.radius, 0);
      CGContextAddLineToPoint(context, self.radius, self.radius);
      CGContextAddLineToPoint(context, 0, self.radius);
      CGContextAddArc(context, 0, 0, self.radius, M_PI_2, 0, 1);
      break;
    case UIRectCornerTopRight:
      CGContextMoveToPoint(context, 0, 0);
      CGContextAddLineToPoint(context, self.radius, 0);
      CGContextAddLineToPoint(context, self.radius, self.radius);
      CGContextAddArc(context, 0, self.radius, self.radius, 0, -M_PI_2, 1);
      break;
    case UIRectCornerTopLeft:
      CGContextMoveToPoint(context, 0, self.radius);
      CGContextAddLineToPoint(context, 0, 0);
      CGContextAddLineToPoint(context, self.radius, 0);
      CGContextAddArc(context, self.radius, self.radius, self.radius, 1.5 * M_PI, M_PI, 1);
      break;
    default:
      break;
  }
  CGContextFillPath(context);
  CGContextStrokePath(context);
}

@end

@implementation UIView (NECorner)

- (void)addCustomCorner:(UIRectCorner)corners radius:(CGFloat)radius backcolor:(UIColor *)backcolor {
    [self removeAllCustomCorner];

    if (corners & UIRectCornerTopLeft) {
      NECornerOverlayView *view = [[NECornerOverlayView alloc] initWithCorner:UIRectCornerTopLeft radius:radius color:backcolor];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      view.tag = 10001;
      [self addSubview:view];
      [NSLayoutConstraint activateConstraints:@[
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [view.topAnchor constraintEqualToAnchor:self.topAnchor],
        [view.widthAnchor constraintEqualToConstant:radius],
        [view.heightAnchor constraintEqualToConstant:radius],
      ]];
    }

    if (corners & UIRectCornerTopRight) {
      NECornerOverlayView *view = [[NECornerOverlayView alloc] initWithCorner:UIRectCornerTopRight radius:radius color:backcolor];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      view.tag = 10002;
      [self addSubview:view];
      [NSLayoutConstraint activateConstraints:@[
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [view.topAnchor constraintEqualToAnchor:self.topAnchor],
        [view.widthAnchor constraintEqualToConstant:radius],
        [view.heightAnchor constraintEqualToConstant:radius],
      ]];
    }

    if (corners & UIRectCornerBottomRight) {
      NECornerOverlayView *view = [[NECornerOverlayView alloc] initWithCorner:UIRectCornerBottomRight radius:radius color:backcolor];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      view.tag = 10003;
      [self addSubview:view];
      [NSLayoutConstraint activateConstraints:@[
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [view.widthAnchor constraintEqualToConstant:radius],
        [view.heightAnchor constraintEqualToConstant:radius],
      ]];
    }

    if (corners & UIRectCornerBottomLeft) {
      NECornerOverlayView *view = [[NECornerOverlayView alloc] initWithCorner:UIRectCornerBottomLeft radius:radius color:backcolor];
      view.translatesAutoresizingMaskIntoConstraints = NO;
      view.tag = 10004;
      [self addSubview:view];
      [NSLayoutConstraint activateConstraints:@[
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [view.widthAnchor constraintEqualToConstant:radius],
        [view.heightAnchor constraintEqualToConstant:radius],
      ]];
    }
}

- (void)addCustomCornerWithConrners:(UIRectCorner)corners radius:(CGFloat)radius backcolor:(UIColor *)backcolor {
    [self addCustomCorner:corners radius:radius backcolor:backcolor];
}

- (void)removeAllAutoLayout {
    NSArray<NSLayoutConstraint *> *selfConstraints = self.constraints.copy;
    if (selfConstraints.count > 0) {
        [NSLayoutConstraint deactivateConstraints:selfConstraints];
        [self removeConstraints:selfConstraints];
    }

    UIView *container = self.superview;
    while (container) {
        NSMutableArray<NSLayoutConstraint *> *relatedConstraints = [NSMutableArray array];
        for (NSLayoutConstraint *constraint in container.constraints.copy) {
            if (constraint.firstItem == self || constraint.secondItem == self) {
                [relatedConstraints addObject:constraint];
            }
        }

        if (relatedConstraints.count > 0) {
            [NSLayoutConstraint deactivateConstraints:relatedConstraints];
            [container removeConstraints:relatedConstraints];
        }
        container = container.superview;
    }
}

- (void)removeAllCustomCorner {
    [[self viewWithTag:10001] removeFromSuperview];
    [[self viewWithTag:10002] removeFromSuperview];
    [[self viewWithTag:10003] removeFromSuperview];
    [[self viewWithTag:10004] removeFromSuperview];
}

@end
