// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPagingContentInteraction.h"
#import "NEPagingBorderOptions.h"
#import "NEPagingIndicatorOptions.h"
#import "NEPagingMenuHorizontalAlignment.h"
#import "NEPagingMenuInteraction.h"
#import "NEPagingMenuItemSize.h"
#import "NEPagingMenuPosition.h"
#import "NEPagingMenuTransition.h"
#import "NEPageViewDirection.h"
#import "NEPagingItems.h"
#import "NEPagingOptions.h"
#import "NEPagingSelectedScrollPosition.h"
#import "NEPagingState.h"
#import "NEPagingViewControllerDataSource.h"
#import "NEPagingViewControllerDelegate.h"
#import "NEPagingViewControllerInfiniteDataSource.h"
#import "NEPagingViewControllerSizeDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPageViewController;
@class NEPagingCollectionViewLayout;

@interface NEPagingViewController : UIViewController <UICollectionViewDelegate>

@property (nonatomic, copy, readonly) NSArray<UIViewController *> *viewControllers;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly) NEPagingState *state;
@property (nonatomic, strong, readonly) NEPagingItems *visibleItems;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) NEPagingCollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong, readonly) NEPageViewController *pageViewController;
@property (nonatomic, strong, readonly) NEPagingOptions *options;

@property (nonatomic, strong) NEPagingMenuItemSize *menuItemSize;
@property (nonatomic, assign) CGFloat menuItemSpacing;
@property (nonatomic, assign) CGFloat menuItemLabelSpacing;
@property (nonatomic, assign) UIEdgeInsets menuInsets;
@property (nonatomic, assign) NEPagingMenuHorizontalAlignment menuHorizontalAlignment;
@property (nonatomic, assign) NEPagingMenuPosition menuPosition;
@property (nonatomic, strong) NEPagingIndicatorOptions *indicatorOptions;
@property (nonatomic, strong) NEPagingBorderOptions *borderOptions;
@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *selectedTextColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
@property (nonatomic, strong) UIColor *menuBackgroundColor;
@property (nonatomic, assign) NEPagingNavigationOrientation contentNavigationOrientation;
@property (nonatomic, assign) NEPagingMenuTransition menuTransition;
@property (nonatomic, assign) PagingMenuInteraction menuInteraction;
@property (nonatomic, assign) Class menuLayoutClass;
@property (nonatomic, assign) NEPagingSelectedScrollPosition selectedScrollPosition;
@property (nonatomic, assign) Class indicatorClass;
@property (nonatomic, assign) Class borderClass;
@property (nonatomic, assign) BOOL includeSafeAreaInsets;
@property (nonatomic, assign) PagingContentInteraction contentInteraction;
@property (nonatomic, weak, nullable) id<NEPagingViewControllerDataSource> dataSource;
@property (nonatomic, weak, nullable) id<NEPagingViewControllerInfiniteDataSource> infiniteDataSource;
@property (nonatomic, weak, nullable) id<NEPagingViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) id<NEPagingViewControllerSizeDelegate> sizeDelegate;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers;
- (instancetype)initWithOptions:(nullable NEPagingOptions *)options
                viewControllers:(nullable NSArray<UIViewController *> *)viewControllers NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil;

- (void)reloadData;
- (void)reloadMenu;
- (void)reloadDataAround:(id<NEPagingItem>)pagingItem;
- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated;
- (void)selectWithIndex:(NSInteger)index animated:(BOOL)animated;
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;
- (void)registerClass:(Class)cellClass forPagingItemType:(Class)pagingItemType;
- (void)registerNib:(UINib *)nib forPagingItemType:(Class)pagingItemType;
- (void)removeContent;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(CGPoint *)targetContentOffset;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)collectionView:(UICollectionView *)collectionView
    targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset;
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView
    didEndDisplayingCell:(UICollectionViewCell *)cell
      forItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
