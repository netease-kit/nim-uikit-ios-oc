// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEInvalidationState.h"
#import "NECollectionView.h"
#import "NEPagingLayout.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingBorderLayoutAttributes;
@class NEPagingIndicatorLayoutAttributes;
@class NEPagingOptions;
@class NEPagingItems;
@class NEPagingSizeCache;
@class NEPagingState;

@interface NEPagingCollectionViewLayout : UICollectionViewLayout <NEPagingLayout, CollectionViewLayout>

@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, strong) NEPagingState *state;
@property (nonatomic, strong) NEPagingItems *visibleItems;
@property (nonatomic, strong, nullable) NEPagingSizeCache *sizeCache;
@property (nonatomic, copy, readonly) NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *layoutAttributes;
@property (nonatomic, strong, readonly, nullable) NEPagingIndicatorLayoutAttributes *indicatorLayoutAttributes;
@property (nonatomic, strong, readonly, nullable) NEPagingBorderLayoutAttributes *borderLayoutAttributes;
@property (nonatomic, assign) NEInvalidationState invalidationState;
@property (nonatomic, assign, readonly) UIEdgeInsets contentInsets;

@end

NS_ASSUME_NONNULL_END
