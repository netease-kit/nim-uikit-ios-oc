// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;
@class NEPagingState;
@class NEPagingItems;
@class NEPagingSizeCache;
@class NEPagingCellLayoutAttributes;

@protocol NEPagingLayout <NSObject>

@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, strong) NEPagingState *state;
@property (nonatomic, strong) NEPagingItems *visibleItems;
@property (nonatomic, strong, nullable) NEPagingSizeCache *sizeCache;
@property (nonatomic, assign, readonly) UIEdgeInsets contentInsets;
@property (nonatomic, copy, readonly) NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *layoutAttributes;

- (void)prepare;
- (void)invalidateLayout;
- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context;

@end

NS_ASSUME_NONNULL_END
