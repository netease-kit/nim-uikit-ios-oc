// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "RedAngleLabel.h"

@implementation RedAngleLabel

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _textInsets = UIEdgeInsetsMake(3, 7, 3, 7);
    self.accessibilityIdentifier = @"id.unread";
  }
  return self;
}

- (void)drawTextInRect:(CGRect)rect {
  [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
  UIEdgeInsets insets = self.textInsets;
  CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                  limitedToNumberOfLines:numberOfLines];
  rect.origin.x    -= insets.left;
  rect.origin.y    -= insets.top;
  rect.size.width  += (insets.left + insets.right);
  rect.size.height += (insets.top  + insets.bottom);
  return rect;
}

@end
