// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingDistance.h"
#import "NEPagingCellLayoutAttributes.h"
#import "NEPagingItems.h"
#import "NEPagingItem.h"
#import "NEPagingSelectedScrollPosition.h"
#import "NEPagingSizeCache.h"

@interface NEPagingDistance ()

@property (nonatomic, weak) id<NECollectionView> view;
@property (nonatomic, assign) BOOL hasItemsBefore;
@property (nonatomic, assign) BOOL hasItemsAfter;
@property (nonatomic, strong) id<NEPagingItem> fromItem;
@property (nonatomic, strong, nullable) NEPagingCellLayoutAttributes *fromAttributes;
@property (nonatomic, strong) id<NEPagingItem> toItem;
@property (nonatomic, strong) NEPagingCellLayoutAttributes *toAttributes;
@property (nonatomic, assign) NEPagingSelectedScrollPosition selectedScrollPosition;
@property (nonatomic, strong) NEPagingSizeCache *sizeCache;
@property (nonatomic, assign) NEPagingNavigationOrientation navigationOrientation;

@end

@implementation NEPagingDistance

- (instancetype)initWithView:(id<NECollectionView>)view
            currentPagingItem:(id<NEPagingItem>)currentPagingItem
           upcomingPagingItem:(id<NEPagingItem>)upcomingPagingItem
                 visibleItems:(NEPagingItems *)visibleItems
                    sizeCache:(NEPagingSizeCache *)sizeCache
       selectedScrollPosition:(NEPagingSelectedScrollPosition)selectedScrollPosition
             layoutAttributes:(NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *)layoutAttributes
        navigationOrientation:(NEPagingNavigationOrientation)navigationOrientation {
  NSIndexPath *upcomingIndexPath = [visibleItems indexPathForPagingItem:upcomingPagingItem];
  NEPagingCellLayoutAttributes *upcomingAttributes = upcomingIndexPath ? layoutAttributes[upcomingIndexPath] : nil;
  if (!upcomingAttributes) {
    return nil;
  }

  self = [super init];
  if (self) {
    _view = view;
    _hasItemsBefore = visibleItems.hasItemsBefore;
    _hasItemsAfter = visibleItems.hasItemsAfter;
    _fromItem = currentPagingItem;
    _toItem = upcomingPagingItem;
    _toAttributes = upcomingAttributes;
    _selectedScrollPosition = selectedScrollPosition;
    _sizeCache = sizeCache;
    _navigationOrientation = navigationOrientation;

    NSIndexPath *currentIndexPath = [visibleItems indexPathForPagingItem:currentPagingItem];
    if (currentIndexPath) {
      _fromAttributes = layoutAttributes[currentIndexPath];
    }
  }
  return self;
}

- (CGFloat)calculate {
  CGFloat distance = 0;
  switch (self.selectedScrollPosition) {
    case NEPagingSelectedScrollPositionLeft:
      distance = [self distanceLeft];
      break;
    case NEPagingSelectedScrollPositionRight:
      distance = [self distanceRight];
      break;
    case NEPagingSelectedScrollPositionPreferCentered:
    case NEPagingSelectedScrollPositionCenter:
      distance = [self distanceCentered];
      break;
  }

  if ([self.view ne_nearEdge:NECollectionViewEdgeLeft clearance:-distance] && distance < 0 && self.hasItemsBefore == NO) {
    distance = -([self contentOffset] + self.view.contentInset.left);
  } else if ([self.view ne_nearEdge:NECollectionViewEdgeRight clearance:distance] && distance > 0 && self.hasItemsAfter == NO) {
    CGFloat originalDistance = distance;
    distance = [self contentSize] - ([self contentOffset] + [self viewSize]);

    if (self.sizeCache.implementsSizeDelegate) {
      CGFloat toWidth = [self.sizeCache itemWidthSelectedForPagingItem:self.toItem];
      distance += toWidth - [self toSize];

      if (self.fromAttributes) {
        CGFloat fromWidth = [self.sizeCache itemSizeForPagingItem:self.fromItem];
        distance -= [self fromSize] - fromWidth;
      }

      if (self.selectedScrollPosition == NEPagingSelectedScrollPositionPreferCentered) {
        CGFloat center = [self viewCenter];
        CGFloat centerAfterTransition = [self toCenter] - distance;
        if (centerAfterTransition < center) {
          distance = originalDistance;
        }
      }
    }
  }

  return distance;
}

- (CGFloat)distanceLeft {
  CGFloat currentPosition = [self toCenter] - ([self toSize] / 2.0);
  CGFloat distance = currentPosition - [self contentOffset];

  if (self.sizeCache.implementsSizeDelegate && self.fromAttributes && [self.fromItem isBeforePagingItem:self.toItem]) {
    CGFloat fromWidth = [self.sizeCache itemSizeForPagingItem:self.fromItem];
    CGFloat fromDiff = [self fromSize] - fromWidth;
    distance -= fromDiff;
  }

  return distance;
}

- (CGFloat)distanceRight {
  CGFloat currentPosition = [self toCenter] + ([self toSize] / 2.0);
  CGFloat width = [self contentOffset] + [self viewSize];
  CGFloat distance = currentPosition - width;

  if (self.sizeCache.implementsSizeDelegate) {
    CGFloat toWidth = [self.sizeCache itemWidthSelectedForPagingItem:self.toItem];
    if (self.fromAttributes) {
      if ([self.toItem isBeforePagingItem:self.fromItem]) {
        CGFloat toDiff = toWidth - [self toSize];
        distance += toDiff;
      } else {
        CGFloat fromWidth = [self.sizeCache itemSizeForPagingItem:self.fromItem];
        CGFloat fromDiff = [self fromSize] - fromWidth;
        CGFloat toDiff = toWidth - [self toSize];
        distance -= fromDiff;
        distance += toDiff;
      }
    } else {
      distance += toWidth - [self toSize];
    }
  }

  return distance;
}

- (CGFloat)distanceCentered {
  CGFloat distance = [self toCenter] - [self viewCenter];

  if (self.fromAttributes) {
    CGFloat distanceToCenter = [self viewCenter] - [self fromCenter];
    CGFloat distanceBetweenCells = [self toCenter] - [self fromCenter];
    distance = distanceBetweenCells - distanceToCenter;

    if (self.sizeCache.implementsSizeDelegate) {
      CGFloat toWidth = [self.sizeCache itemWidthSelectedForPagingItem:self.toItem];
      CGFloat fromWidth = [self.sizeCache itemSizeForPagingItem:self.fromItem];

      if ([self.toItem isBeforePagingItem:self.fromItem]) {
        distance = -([self toSize] + ([self fromCenter] - ([self toCenter] + ([self toSize] / 2.0))) - (toWidth / 2.0)) - distanceToCenter;
      } else {
        CGFloat toDiff = (toWidth - [self toSize]) / 2.0;
        distance = fromWidth + ([self toCenter] - ([self fromCenter] + ([self fromSize] / 2.0))) + toDiff - ([self fromSize] / 2.0) - distanceToCenter;
      }
    }
  } else if (self.sizeCache.implementsSizeDelegate) {
    CGFloat toWidth = [self.sizeCache itemWidthSelectedForPagingItem:self.toItem];
    CGFloat toDiff = toWidth - [self toSize];
    distance += toDiff / 2.0;
  }

  return distance;
}

- (CGFloat)fromSize {
  if (!self.fromAttributes) {
    return 0;
  }
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? CGRectGetHeight(self.fromAttributes.bounds) : CGRectGetWidth(self.fromAttributes.bounds);
}

- (CGFloat)fromCenter {
  if (!self.fromAttributes) {
    return 0;
  }
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? self.fromAttributes.center.y : self.fromAttributes.center.x;
}

- (CGFloat)toSize {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? CGRectGetHeight(self.toAttributes.bounds) : CGRectGetWidth(self.toAttributes.bounds);
}

- (CGFloat)toCenter {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? self.toAttributes.center.y : self.toAttributes.center.x;
}

- (CGFloat)contentOffset {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? self.view.contentOffset.y : self.view.contentOffset.x;
}

- (CGFloat)contentSize {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? self.view.contentSize.height : self.view.contentSize.width;
}

- (CGFloat)viewSize {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? CGRectGetHeight(self.view.bounds) : CGRectGetWidth(self.view.bounds);
}

- (CGFloat)viewCenter {
  return self.navigationOrientation == NEPagingNavigationOrientationVertical ? CGRectGetMidY(self.view.bounds) : CGRectGetMidX(self.view.bounds);
}

@end
