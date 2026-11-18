// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENSArray+Sort.h"

@implementation NSArray (NENSArraySort)

- (NSArray<__kindof UIView *> *)neSortedArrayByTag {
  return [self sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    if (![obj1 isKindOfClass:[UIView class]] || ![obj2 isKindOfClass:[UIView class]]) {
      return NSOrderedSame;
    }
    NSInteger leftTag = ((UIView *)obj1).tag;
    NSInteger rightTag = ((UIView *)obj2).tag;
    if (leftTag == rightTag) {
      return NSOrderedSame;
    }
    return leftTag < rightTag ? NSOrderedAscending : NSOrderedDescending;
  }];
}

- (NSArray<__kindof UIView *> *)neSortedArrayByPosition {
  return [self sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    if (![obj1 isKindOfClass:[UIView class]] || ![obj2 isKindOfClass:[UIView class]]) {
      return NSOrderedSame;
    }
    UIView *leftView = (UIView *)obj1;
    UIView *rightView = (UIView *)obj2;
    if (CGRectGetMinY(leftView.frame) != CGRectGetMinY(rightView.frame)) {
      return CGRectGetMinY(leftView.frame) < CGRectGetMinY(rightView.frame) ? NSOrderedAscending : NSOrderedDescending;
    }
    if (CGRectGetMinX(leftView.frame) != CGRectGetMinX(rightView.frame)) {
      return CGRectGetMinX(leftView.frame) < CGRectGetMinX(rightView.frame) ? NSOrderedAscending : NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
}

@end
