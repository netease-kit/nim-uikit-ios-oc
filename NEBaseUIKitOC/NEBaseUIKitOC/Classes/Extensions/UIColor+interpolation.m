// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIColor+interpolation.h"

@implementation UIColor (interpolation)

- (void)ne_componentsRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
  const CGFloat *components = CGColorGetComponents(self.CGColor);
  size_t count = CGColorGetNumberOfComponents(self.CGColor);

  CGFloat r = 0;
  CGFloat g = 0;
  CGFloat b = 0;
  CGFloat a = 1;

  if (count == 2) {
    r = components[0];
    g = components[0];
    b = components[0];
    a = components[1];
  } else if (count >= 4) {
    r = components[0];
    g = components[1];
    b = components[2];
    a = components[3];
  }

  if (red) *red = r;
  if (green) *green = g;
  if (blue) *blue = b;
  if (alpha) *alpha = a;
}

+ (UIColor *)interpolateFrom:(UIColor *)from to:(UIColor *)to withFraction:(CGFloat)fraction {
  CGFloat clamped = MIN(1, MAX(0, fraction));

  CGFloat r1 = 0, g1 = 0, b1 = 0, a1 = 1;
  CGFloat r2 = 0, g2 = 0, b2 = 0, a2 = 1;
  [from ne_componentsRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  [to ne_componentsRed:&r2 green:&g2 blue:&b2 alpha:&a2];

  return [UIColor colorWithRed:r1 + (r2 - r1) * clamped
                         green:g1 + (g2 - g1) * clamped
                          blue:b1 + (b2 - b1) * clamped
                         alpha:a1 + (a2 - a1) * clamped];
}

@end

