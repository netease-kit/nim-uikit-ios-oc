// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUIScrollView+Additions.h"
#import <objc/runtime.h>

static void *NEShouldIgnoreScrollingAdjustmentKey = &NEShouldIgnoreScrollingAdjustmentKey;
static void *NEShouldIgnoreContentInsetAdjustmentKey = &NEShouldIgnoreContentInsetAdjustmentKey;
static void *NEShouldRestoreScrollViewContentOffsetKey = &NEShouldRestoreScrollViewContentOffsetKey;

@implementation UIScrollView (NEAdditions)

- (BOOL)neShouldIgnoreScrollingAdjustment {
  return [objc_getAssociatedObject(self, NEShouldIgnoreScrollingAdjustmentKey) boolValue];
}

- (void)setNeShouldIgnoreScrollingAdjustment:(BOOL)neShouldIgnoreScrollingAdjustment {
  objc_setAssociatedObject(self, NEShouldIgnoreScrollingAdjustmentKey, @(neShouldIgnoreScrollingAdjustment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)neShouldIgnoreContentInsetAdjustment {
  return [objc_getAssociatedObject(self, NEShouldIgnoreContentInsetAdjustmentKey) boolValue];
}

- (void)setNeShouldIgnoreContentInsetAdjustment:(BOOL)neShouldIgnoreContentInsetAdjustment {
  objc_setAssociatedObject(self, NEShouldIgnoreContentInsetAdjustmentKey, @(neShouldIgnoreContentInsetAdjustment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)neShouldRestoreScrollViewContentOffset {
  return [objc_getAssociatedObject(self, NEShouldRestoreScrollViewContentOffsetKey) boolValue];
}

- (void)setNeShouldRestoreScrollViewContentOffset:(BOOL)neShouldRestoreScrollViewContentOffset {
  objc_setAssociatedObject(self, NEShouldRestoreScrollViewContentOffsetKey, @(neShouldRestoreScrollViewContentOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UITableView (NEAdditions)

- (NSIndexPath *)nePreviousIndexPathOf:(NSIndexPath *)indexPath {
  NSInteger previousRow = indexPath.row - 1;
  NSInteger previousSection = indexPath.section;
  if (previousRow < 0) {
    previousSection -= 1;
    if (previousSection >= 0) {
      previousRow = [self numberOfRowsInSection:previousSection] - 1;
    }
  }
  if (previousRow >= 0 && previousSection >= 0) {
    return [NSIndexPath indexPathForRow:previousRow inSection:previousSection];
  }
  return nil;
}

@end

@implementation UICollectionView (NEAdditions)

- (NSIndexPath *)nePreviousIndexPathOf:(NSIndexPath *)indexPath {
  NSInteger previousItem = indexPath.item - 1;
  NSInteger previousSection = indexPath.section;
  if (previousItem < 0) {
    previousSection -= 1;
    if (previousSection >= 0) {
      previousItem = [self numberOfItemsInSection:previousSection] - 1;
    }
  }
  if (previousItem >= 0 && previousSection >= 0) {
    return [NSIndexPath indexPathForItem:previousItem inSection:previousSection];
  }
  return nil;
}

@end
