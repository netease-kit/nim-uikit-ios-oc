// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ExpandButton.h"

@implementation ExpandButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  CGRect bounds = self.bounds;
  CGFloat widthDelta = MAX(44.0 - bounds.size.width, 0);
  CGFloat heightDelta = MAX(44.0 - bounds.size.height, 0);
  bounds = CGRectInset(bounds, -0.5 * widthDelta, -0.5 * heightDelta);
  return CGRectContainsPoint(bounds, point);
}

@end