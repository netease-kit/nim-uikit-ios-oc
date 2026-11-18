// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPagingMenuDataSource.h"
#import "NEPagingMenuDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingCollectionViewLayout;
@class NEPagingItems;
@class NEPagingOptions;
@class NEPagingState;

@interface NEPagingMenuView : UIView

@property (nonatomic, weak, nullable) id<NEPagingMenuDelegate> delegate;
@property (nonatomic, weak, nullable) id<NEPagingMenuDataSource> dataSource;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) NEPagingCollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, strong, readonly) NEPagingState *state;
@property (nonatomic, strong, readonly) NEPagingItems *visibleItems;

- (void)viewAppeared;
- (void)transitionSize;
- (void)contentScrolledProgress:(CGFloat)progress;
- (void)contentFinishedScrolling;
- (void)reloadAround:(id<NEPagingItem>)pagingItem;
- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
