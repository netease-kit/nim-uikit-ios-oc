// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SearchTextField.h"

@implementation SearchTextField

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
  CGRect rect = [super leftViewRectForBounds:bounds];
  rect.origin.x += (_leftViewRectX ? _leftViewRectX.floatValue : 10.0f);
  return rect;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
  CGRect rect = [super placeholderRectForBounds:bounds];
  rect.origin.x += 1;
  return rect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  CGRect rect = [super editingRectForBounds:bounds];
  rect.origin.x += 5;
  return rect;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
  CGRect rect = [super textRectForBounds:bounds];
  rect.origin.x += 5;
  return rect;
}

@end
