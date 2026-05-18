// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingCollectionViewLayout.h"
#import "NEInvalidationState.h"
#import "NEPagingBorderLayoutAttributes.h"
#import "NEPagingBorderOptions.h"
#import "NEPagingCellLayoutAttributes.h"
#import "NEPagingIndicatorLayoutAttributes.h"
#import "NEPagingIndicatorMetric.h"
#import "NEPagingIndicatorOptions.h"
#import "NEPagingInvalidationContext.h"
#import "NEPagingItem.h"
#import "NEPagingItems.h"
#import "NEPagingMenuHorizontalAlignment.h"
#import "NEPagingMenuItemSize.h"
#import "NEPagingOptions.h"
#import "NEPagingSizeCache.h"
#import "NEPagingState.h"
#import "Tween.h"
#import "UIEdgeInsets.h"

@interface NEPagingCollectionViewLayout ()

@property (nonatomic, copy, readwrite) NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *layoutAttributes;
@property (nonatomic, strong, readwrite, nullable) NEPagingIndicatorLayoutAttributes *indicatorLayoutAttributes;
@property (nonatomic, strong, readwrite, nullable) NEPagingBorderLayoutAttributes *borderLayoutAttributes;
@property (nonatomic, assign, readwrite) UIEdgeInsets contentInsets;
@property (nonatomic, assign) CGSize cachedContentSize;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *preferredSizeCache;

@end

@implementation NEPagingCollectionViewLayout

static NSString * const NEPagingIndicatorKind = @"NEPagingIndicatorKind";
static NSString * const NEPagingBorderKind = @"NEPagingBorderKind";

+ (Class)layoutAttributesClass {
  return [NEPagingCellLayoutAttributes class];
}

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
  return YES;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _options = [[NEPagingOptions alloc] init];
    _state = [NEPagingState emptyState];
    _visibleItems = [[NEPagingItems alloc] initWithItems:@[] hasItemsBefore:NO hasItemsAfter:NO];
    _layoutAttributes = @{};
    _contentInsets = UIEdgeInsetsZero;
    _cachedContentSize = CGSizeZero;
    _preferredSizeCache = [NSMutableDictionary dictionary];
    _invalidationState = NEInvalidationStateEverything;
    [self registerBorderClass];
    [self registerIndicatorClass];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _options = [[NEPagingOptions alloc] init];
    _state = [NEPagingState emptyState];
    _visibleItems = [[NEPagingItems alloc] initWithItems:@[] hasItemsBefore:NO hasItemsAfter:NO];
    _layoutAttributes = @{};
    _contentInsets = UIEdgeInsetsZero;
    _cachedContentSize = CGSizeZero;
    _preferredSizeCache = [NSMutableDictionary dictionary];
    _invalidationState = NEInvalidationStateEverything;
    [self registerBorderClass];
    [self registerIndicatorClass];
  }
  return self;
}

- (void)setOptions:(NEPagingOptions *)options {
  NEPagingOptions *oldValue = _options;
  _options = options ?: [[NEPagingOptions alloc] init];
  [self optionsChangedFrom:oldValue];
}

- (CGSize)collectionViewContentSize {
  return self.cachedContentSize;
}

- (void)prepareLayout {
  [super prepareLayout];

  switch (self.invalidationState) {
    case NEInvalidationStateEverything:
      self.layoutAttributes = @{};
      self.borderLayoutAttributes = nil;
      self.indicatorLayoutAttributes = nil;
      [self createLayoutAttributes];
      [self createDecorationLayoutAttributes];
      break;
    case NEInvalidationStateSizes:
      self.layoutAttributes = @{};
      [self createLayoutAttributes];
      break;
    case NEInvalidationStateNothing:
      break;
  }

  [self updateBorderLayoutAttributes];
  [self updateIndicatorLayoutAttributes];
  self.invalidationState = NEInvalidationStateNothing;
}

- (void)invalidateLayout {
  [super invalidateLayout];
  self.invalidationState = NEInvalidationStateEverything;
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
  [super invalidateLayoutWithContext:context];
  self.invalidationState = NEInvalidationStateCombine(self.invalidationState, NEInvalidationStateFromContext(context));
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes
                                                                         withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
  NEPagingInvalidationContext *context = [[NEPagingInvalidationContext alloc] init];
  context.invalidateSizes = YES;
  return context;
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes
                                   withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes {
  if (self.options.menuItemSize.sizingMode == NEPagingMenuItemSizingModeSelfSizing &&
      [originalAttributes isKindOfClass:[NEPagingCellLayoutAttributes class]]) {
    if (CGRectGetWidth(preferredAttributes.frame) != CGRectGetWidth(originalAttributes.frame)) {
      id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:originalAttributes.indexPath];
      self.preferredSizeCache[@(pagingItem.identifier)] = @(CGRectGetWidth(preferredAttributes.frame));
      return YES;
    }
  }
  return NO;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
  NEPagingCellLayoutAttributes *attributes = self.layoutAttributes[indexPath];
  attributes.progress = [self progressForItemAtIndexPath:indexPath];
  return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind
                                                                  atIndexPath:(NSIndexPath *)indexPath {
  if ([elementKind isEqualToString:NEPagingIndicatorKind]) {
    return self.indicatorLayoutAttributes;
  }
  if ([elementKind isEqualToString:NEPagingBorderKind]) {
    return self.borderLayoutAttributes;
  }
  return [super layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSMutableArray<UICollectionViewLayoutAttributes *> *attributes = [NSMutableArray arrayWithArray:self.layoutAttributes.allValues];
  for (UICollectionViewLayoutAttributes *layoutAttribute in attributes) {
    if ([layoutAttribute isKindOfClass:[NEPagingCellLayoutAttributes class]]) {
      ((NEPagingCellLayoutAttributes *)layoutAttribute).progress = [self progressForItemAtIndexPath:layoutAttribute.indexPath];
    }
  }

  UICollectionViewLayoutAttributes *indicator = [self layoutAttributesForDecorationViewOfKind:NEPagingIndicatorKind
                                                                                   atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  UICollectionViewLayoutAttributes *border = [self layoutAttributesForDecorationViewOfKind:NEPagingBorderKind
                                                                                atIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
  if (indicator) {
    [attributes addObject:indicator];
  }
  if (border) {
    [attributes addObject:border];
  }
  return [attributes copy];
}

- (void)optionsChangedFrom:(NEPagingOptions *)oldValue {
  BOOL shouldInvalidate = NO;
  if (self.options.borderClass != oldValue.borderClass) {
    [self registerBorderClass];
    shouldInvalidate = YES;
  }
  if (self.options.indicatorClass != oldValue.indicatorClass) {
    [self registerIndicatorClass];
    shouldInvalidate = YES;
  }
  if (self.options.borderColor != oldValue.borderColor) {
    shouldInvalidate = YES;
  }
  if (self.options.indicatorColor != oldValue.indicatorColor) {
    shouldInvalidate = YES;
  }
  if (shouldInvalidate) {
    [self invalidateLayout];
  }
}

- (void)registerIndicatorClass {
  [self registerClass:self.options.indicatorClass forDecorationViewOfKind:NEPagingIndicatorKind];
}

- (void)registerBorderClass {
  [self registerClass:self.options.borderClass forDecorationViewOfKind:NEPagingBorderKind];
}

- (void)createLayoutAttributes {
  if (!self.sizeCache || !self.collectionView) {
    return;
  }

  NSMutableDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *layoutAttributes = [NSMutableDictionary dictionary];
  CGRect previousFrame = CGRectZero;
  previousFrame.origin.x = self.adjustedMenuInsets.left - self.options.menuItemSpacing;

  NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
  for (NSInteger index = 0; index < itemCount; index++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    NEPagingCellLayoutAttributes *attributes = [NEPagingCellLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGFloat x = CGRectGetMaxX(previousFrame) + self.options.menuItemSpacing;
    CGFloat y = self.adjustedMenuInsets.top;
    id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:indexPath];

    if (self.sizeCache.implementsSizeDelegate) {
      CGFloat width = [self.sizeCache itemSizeForPagingItem:pagingItem];
      CGFloat selectedWidth = [self.sizeCache itemWidthSelectedForPagingItem:pagingItem];
      if (self.state.currentPagingItem && [self.state.currentPagingItem isEqualToPagingItem:pagingItem]) {
        width = NEPagingTween(selectedWidth, width, fabs(self.state.progress));
      } else if (self.state.upcomingPagingItem && [self.state.upcomingPagingItem isEqualToPagingItem:pagingItem]) {
        width = NEPagingTween(width, selectedWidth, fabs(self.state.progress));
      }
      attributes.frame = CGRectMake(x, y, width, self.options.menuItemSize.height);
    } else {
      switch (self.options.menuItemSize.sizingMode) {
        case NEPagingMenuItemSizingModeFixed:
          attributes.frame = CGRectMake(x, y, self.options.menuItemSize.width, self.options.menuItemSize.height);
          break;
        case NEPagingMenuItemSizingModeSizeToFit:
          attributes.frame = CGRectMake(x, y, self.options.menuItemSize.minimumWidth, self.options.menuItemSize.height);
          break;
        case NEPagingMenuItemSizingModeSelfSizing: {
          NSNumber *actualWidth = self.preferredSizeCache[@(pagingItem.identifier)];
          CGFloat width = actualWidth ? actualWidth.doubleValue : self.options.menuItemSize.width;
          attributes.frame = CGRectMake(x, y, width, self.options.menuItemSize.height);
          break;
        }
      }
    }

    previousFrame = attributes.frame;
    layoutAttributes[indexPath] = attributes;
  }

  if (itemCount > 0 && CGRectGetMaxX(previousFrame) - self.adjustedMenuInsets.left < CGRectGetWidth(self.collectionView.bounds)) {
    if (self.options.menuItemSize.sizingMode == NEPagingMenuItemSizingModeSizeToFit && self.sizeCache.implementsSizeDelegate == NO) {
      CGFloat insets = self.adjustedMenuInsets.left + self.adjustedMenuInsets.right;
      CGFloat spacing = self.options.menuItemSpacing * MAX(itemCount - 1, 0);
      CGFloat width = (CGRectGetWidth(self.collectionView.bounds) - insets - spacing) / itemCount;
      previousFrame = CGRectZero;
      previousFrame.origin.x = self.adjustedMenuInsets.left - self.options.menuItemSpacing;

      NSArray<NEPagingCellLayoutAttributes *> *sortedAttributes = [layoutAttributes.allValues sortedArrayUsingComparator:^NSComparisonResult(NEPagingCellLayoutAttributes *lhs, NEPagingCellLayoutAttributes *rhs) {
        return [lhs.indexPath compare:rhs.indexPath];
      }];
      for (NEPagingCellLayoutAttributes *attributes in sortedAttributes) {
        CGFloat x = CGRectGetMaxX(previousFrame) + self.options.menuItemSpacing;
        CGFloat y = self.adjustedMenuInsets.top;
        attributes.frame = CGRectMake(x, y, width, self.options.menuItemSize.height);
        previousFrame = attributes.frame;
      }
    } else {
      CGFloat offset = 0;
      switch (self.options.menuHorizontalAlignment) {
        case NEPagingMenuHorizontalAlignmentCenter:
          offset = (CGRectGetWidth(self.collectionView.bounds) - CGRectGetMaxX(previousFrame) - self.adjustedMenuInsets.left) / 2.0;
          break;
        case NEPagingMenuHorizontalAlignmentRight:
          offset = CGRectGetWidth(self.collectionView.bounds) - CGRectGetMaxX(previousFrame) - self.adjustedMenuInsets.right;
          break;
        case NEPagingMenuHorizontalAlignmentLeft:
          break;
      }
      if (offset != 0) {
        for (NEPagingCellLayoutAttributes *attributes in layoutAttributes.allValues) {
          attributes.frame = CGRectOffset(attributes.frame, offset, 0);
        }
      }
    }
  }

  if (self.options.selectedScrollPosition == NEPagingSelectedScrollPositionCenter && itemCount > 0) {
    NSArray<NEPagingCellLayoutAttributes *> *sortedAttributes = [layoutAttributes.allValues sortedArrayUsingComparator:^NSComparisonResult(NEPagingCellLayoutAttributes *lhs, NEPagingCellLayoutAttributes *rhs) {
      return [lhs.indexPath compare:rhs.indexPath];
    }];
    NEPagingCellLayoutAttributes *first = sortedAttributes.firstObject;
    NEPagingCellLayoutAttributes *last = sortedAttributes.lastObject;
    CGFloat insetLeft = (CGRectGetWidth(self.collectionView.bounds) / 2.0) - (CGRectGetWidth(first.bounds) / 2.0);
    CGFloat insetRight = (CGRectGetWidth(self.collectionView.bounds) / 2.0) - (CGRectGetWidth(last.bounds) / 2.0);
    for (NEPagingCellLayoutAttributes *attributes in layoutAttributes.allValues) {
      attributes.frame = CGRectOffset(attributes.frame, insetLeft, 0);
    }
    self.contentInsets = UIEdgeInsetsMake(0,
                                          insetLeft + self.adjustedMenuInsets.left,
                                          0,
                                          insetRight + self.adjustedMenuInsets.right);
    self.cachedContentSize = CGSizeMake(CGRectGetMaxX(previousFrame) + insetLeft + insetRight + self.adjustedMenuInsets.right,
                                        CGRectGetHeight(self.collectionView.bounds));
  } else {
    self.contentInsets = self.adjustedMenuInsets;
    self.cachedContentSize = CGSizeMake(CGRectGetMaxX(previousFrame) + self.adjustedMenuInsets.right,
                                        CGRectGetHeight(self.collectionView.bounds));
  }

  self.layoutAttributes = [layoutAttributes copy];
}

- (void)createDecorationLayoutAttributes {
  if (self.options.indicatorOptions.visible) {
    self.indicatorLayoutAttributes = [NEPagingIndicatorLayoutAttributes layoutAttributesForDecorationViewOfKind:NEPagingIndicatorKind
                                                                                                      withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  }
  if (self.options.borderOptions.visible) {
    self.borderLayoutAttributes = [NEPagingBorderLayoutAttributes layoutAttributesForDecorationViewOfKind:NEPagingBorderKind
                                                                                              withIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
  }
}

- (void)updateBorderLayoutAttributes {
  [self.borderLayoutAttributes configureWithOptions:self.options];
  [self.borderLayoutAttributes updateWithContentSize:self.collectionViewContentSize
                                              bounds:self.collectionView.bounds
                                      safeAreaInsets:self.safeAreaInsets];
}

- (void)updateIndicatorLayoutAttributes {
  if (!self.state.currentPagingItem) {
    return;
  }
  [self.indicatorLayoutAttributes configureWithOptions:self.options];

  NSIndexPath *currentIndexPath = [self.visibleItems indexPathForPagingItem:self.state.currentPagingItem];
  NSIndexPath *upcomingIndexPath = [self upcomingIndexPathForIndexPath:currentIndexPath];
  if (upcomingIndexPath) {
    CGFloat progress = fabs(self.state.progress);
    NEPagingIndicatorMetric *toMetric = [self indicatorMetricForIndex:upcomingIndexPath.item];
    if (currentIndexPath) {
      NEPagingIndicatorMetric *fromMetric = [self indicatorMetricForIndex:currentIndexPath.item];
      [self.indicatorLayoutAttributes updateFromMetric:fromMetric toMetric:toMetric progress:progress];
    } else if ([self indicatorMetricForFirstItem]) {
      [self.indicatorLayoutAttributes updateFromMetric:[self indicatorMetricForFirstItem] toMetric:toMetric progress:progress];
    } else if ([self indicatorMetricForLastItem]) {
      [self.indicatorLayoutAttributes updateFromMetric:[self indicatorMetricForLastItem] toMetric:toMetric progress:progress];
    }
  } else if ([self indicatorMetricForFirstItem]) {
    [self.indicatorLayoutAttributes updateToMetric:[self indicatorMetricForFirstItem]];
  } else if ([self indicatorMetricForLastItem]) {
    [self.indicatorLayoutAttributes updateToMetric:[self indicatorMetricForLastItem]];
  }
}

- (NEPagingIndicatorMetric *)indicatorMetricForFirstItem {
  if (!self.state.currentPagingItem || self.visibleItems.items.count == 0) {
    return nil;
  }
  id<NEPagingItem> first = self.visibleItems.items.firstObject;
  if ([self.state.currentPagingItem isBeforePagingItem:first]) {
    return [self indicatorMetricForIndex:-1];
  }
  return nil;
}

- (NEPagingIndicatorMetric *)indicatorMetricForLastItem {
  if (!self.state.currentPagingItem || self.visibleItems.items.count == 0) {
    return nil;
  }
  id<NEPagingItem> last = self.visibleItems.items.lastObject;
  if ([last isBeforePagingItem:self.state.currentPagingItem]) {
    return [self indicatorMetricForIndex:self.visibleItems.items.count];
  }
  return nil;
}

- (CGFloat)progressForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.state.currentPagingItem) {
    return 0;
  }
  NSIndexPath *currentIndexPath = [self.visibleItems indexPathForPagingItem:self.state.currentPagingItem];
  if (currentIndexPath && indexPath.item == currentIndexPath.item) {
    return 1 - fabs(self.state.progress);
  }
  NSIndexPath *upcomingIndexPath = [self upcomingIndexPathForIndexPath:currentIndexPath];
  if (upcomingIndexPath && indexPath.item == upcomingIndexPath.item) {
    return fabs(self.state.progress);
  }
  return 0;
}

- (NSIndexPath *)upcomingIndexPathForIndexPath:(NSIndexPath *)indexPath {
  if (self.state.upcomingPagingItem) {
    return [self.visibleItems indexPathForPagingItem:self.state.upcomingPagingItem];
  }
  if (!indexPath) {
    return nil;
  }
  NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
  if (indexPath.item == 0) {
    return [NSIndexPath indexPathForItem:-1 inSection:0];
  }
  if (indexPath.item == itemCount - 1) {
    return [NSIndexPath indexPathForItem:itemCount inSection:0];
  }
  return indexPath;
}

- (UIEdgeInsets)indicatorSpacingForIndex:(NSInteger)index {
  return self.options.indicatorOptions.visible ? self.options.indicatorOptions.spacing : UIEdgeInsetsZero;
}

- (NEPagingIndicatorMetric *)indicatorMetricForIndex:(NSInteger)index {
  CGRect frame = [self indicatorFrameForIndex:index];
  UIEdgeInsets spacing = [self indicatorSpacingForIndex:index];
  NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
  UIEdgeInsets insets = self.options.indicatorOptions.insets;
  if (index == 0 && itemCount == 1) {
    return [NEPagingIndicatorMetric metricWithFrame:frame
                                            spacing:spacing
                                          insetKind:NEPagingIndicatorMetricInsetKindBoth
                                          leftInset:insets.left
                                         rightInset:insets.right];
  }
  if (index == 0) {
    return [NEPagingIndicatorMetric metricWithFrame:frame
                                            spacing:spacing
                                          insetKind:NEPagingIndicatorMetricInsetKindLeft
                                          leftInset:insets.left
                                         rightInset:0];
  }
  if (index >= itemCount - 1) {
    return [NEPagingIndicatorMetric metricWithFrame:frame
                                            spacing:spacing
                                          insetKind:NEPagingIndicatorMetricInsetKindRight
                                          leftInset:0
                                         rightInset:insets.right];
  }
  return [NEPagingIndicatorMetric metricWithFrame:frame spacing:spacing];
}

- (CGRect)indicatorFrameForIndex:(NSInteger)index {
  NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
  if (index < 0) {
    CGRect frame = [self frameForIndex:0];
    return CGRectOffset(frame, -CGRectGetWidth(frame), 0);
  }
  if (index > itemCount - 1) {
    CGRect frame = [self frameForIndex:itemCount - 1];
    return CGRectOffset(frame, CGRectGetWidth(frame), 0);
  }
  return [self frameForIndex:index];
}

- (CGRect)frameForIndex:(NSInteger)index {
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
  NEPagingCellLayoutAttributes *attributes = self.layoutAttributes[indexPath];
  if (!attributes) {
    return CGRectZero;
  }
  CGRect frame = CGRectMake(attributes.center.x - CGRectGetMidX(attributes.bounds),
                            attributes.center.y - CGRectGetMidY(attributes.bounds),
                            CGRectGetWidth(attributes.bounds),
                            CGRectGetHeight(attributes.bounds));
  if (self.sizeCache.implementsSizeDelegate) {
    id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:indexPath];
    if (self.state.upcomingPagingItem && self.state.currentPagingItem) {
      if ([self.state.upcomingPagingItem isEqualToPagingItem:pagingItem] ||
          [self.state.currentPagingItem isEqualToPagingItem:pagingItem]) {
        frame.size.width = [self.sizeCache itemWidthSelectedForPagingItem:pagingItem];
      }
    }
  }
  return frame;
}

- (UIEdgeInsets)adjustedMenuInsets {
  return UIEdgeInsetsMake(self.options.menuInsets.top,
                          self.options.menuInsets.left + self.safeAreaInsets.left,
                          self.options.menuInsets.bottom,
                          self.options.menuInsets.right + self.safeAreaInsets.right);
}

- (UIEdgeInsets)safeAreaInsets {
  if (self.options.includeSafeAreaInsets) {
    return self.collectionView.safeAreaInsets;
  }
  return UIEdgeInsetsZero;
}

@end
