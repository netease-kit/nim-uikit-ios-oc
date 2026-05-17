// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingSizeCache;
@class NEPagingState;
@class NEPagingItems;
@class NEPagingCellLayoutAttributes;

typedef NS_ENUM(NSInteger, NECollectionViewEdge) {
  NECollectionViewEdgeLeft = 0,
  NECollectionViewEdgeRight = 1,
  NECollectionViewEdgeTop = 2,
  NECollectionViewEdgeBottom = 3,
};

@protocol CollectionViewLayout <NSObject>

@property (nonatomic, strong) NEPagingState *state;
@property (nonatomic, strong) NEPagingItems *visibleItems;
@property (nonatomic, strong, nullable) NEPagingSizeCache *sizeCache;
@property (nonatomic, assign, readonly) UIEdgeInsets contentInsets;
@property (nonatomic, copy, readonly) NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *layoutAttributes;

- (void)prepare;
- (void)invalidateLayout;
- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context;

@end

@protocol NECollectionView <NSObject>

@property (nonatomic, copy, readonly) NSArray<NSIndexPath *> *indexPathsForVisibleItems;
@property (nonatomic, assign, readonly, getter=isDragging) BOOL dragging;
@property (nonatomic, strong, readonly, nullable) UIWindow *window;
@property (nonatomic, strong, readonly, nullable) UIView *superview;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign, readonly) CGSize contentSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) BOOL showsHorizontalScrollIndicator;
@property (nonatomic, weak, nullable) id<UICollectionViewDataSource> dataSource;
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;
@property (nonatomic, assign) UIScrollViewContentInsetAdjustmentBehavior contentInsetAdjustmentBehavior;

- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
- (void)reloadData;
- (void)layoutIfNeeded;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
- (void)selectItemAtIndexPath:(nullable NSIndexPath *)indexPath
                     animated:(BOOL)animated
               scrollPosition:(UICollectionViewScrollPosition)scrollPosition;
- (BOOL)ne_nearEdge:(NECollectionViewEdge)edge clearance:(CGFloat)clearance;

@end

@interface UICollectionView (NECollectionView) <NECollectionView>

- (BOOL)ne_nearEdge:(NECollectionViewEdge)edge clearance:(CGFloat)clearance;

@end

NS_ASSUME_NONNULL_END
