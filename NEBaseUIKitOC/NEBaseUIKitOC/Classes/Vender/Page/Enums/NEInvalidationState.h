// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEInvalidationState) {
  NEInvalidationStateNothing = 0,
  NEInvalidationStateSizes = 1,
  NEInvalidationStateEverything = 2,
};

static inline NEInvalidationState NEInvalidationStateCombine(NEInvalidationState lhs,
                                                             NEInvalidationState rhs) {
  if (lhs == NEInvalidationStateEverything || rhs == NEInvalidationStateEverything) {
    return NEInvalidationStateEverything;
  }
  if (lhs == NEInvalidationStateSizes || rhs == NEInvalidationStateSizes) {
    return NEInvalidationStateSizes;
  }
  return NEInvalidationStateNothing;
}

static inline NEInvalidationState NEInvalidationStateFromContext(UICollectionViewLayoutInvalidationContext *context) {
  if (context.invalidateEverything || context.invalidateDataSourceCounts) {
    return NEInvalidationStateEverything;
  }
  if ([context respondsToSelector:NSSelectorFromString(@"invalidateSizes")] &&
      [[context valueForKey:@"invalidateSizes"] boolValue]) {
    return NEInvalidationStateSizes;
  }
  return NEInvalidationStateNothing;
}

NS_ASSUME_NONNULL_END
