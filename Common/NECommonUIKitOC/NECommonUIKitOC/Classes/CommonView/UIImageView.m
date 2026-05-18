// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIImageView.h"

@implementation CornerView

- (instancetype)initWithCorner:(UIRectCorner)corner
                        radius:(CGFloat)radius
                         color:(UIColor *)color {
  self = [super initWithFrame:CGRectMake(0, 0, radius, radius)];
  if (self) {
    _corner = corner;
    _radius = radius;
    _color = color ?: UIColor.whiteColor;
    self.backgroundColor = UIColor.clearColor;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context) {
    return;
  }

  [self.color set];
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
