// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingController.h"
#import "NEPagingCell.h"
#import "NEPagingCellLayoutAttributes.h"
#import "NEPagingDiff.h"
#import "NEPagingDistance.h"
#import "NEPagingInvalidationContext.h"
#import "NEPagingItem.h"
#import "NEPagingItems.h"
#import "NEPagingOptions.h"
#import "NEPagingSizeCache.h"
#import "NEPagingState.h"
#import "NEPagingTransition.h"

@interface NEPagingController () <UICollectionViewDataSource>

@property (nonatomic, strong, readwrite) NEPagingState *state;
@property (nonatomic, strong, readwrite) NEPagingItems *visibleItems;
@property (nonatomic, strong, readwrite) NEPagingSizeCache *sizeCache;
@property (nonatomic, strong, nullable) UISwipeGestureRecognizer *swipeGestureRecognizerLeft;
@property (nonatomic, strong, nullable) UISwipeGestureRecognizer *swipeGestureRecognizerRight;

@end

@implementation NEPagingController

- (instancetype)initWithOptions:(NEPagingOptions *)options {
  self = [super init];
  if (self) {
    _options = options ?: [[NEPagingOptions alloc] init];
    _sizeCache = [[NEPagingSizeCache alloc] initWithOptions:_options];
    _visibleItems = [[NEPagingItems alloc] initWithItems:@[] hasItemsBefore:NO hasItemsAfter:NO];
    _state = [NEPagingState emptyState];
  }
  return self;
}

- (void)setCollectionView:(id<NECollectionView>)collectionView {
  _collectionView = collectionView;
  [self configureCollectionView];
}

- (void)setCollectionViewLayout:(UICollectionViewLayout<CollectionViewLayout> *)collectionViewLayout {
  _collectionViewLayout = collectionViewLayout;
  [self configureCollectionViewLayout];
}

- (void)setOptions:(NEPagingOptions *)options {
  NEPagingOptions *oldValue = _options;
  _options = options ?: [[NEPagingOptions alloc] init];
  [self optionsChangedFrom:oldValue];
}

- (void)setState:(NEPagingState *)state {
  _state = state;
  self.collectionViewLayout.state = state;
}

- (void)setVisibleItems:(NEPagingItems *)visibleItems {
  _visibleItems = visibleItems;
  self.collectionViewLayout.visibleItems = visibleItems;
}

- (void)setSizeCache:(NEPagingSizeCache *)sizeCache {
  _sizeCache = sizeCache;
  self.collectionViewLayout.sizeCache = sizeCache;
}

- (void)selectIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
  id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:indexPath];
  [self selectPagingItem:pagingItem animated:animated];
}

- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated {
  if (!self.collectionView.superview || !self.collectionView.window) {
    self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
    return;
  }

  switch (self.state.kind) {
    case NEPagingStateKindEmpty:
      self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
      [self reloadItemsAround:pagingItem keepExisting:NO];
      [self.delegate selectContentWithPagingItem:pagingItem direction:[PagingDirection noneDirection] animated:NO];
      [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:pagingItem]
                                        animated:NO
                                  scrollPosition:self.options.scrollPosition];
      break;
    case NEPagingStateKindSelected: {
      id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
      if (![pagingItem isEqualToPagingItem:currentPagingItem]) {
        if (animated) {
          [self appendItemsIfNeeded:pagingItem];
          NEPagingTransition *transition = [self calculateTransitionFrom:currentPagingItem to:pagingItem];
          self.state = [NEPagingState scrollingStateWithPagingItem:currentPagingItem
                                                 upcomingPagingItem:pagingItem
                                                           progress:0
                                               initialContentOffset:transition.contentOffset
                                                           distance:transition.distance];
          PagingDirection *direction = [self.visibleItems directionFrom:currentPagingItem to:pagingItem];
          [self.delegate selectContentWithPagingItem:pagingItem direction:direction animated:YES];
        } else {
          self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
          [self reloadItemsAround:pagingItem keepExisting:NO];
          [self.delegate selectContentWithPagingItem:pagingItem direction:[PagingDirection noneDirection] animated:NO];
          [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:pagingItem]
                                            animated:NO
                                      scrollPosition:self.options.scrollPosition];
        }
      }
      break;
    }
    case NEPagingStateKindScrolling:
      break;
  }
}

- (void)contentScrolledProgress:(CGFloat)progress {
  switch (self.state.kind) {
    case NEPagingStateKindSelected: {
      id<NEPagingItem> pagingItem = self.state.currentPagingItem;
      id<NEPagingItem> upcomingPagingItem = nil;
      if (progress > 0) {
        upcomingPagingItem = [self.dataSource pagingItemAfterPagingItem:pagingItem];
      } else if (progress < 0) {
        upcomingPagingItem = [self.dataSource pagingItemBeforePagingItem:pagingItem];
      } else {
        return;
      }
      [self appendItemsIfNeeded:upcomingPagingItem];
      NEPagingTransition *transition = [self calculateTransitionFrom:pagingItem to:upcomingPagingItem];
      [self updateScrollingStateWithPagingItem:pagingItem
                              upcomingPagingItem:upcomingPagingItem
                           initialContentOffset:transition.contentOffset
                                       distance:transition.distance
                                       progress:progress];
      break;
    }
    case NEPagingStateKindScrolling: {
      id<NEPagingItem> pagingItem = self.state.currentPagingItem;
      id<NEPagingItem> upcomingPagingItem = self.state.upcomingPagingItem;
      CGFloat oldProgress = self.state.progress;
      if ((oldProgress < 0 && progress > 0) || (oldProgress > 0 && progress < 0) || progress == 0) {
        self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
      } else {
        [self updateScrollingStateWithPagingItem:pagingItem
                              upcomingPagingItem:upcomingPagingItem
                           initialContentOffset:self.state.initialContentOffset
                                       distance:self.state.distance
                                       progress:progress];
      }
      break;
    }
    case NEPagingStateKindEmpty:
      break;
  }
}

- (void)contentFinishedScrolling {
  if (self.state.kind != NEPagingStateKindScrolling) {
    return;
  }

  id<NEPagingItem> pagingItem = self.state.currentPagingItem;
  id<NEPagingItem> upcomingPagingItem = self.state.upcomingPagingItem;
  if (upcomingPagingItem) {
    self.state = [NEPagingState selectedStateWithPagingItem:upcomingPagingItem];
    if (!self.collectionView.isDragging) {
      [self reloadItemsAround:upcomingPagingItem keepExisting:NO];
      [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:upcomingPagingItem]
                                        animated:self.options.menuTransition == NEPagingMenuTransitionAnimateAfter
                                  scrollPosition:self.options.scrollPosition];
    }
  } else {
    self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
  }
}

- (void)transitionSize {
  if (self.state.kind == NEPagingStateKindScrolling) {
    id<NEPagingItem> pagingItem = self.state.currentPagingItem;
    [self.sizeCache clear];
    self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
    [self reloadItemsAround:pagingItem keepExisting:NO];
    [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:pagingItem]
                                      animated:self.options.menuTransition == NEPagingMenuTransitionAnimateAfter
                                scrollPosition:self.options.scrollPosition];
    return;
  }

  id<NEPagingItem> pagingItem = self.state.currentPagingItem;
  if (pagingItem) {
    [self.sizeCache clear];
    [self reloadItemsAround:pagingItem keepExisting:NO];
    [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:pagingItem]
                                      animated:self.options.menuTransition == NEPagingMenuTransitionAnimateAfter
                                scrollPosition:self.options.scrollPosition];
  }
}

- (void)removeAll {
  self.state = [NEPagingState emptyState];
  [self.sizeCache clear];
  self.visibleItems = [[NEPagingItems alloc] initWithItems:@[] hasItemsBefore:NO hasItemsAfter:NO];
  [self.collectionView reloadData];
  [self.delegate removeContent];
}

- (void)viewAppeared {
  id<NEPagingItem> pagingItem = nil;
  if (self.state.kind == NEPagingStateKindSelected) {
    pagingItem = self.state.currentPagingItem;
  } else if (self.state.kind == NEPagingStateKindScrolling && self.state.upcomingPagingItem) {
    pagingItem = self.state.upcomingPagingItem;
  }
  if (!pagingItem) {
    return;
  }

  self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
  [self reloadItemsAround:pagingItem keepExisting:NO];
  [self.delegate selectContentWithPagingItem:pagingItem direction:[PagingDirection noneDirection] animated:NO];
  [self.collectionView selectItemAtIndexPath:[self.visibleItems indexPathForPagingItem:pagingItem]
                                    animated:NO
                              scrollPosition:self.options.scrollPosition];
}

- (void)reloadDataAround:(id<NEPagingItem>)pagingItem {
  [self reloadMenuAround:pagingItem];
  [self.delegate removeContent];
  [self.delegate selectContentWithPagingItem:pagingItem direction:[PagingDirection noneDirection] animated:NO];
  self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
  [self.collectionViewLayout invalidateLayout];
}

- (void)reloadMenuAround:(id<NEPagingItem>)pagingItem {
  [self.sizeCache clear];
  NSArray<id<NEPagingItem>> *items = [self generateItemsAround:pagingItem];
  self.visibleItems = [[NEPagingItems alloc] initWithItems:items
                                            hasItemsBefore:[self hasItemBefore:items.firstObject]
                                             hasItemsAfter:[self hasItemAfter:items.lastObject]];
  self.state = [NEPagingState selectedStateWithPagingItem:pagingItem];
  [self.collectionViewLayout invalidateLayout];
  [self.collectionView reloadData];
  [self configureSizeCacheFor:pagingItem];
}

- (void)menuScrolled {
  if (self.collectionView.indexPathsForVisibleItems.count == 0) {
    return;
  }

  UIEdgeInsets contentInsets = self.collectionViewLayout.contentInsets;
  if ([self.collectionView ne_nearEdge:NECollectionViewEdgeLeft clearance:contentInsets.left]) {
    id<NEPagingItem> firstPagingItem = self.visibleItems.items.firstObject;
    if (firstPagingItem && self.visibleItems.hasItemsBefore) {
      [self reloadItemsAround:firstPagingItem keepExisting:NO];
    }
  } else if ([self.collectionView ne_nearEdge:NECollectionViewEdgeRight clearance:contentInsets.right]) {
    id<NEPagingItem> lastPagingItem = self.visibleItems.items.lastObject;
    if (lastPagingItem && self.visibleItems.hasItemsAfter) {
      [self reloadItemsAround:lastPagingItem keepExisting:NO];
    }
  }
}

- (void)optionsChangedFrom:(NEPagingOptions *)oldValue {
  if (self.options.menuInteraction != oldValue.menuInteraction) {
    [self configureMenuInteraction];
  }
  self.sizeCache.options = self.options;
  [self.collectionViewLayout invalidateLayout];
}

- (void)configureCollectionViewLayout {
  self.collectionViewLayout.state = self.state;
  self.collectionViewLayout.visibleItems = self.visibleItems;
  self.collectionViewLayout.sizeCache = self.sizeCache;
}

- (void)configureCollectionView {
  self.collectionView.showsHorizontalScrollIndicator = NO;
  self.collectionView.dataSource = self;
  self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  [self configureMenuInteraction];
}

- (void)configureMenuInteraction {
  if (self.swipeGestureRecognizerLeft) {
    [self.collectionView removeGestureRecognizer:self.swipeGestureRecognizerLeft];
  }
  if (self.swipeGestureRecognizerRight) {
    [self.collectionView removeGestureRecognizer:self.swipeGestureRecognizerRight];
  }

  self.collectionView.scrollEnabled = NO;
  self.collectionView.alwaysBounceHorizontal = NO;
  switch (self.options.menuInteraction) {
    case PagingMenuInteractionScrolling:
      self.collectionView.scrollEnabled = YES;
      self.collectionView.alwaysBounceHorizontal = YES;
      break;
    case PagingMenuInteractionSwipe:
      [self setupGestureRecognizers];
      break;
    case PagingMenuInteractionNone:
      break;
  }
}

- (void)setupGestureRecognizers {
  self.swipeGestureRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureRecognizer:)];
  self.swipeGestureRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureRecognizer:)];
  self.swipeGestureRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
  self.swipeGestureRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
  [self.collectionView addGestureRecognizer:self.swipeGestureRecognizerLeft];
  [self.collectionView addGestureRecognizer:self.swipeGestureRecognizerRight];
}

- (void)handleSwipeGestureRecognizer:(UISwipeGestureRecognizer *)recognizer {
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  if (!currentPagingItem) {
    return;
  }
  id<NEPagingItem> pagingItem = nil;
  if (recognizer.direction & UISwipeGestureRecognizerDirectionLeft) {
    pagingItem = [self.dataSource pagingItemAfterPagingItem:currentPagingItem];
  } else if (recognizer.direction & UISwipeGestureRecognizerDirectionRight) {
    pagingItem = [self.dataSource pagingItemBeforePagingItem:currentPagingItem];
  }
  if (pagingItem) {
    [self selectPagingItem:pagingItem animated:YES];
  }
}

- (void)updateScrollingStateWithPagingItem:(id<NEPagingItem>)pagingItem
                        upcomingPagingItem:(nullable id<NEPagingItem>)upcomingPagingItem
                     initialContentOffset:(CGPoint)initialContentOffset
                                 distance:(CGFloat)distance
                                 progress:(CGFloat)progress {
  self.state = [NEPagingState scrollingStateWithPagingItem:pagingItem
                                         upcomingPagingItem:upcomingPagingItem
                                                   progress:progress
                                       initialContentOffset:initialContentOffset
                                                   distance:distance];
  if (self.options.menuTransition == NEPagingMenuTransitionScrollAlongside) {
    NEPagingInvalidationContext *context = [[NEPagingInvalidationContext alloc] init];
    if (upcomingPagingItem) {
      if (self.collectionView.contentSize.width >= CGRectGetWidth(self.collectionView.bounds) && self.state.progress != 0) {
        CGPoint contentOffset = CGPointMake(initialContentOffset.x + distance * fabs(progress), initialContentOffset.y);
        [self.collectionView setContentOffset:contentOffset animated:NO];
      }
      if (self.sizeCache.implementsSizeDelegate) {
        context.invalidateSizes = YES;
      }
    }
    [self.collectionViewLayout invalidateLayoutWithContext:context];
  }
}

- (NEPagingTransition *)calculateTransitionFrom:(id<NEPagingItem>)pagingItem
                                             to:(nullable id<NEPagingItem>)upcomingPagingItem {
  if (!upcomingPagingItem) {
    return [[NEPagingTransition alloc] initWithContentOffset:CGPointZero distance:0];
  }
  NEPagingDistance *distance = [[NEPagingDistance alloc] initWithView:self.collectionView
                                                    currentPagingItem:pagingItem
                                                   upcomingPagingItem:upcomingPagingItem
                                                         visibleItems:self.visibleItems
                                                            sizeCache:self.sizeCache
                                               selectedScrollPosition:self.options.selectedScrollPosition
                                                     layoutAttributes:self.collectionViewLayout.layoutAttributes
                                                navigationOrientation:self.options.contentNavigationOrientation];
  return [[NEPagingTransition alloc] initWithContentOffset:self.collectionView.contentOffset
                                                  distance:distance ? [distance calculate] : 0];
}

- (void)appendItemsIfNeeded:(nullable id<NEPagingItem>)upcomingPagingItem {
  if (upcomingPagingItem && ![self.visibleItems containsPagingItem:upcomingPagingItem]) {
    [self reloadItemsAround:upcomingPagingItem keepExisting:YES];
  }
}

- (void)reloadItemsAround:(id<NEPagingItem>)pagingItem keepExisting:(BOOL)keepExisting {
  NSArray<id<NEPagingItem>> *items = [self generateItemsAround:pagingItem];
  if (keepExisting) {
    items = [self.visibleItems unionWithItems:items];
  }

  NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *oldLayoutAttributes = self.collectionViewLayout.layoutAttributes;
  CGPoint oldContentOffset = self.collectionView.contentOffset;
  NEPagingItems *oldVisibleItems = self.visibleItems;

  [self configureSizeCacheFor:pagingItem];

  self.visibleItems = [[NEPagingItems alloc] initWithItems:items
                                            hasItemsBefore:[self hasItemBefore:items.firstObject]
                                             hasItemsAfter:[self hasItemAfter:items.lastObject]];

  [self.collectionView reloadData];
  [self.collectionViewLayout prepareLayout];

  NSDictionary<NSIndexPath *, NEPagingCellLayoutAttributes *> *newLayoutAttributes = self.collectionViewLayout.layoutAttributes;
  CGFloat offset = 0;
  NEPagingDiff *diff = [[NEPagingDiff alloc] initWithFromItems:oldVisibleItems toItems:self.visibleItems];
  for (NSIndexPath *indexPath in [diff removedIndexPaths]) {
    offset += CGRectGetWidth(oldLayoutAttributes[indexPath].bounds);
    offset += self.options.menuItemSpacing;
  }
  for (NSIndexPath *indexPath in [diff addedIndexPaths]) {
    offset -= CGRectGetWidth(newLayoutAttributes[indexPath].bounds);
    offset -= self.options.menuItemSpacing;
  }

  self.collectionView.contentOffset = CGPointMake(oldContentOffset.x - offset, oldContentOffset.y);
  [self.collectionView layoutIfNeeded];

  if (self.state.kind == NEPagingStateKindScrolling) {
    id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
    id<NEPagingItem> upcomingPagingItem = self.state.upcomingPagingItem;
    CGFloat progress = self.state.progress;
    CGFloat distance = self.state.distance;
    NEPagingTransition *transition = [self calculateTransitionFrom:currentPagingItem to:upcomingPagingItem];
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGPoint newContentOffset = CGPointMake(contentOffset.x - (distance - transition.distance), contentOffset.y);
    self.state = [NEPagingState scrollingStateWithPagingItem:currentPagingItem
                                           upcomingPagingItem:upcomingPagingItem
                                                     progress:progress
                                         initialContentOffset:newContentOffset
                                                     distance:distance];
  }
}

- (NSArray<id<NEPagingItem>> *)generateItemsAround:(id<NEPagingItem>)pagingItem {
  NSMutableArray<id<NEPagingItem>> *items = [NSMutableArray arrayWithObject:pagingItem];
  id<NEPagingItem> previousItem = pagingItem;
  id<NEPagingItem> nextItem = pagingItem;
  CGFloat menuWidth = CGRectGetWidth(self.collectionView.bounds);

  CGFloat widthBefore = menuWidth;
  while (widthBefore > 0) {
    id<NEPagingItem> item = [self.dataSource pagingItemBeforePagingItem:previousItem];
    if (!item) {
      break;
    }
    widthBefore -= [self itemWidthForPagingItem:item];
    widthBefore -= self.options.menuItemSpacing;
    previousItem = item;
    [items insertObject:item atIndex:0];
  }

  CGFloat widthAfter = menuWidth + widthBefore;
  while (widthAfter > 0) {
    id<NEPagingItem> item = [self.dataSource pagingItemAfterPagingItem:nextItem];
    if (!item) {
      break;
    }
    widthAfter -= [self itemWidthForPagingItem:item];
    widthAfter -= self.options.menuItemSpacing;
    nextItem = item;
    [items addObject:item];
  }

  CGFloat remainingWidth = widthAfter;
  while (remainingWidth > 0) {
    id<NEPagingItem> item = [self.dataSource pagingItemBeforePagingItem:previousItem];
    if (!item) {
      break;
    }
    remainingWidth -= [self itemWidthForPagingItem:item];
    remainingWidth -= self.options.menuItemSpacing;
    previousItem = item;
    [items insertObject:item atIndex:0];
  }

  return [items copy];
}

- (CGFloat)itemWidthForPagingItem:(id<NEPagingItem>)pagingItem {
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  if (!currentPagingItem) {
    return self.options.estimatedItemWidth;
  }
  if ([currentPagingItem isEqualToPagingItem:pagingItem]) {
    return [self.sizeCache itemWidthSelectedForPagingItem:pagingItem];
  }
  return [self.sizeCache itemSizeForPagingItem:pagingItem];
}

- (void)configureSizeCacheFor:(id<NEPagingItem>)pagingItem {
  if (self.sizeDelegate) {
    self.sizeCache.implementsSizeDelegate = YES;
    __weak typeof(self) weakSelf = self;
    self.sizeCache.sizeForPagingItem = ^CGFloat(id<NEPagingItem> item, BOOL selected) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      return [strongSelf.sizeDelegate widthForPagingItem:item isSelected:selected];
    };
  }
}

- (BOOL)hasItemBefore:(nullable id<NEPagingItem>)pagingItem {
  return pagingItem ? [self.dataSource pagingItemBeforePagingItem:pagingItem] != nil : NO;
}

- (BOOL)hasItemAfter:(nullable id<NEPagingItem>)pagingItem {
  return pagingItem ? [self.dataSource pagingItemAfterPagingItem:pagingItem] != nil : NO;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:indexPath];
  NEPagingCell *cell = (NEPagingCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([pagingItem class])
                                                                                 forIndexPath:indexPath];
  BOOL selected = self.state.currentPagingItem ? [self.state.currentPagingItem isEqualToPagingItem:pagingItem] : NO;
  [cell setPagingItem:pagingItem selected:selected options:self.options];
  return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.visibleItems.items.count;
}

@end
