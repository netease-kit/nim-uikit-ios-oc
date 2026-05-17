// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NECollectionView.h"
#import "NEPagingNavigationOrientation.h"
#import "NEPagingSelectedScrollPosition.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingItems;
@class NEPagingSizeCache;
@class NEPagingCellLayoutAttributes;
@protocol NEPagingItem;

@interface NEPagingDistance : NSObject

- (nullable instancetype)initWithView:(id<NECollectionView>)view
                    currentPagingItem:(id<NEPagingItem>)currentPagingItem
                   upcomingPagingItem:(id<NEPagingItem>)upcomingPagingItem
                         visibleItems:(NEPagingItems *)visibleItems
                            sizeCache:(NEPagingSizeCache *)sizeCache
               selectedScrollPosition:(NEPagingSelectedScrollPosition)selectedScrollPosition
                     layoutAttributes:(NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *)layoutAttributes
                navigationOrientation:(NEPagingNavigationOrientation)navigationOrientation;
- (CGFloat)calculate;

@end

NS_ASSUME_NONNULL_END
