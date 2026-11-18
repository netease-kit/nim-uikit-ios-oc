// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingCellLayoutAttributes.h"

@implementation NEPagingCellLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
  NEPagingCellLayoutAttributes *copy = [super copyWithZone:zone];
  copy.progress = self.progress;
  return copy;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[NEPagingCellLayoutAttributes class]]) {
    return NO;
  }
  NEPagingCellLayoutAttributes *other = (NEPagingCellLayoutAttributes *)object;
  if (fabs(self.progress - other.progress) > DBL_EPSILON) {
    return NO;
  }
  return [super isEqual:object];
}

@end
