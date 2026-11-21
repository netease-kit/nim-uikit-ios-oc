// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveContentInsets.h"

#import <objc/runtime.h>

static void *NEAdaptiveManagedKey = &NEAdaptiveManagedKey;
static void *NEAdaptiveOriginalContentInsetKey = &NEAdaptiveOriginalContentInsetKey;
static void *NEAdaptiveOriginalIndicatorInsetKey = &NEAdaptiveOriginalIndicatorInsetKey;
static void *NEAdaptiveOriginalAdjustmentBehaviorKey = &NEAdaptiveOriginalAdjustmentBehaviorKey;
static void *NEAdaptiveOriginalAutomaticIndicatorInsetKey = &NEAdaptiveOriginalAutomaticIndicatorInsetKey;
static void *NEAdaptiveOriginalInsetsToSafeAreaKey = &NEAdaptiveOriginalInsetsToSafeAreaKey;
static void *NEAdaptiveOriginalLayoutMarginsKey = &NEAdaptiveOriginalLayoutMarginsKey;
static void *NEAdaptiveOriginalReadableMarginsKey = &NEAdaptiveOriginalReadableMarginsKey;
static void *NEAdaptiveScrollManagedKey = &NEAdaptiveScrollManagedKey;
static void *NEAdaptiveScrollOriginalIndicatorInsetKey = &NEAdaptiveScrollOriginalIndicatorInsetKey;
static void *NEAdaptiveScrollOriginalAdjustmentBehaviorKey = &NEAdaptiveScrollOriginalAdjustmentBehaviorKey;
static void *NEAdaptiveScrollOriginalAutomaticIndicatorInsetKey = &NEAdaptiveScrollOriginalAutomaticIndicatorInsetKey;

@implementation UIScrollView (NEAdaptiveContentInsets)

- (void)ne_resetContentInsetsManagedByContainer {
  if (objc_getAssociatedObject(self, NEAdaptiveManagedKey) != nil) {
    [self ne_setContentInsetsManagedByContainer:NO];
  }
}

- (void)ne_resetScrollIndicatorsManagedByContainer {
  if (objc_getAssociatedObject(self, NEAdaptiveScrollManagedKey) != nil) {
    [self ne_setScrollIndicatorsManagedByContainer:NO];
  }
}

- (void)ne_setScrollIndicatorsManagedByContainer:(BOOL)managed {
  if (managed) {
    if (objc_getAssociatedObject(self, NEAdaptiveScrollManagedKey) == nil) {
      objc_setAssociatedObject(self, NEAdaptiveScrollManagedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveScrollOriginalIndicatorInsetKey,
                               [NSValue valueWithUIEdgeInsets:self.verticalScrollIndicatorInsets],
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveScrollOriginalAdjustmentBehaviorKey,
                               @(self.contentInsetAdjustmentBehavior),
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveScrollOriginalAutomaticIndicatorInsetKey,
                               @(self.automaticallyAdjustsScrollIndicatorInsets),
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.automaticallyAdjustsScrollIndicatorInsets = NO;
    UIEdgeInsets indicatorInset = self.verticalScrollIndicatorInsets;
    indicatorInset.right = 0;
    self.verticalScrollIndicatorInsets = indicatorInset;
    return;
  }

  if (objc_getAssociatedObject(self, NEAdaptiveScrollManagedKey) == nil) {
    return;
  }
  NSValue *originalIndicatorInset = objc_getAssociatedObject(self, NEAdaptiveScrollOriginalIndicatorInsetKey);
  if (originalIndicatorInset) {
    self.verticalScrollIndicatorInsets = originalIndicatorInset.UIEdgeInsetsValue;
  }
  NSNumber *originalAdjustment = objc_getAssociatedObject(self, NEAdaptiveScrollOriginalAdjustmentBehaviorKey);
  if (originalAdjustment) {
    self.contentInsetAdjustmentBehavior = (UIScrollViewContentInsetAdjustmentBehavior)originalAdjustment.integerValue;
  }
  NSNumber *originalAutomaticIndicatorInset = objc_getAssociatedObject(self, NEAdaptiveScrollOriginalAutomaticIndicatorInsetKey);
  if (originalAutomaticIndicatorInset) {
    self.automaticallyAdjustsScrollIndicatorInsets = originalAutomaticIndicatorInset.boolValue;
  }
  objc_setAssociatedObject(self, NEAdaptiveScrollManagedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveScrollOriginalIndicatorInsetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveScrollOriginalAdjustmentBehaviorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveScrollOriginalAutomaticIndicatorInsetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ne_setContentInsetsManagedByContainer:(BOOL)managed {
  if (managed) {
    if (objc_getAssociatedObject(self, NEAdaptiveManagedKey) == nil) {
      objc_setAssociatedObject(self, NEAdaptiveManagedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveOriginalContentInsetKey,
                               [NSValue valueWithUIEdgeInsets:self.contentInset],
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveOriginalIndicatorInsetKey,
                               [NSValue valueWithUIEdgeInsets:self.verticalScrollIndicatorInsets],
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveOriginalAdjustmentBehaviorKey,
                               @(self.contentInsetAdjustmentBehavior),
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveOriginalAutomaticIndicatorInsetKey,
                               @(self.automaticallyAdjustsScrollIndicatorInsets),
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(self, NEAdaptiveOriginalLayoutMarginsKey,
                               [NSValue valueWithUIEdgeInsets:self.layoutMargins],
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      if ([self isKindOfClass:[UITableView class]]) {
        UITableView *table = (UITableView *)self;
        objc_setAssociatedObject(self, NEAdaptiveOriginalInsetsToSafeAreaKey,
                                 @(table.insetsContentViewsToSafeArea),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, NEAdaptiveOriginalReadableMarginsKey,
                                 @(table.cellLayoutMarginsFollowReadableWidth),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
    }

    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.automaticallyAdjustsScrollIndicatorInsets = NO;
    self.layoutMargins = UIEdgeInsetsZero;

    if ([self isKindOfClass:[UITableView class]]) {
      UITableView *table = (UITableView *)self;
      table.insetsContentViewsToSafeArea = NO;
      table.cellLayoutMarginsFollowReadableWidth = NO;
    }

    NSValue *originalContentInset = objc_getAssociatedObject(self, NEAdaptiveOriginalContentInsetKey);
    if (originalContentInset) {
      UIEdgeInsets inset = originalContentInset.UIEdgeInsetsValue;
      inset.bottom += self.safeAreaInsets.bottom;
      self.contentInset = inset;
    }
    NSValue *originalIndicatorInset = objc_getAssociatedObject(self, NEAdaptiveOriginalIndicatorInsetKey);
    if (originalIndicatorInset) {
      UIEdgeInsets inset = originalIndicatorInset.UIEdgeInsetsValue;
      inset.bottom += self.safeAreaInsets.bottom;
      inset.right = 0;
      self.verticalScrollIndicatorInsets = inset;
    }
    return;
  }

  if (objc_getAssociatedObject(self, NEAdaptiveManagedKey) == nil) {
    return;
  }

  NSValue *originalContentInset = objc_getAssociatedObject(self, NEAdaptiveOriginalContentInsetKey);
  if (originalContentInset) {
    self.contentInset = originalContentInset.UIEdgeInsetsValue;
  }
  NSValue *originalIndicatorInset = objc_getAssociatedObject(self, NEAdaptiveOriginalIndicatorInsetKey);
  if (originalIndicatorInset) {
    self.verticalScrollIndicatorInsets = originalIndicatorInset.UIEdgeInsetsValue;
  }
  NSNumber *originalAdjustment = objc_getAssociatedObject(self, NEAdaptiveOriginalAdjustmentBehaviorKey);
  if (originalAdjustment) {
    self.contentInsetAdjustmentBehavior = (UIScrollViewContentInsetAdjustmentBehavior)originalAdjustment.integerValue;
  }
  NSNumber *originalAutomaticIndicatorInset =
      objc_getAssociatedObject(self, NEAdaptiveOriginalAutomaticIndicatorInsetKey);
  if (originalAutomaticIndicatorInset) {
    self.automaticallyAdjustsScrollIndicatorInsets = originalAutomaticIndicatorInset.boolValue;
  }
  NSValue *originalLayoutMargins = objc_getAssociatedObject(self, NEAdaptiveOriginalLayoutMarginsKey);
  if (originalLayoutMargins) {
    self.layoutMargins = originalLayoutMargins.UIEdgeInsetsValue;
  }
  if ([self isKindOfClass:[UITableView class]]) {
    UITableView *table = (UITableView *)self;
    NSNumber *originalInsets = objc_getAssociatedObject(self, NEAdaptiveOriginalInsetsToSafeAreaKey);
    if (originalInsets) {
      table.insetsContentViewsToSafeArea = originalInsets.boolValue;
    }
    NSNumber *originalReadable = objc_getAssociatedObject(self, NEAdaptiveOriginalReadableMarginsKey);
    if (originalReadable) {
      table.cellLayoutMarginsFollowReadableWidth = originalReadable.boolValue;
    }
  }

  objc_setAssociatedObject(self, NEAdaptiveManagedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalContentInsetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalIndicatorInsetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalAdjustmentBehaviorKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalAutomaticIndicatorInsetKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalLayoutMarginsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalInsetsToSafeAreaKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, NEAdaptiveOriginalReadableMarginsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
