// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMenuGeometry.h"

BOOL ChatMenuFrameForMessage(CGRect messageRect,
                             CGRect containerBounds,
                             CGRect visibleRect,
                             CGSize menuSize,
                             CGFloat margin,
                             CGRect *_Nullable outFrame) {
  if (menuSize.width <= 0 || menuSize.height <= 0 ||
      containerBounds.size.width <= 0 || containerBounds.size.height <= 0) {
    return NO;
  }
  if (!CGRectIsEmpty(visibleRect) && !CGRectIntersectsRect(messageRect, visibleRect)) {
    return NO;
  }

  CGFloat left = CGRectGetMidX(messageRect) - menuSize.width / 2.0;
  CGFloat maxLeft = CGRectGetMaxX(containerBounds) - menuSize.width - margin;
  CGFloat minLeft = CGRectGetMinX(containerBounds) + margin;
  if (maxLeft < minLeft) {
    left = minLeft;
  } else {
    left = MIN(MAX(left, minLeft), maxLeft);
  }

  CGFloat top = CGRectGetMinY(messageRect) - menuSize.height;
  if (top < CGRectGetMinY(containerBounds) + margin) {
    top = CGRectGetMaxY(messageRect);
  }
  CGFloat maxTop = CGRectGetMaxY(containerBounds) - menuSize.height - margin;
  top = MIN(MAX(top, CGRectGetMinY(containerBounds) + margin), MAX(CGRectGetMinY(containerBounds) + margin, maxTop));

  if (outFrame) {
    *outFrame = CGRectMake(left, top, menuSize.width, menuSize.height);
  }
  return YES;
}
