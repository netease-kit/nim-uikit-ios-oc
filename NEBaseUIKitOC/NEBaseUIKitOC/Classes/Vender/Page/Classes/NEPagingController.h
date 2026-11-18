// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NECollectionView.h"
#import "NEPagingMenuDataSource.h"
#import "NEPagingMenuDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;
@class NEPagingState;
@class NEPagingItems;
@class NEPagingSizeCache;

@protocol PagingControllerSizeDelegate <NSObject>

- (CGFloat)widthForPagingItem:(id<NEPagingItem>)pagingItem isSelected:(BOOL)isSelected;

@end

@interface NEPagingController : NSObject

@property (nonatomic, weak, nullable) id<NEPagingMenuDataSource> dataSource;
@property (nonatomic, weak, nullable) id<PagingControllerSizeDelegate> sizeDelegate;
@property (nonatomic, weak, nullable) id<NEPagingMenuDelegate> delegate;
@property (nonatomic, weak) id<NECollectionView> collectionView;
@property (nonatomic, strong) UICollectionViewLayout<CollectionViewLayout> *collectionViewLayout;
@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, strong, readonly) NEPagingState *state;
@property (nonatomic, strong, readonly) NEPagingItems *visibleItems;
@property (nonatomic, strong, readonly) NEPagingSizeCache *sizeCache;

- (instancetype)initWithOptions:(NEPagingOptions *)options;
- (void)selectIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated;
- (void)contentScrolledProgress:(CGFloat)progress;
- (void)contentFinishedScrolling;
- (void)transitionSize;
- (void)removeAll;
- (void)viewAppeared;
- (void)reloadDataAround:(id<NEPagingItem>)pagingItem;
- (void)reloadMenuAround:(id<NEPagingItem>)pagingItem;
- (void)menuScrolled;

@end

NS_ASSUME_NONNULL_END
