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

@interface NEPagingViewController : UIViewController

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
                viewControllers:(NSArray<UIViewController *> *)viewControllers NS_DESIGNATED_INITIALIZER;

- (void)reloadData;
- (void)reloadMenu;
- (void)reloadDataAround:(id<NEPagingItem>)pagingItem;
- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated;
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;
- (void)registerClass:(Class)cellClass forPagingItemType:(Class)pagingItemType;
- (void)registerNib:(UINib *)nib forPagingItemType:(Class)pagingItemType;

@end

NS_ASSUME_NONNULL_END
