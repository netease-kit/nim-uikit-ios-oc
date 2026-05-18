// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingTransition.h"

@implementation NEPagingTransition

- (instancetype)initWithContentOffset:(CGPoint)contentOffset
                             distance:(CGFloat)distance {
  self = [super init];
  if (self) {
    _contentOffset = contentOffset;
    _distance = distance;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[NEPagingTransition class]]) {
    return NO;
  }
  NEPagingTransition *other = (NEPagingTransition *)object;
  return CGPointEqualToPoint(self.contentOffset, other.contentOffset) &&
         fabs(self.distance - other.distance) < DBL_EPSILON;
}

- (NSUInteger)hash {
  return (NSUInteger)self.contentOffset.x ^ (NSUInteger)self.contentOffset.y ^ (NSUInteger)llround(self.distance * 1000.0);
}

@end
