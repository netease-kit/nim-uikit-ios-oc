// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingViewController.h"
#import "NEPageViewController.h"
#import "NEPagingBorderView.h"
#import "NEPagingCollectionViewLayout.h"
#import "NEPagingController.h"
#import "NEPagingFiniteDataSource.h"
#import "NEPagingIndicatorView.h"
#import "NEPagingIndexItem.h"
#import "NEPagingOptions.h"
#import "NEPagingStaticDataSource.h"
#import "NEPagingTitleCell.h"
#import "NEPagingView.h"

typedef NS_ENUM(NSInteger, NEPagingDataSourceReferenceKind) {
  NEPagingDataSourceReferenceKindNone = 0,
  NEPagingDataSourceReferenceKindStatic = 1,
  NEPagingDataSourceReferenceKindFinite = 2,
};

@interface NEPagingViewController () <UICollectionViewDelegate, NEPageViewControllerDataSource, NEPageViewControllerDelegate, NEPagingMenuDataSource, NEPagingMenuDelegate, PagingControllerSizeDelegate>

@property (nonatomic, copy, readwrite) NSArray<UIViewController *> *viewControllers;
@property (nonatomic, assign, readwrite) NSInteger currentIndex;
@property (nonatomic, strong, readwrite) NEPagingCollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) NEPageViewController *pageViewController;
@property (nonatomic, strong, readwrite) NEPagingOptions *options;
@property (nonatomic, strong) NEPagingController *pagingController;
@property (nonatomic, assign) BOOL didLayoutSubviews;
@property (nonatomic, assign) NEPagingDataSourceReferenceKind dataSourceReferenceKind;
@property (nonatomic, strong, nullable) NEPagingStaticDataSource *staticDataSource;
@property (nonatomic, strong, nullable) NEPagingFiniteDataSource *finiteDataSource;

@end

@implementation NEPagingViewController

- (instancetype)init {
  return [self initWithOptions:nil viewControllers:@[]];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [self initWithOptions:nil viewControllers:@[]];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers {
  return [self initWithOptions:nil viewControllers:viewControllers];
}

- (instancetype)initWithOptions:(NEPagingOptions *)options
                viewControllers:(NSArray<UIViewController *> *)viewControllers {
  NEPagingOptions *resolvedOptions = [options copy] ?: [[NEPagingOptions alloc] init];
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _options = resolvedOptions;
    _pagingController = [[NEPagingController alloc] initWithOptions:resolvedOptions];
    _pageViewController = [[NEPageViewController alloc] initWithOptions:resolvedOptions];
    _collectionViewLayout = [[resolvedOptions.menuLayoutClass alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
    _collectionView.delegate = self;
    _collectionViewLayout.options = resolvedOptions;
    _viewControllers = @[];
    _currentIndex = -1;
    [self configurePagingController];
    [self registerClass:[NEPagingTitleCell class] forPagingItemType:[NEPagingIndexItem class]];
    [self configureDataSourceWithViewControllers:viewControllers ?: @[]];
  }
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [self initWithOptions:nil viewControllers:@[]];
}

- (NEPagingState *)state {
  return self.pagingController.state;
}

- (NEPagingItems *)visibleItems {
  return self.pagingController.visibleItems;
}

- (void)loadView {
  self.view = [[NEPagingView alloc] initWithOptions:self.options
                                     collectionView:self.collectionView
                                           pageView:self.pageViewController.view];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addChildViewController:self.pageViewController];
  [(NEPagingView *)self.view configure];
  [self.pageViewController didMoveToParentViewController:self];
  self.pageViewController.delegate = self;
  self.pageViewController.dataSource = self;
  [self configureContentInteraction];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (!self.didLayoutSubviews) {
    self.didLayoutSubviews = YES;
    [self.pagingController viewAppeared];
  }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
    [self.pagingController transitionSize];
  } completion:nil];
}

- (void)setDataSource:(id<NEPagingViewControllerDataSource>)dataSource {
  _dataSource = dataSource;
  [self configureFiniteDataSource];
}

- (void)setInfiniteDataSource:(id<NEPagingViewControllerInfiniteDataSource>)infiniteDataSource {
  _infiniteDataSource = infiniteDataSource;
  [self reloadCurrentIndex];
}

- (void)setSizeDelegate:(id<NEPagingViewControllerSizeDelegate>)sizeDelegate {
  _sizeDelegate = sizeDelegate;
  self.pagingController.sizeDelegate = sizeDelegate ? self : nil;
}

- (NEPagingMenuItemSize *)menuItemSize {
  return self.options.menuItemSize;
}

- (void)setMenuItemSize:(NEPagingMenuItemSize *)menuItemSize {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuItemSize = menuItemSize ?: [NEPagingMenuItemSize sizeToFitMinWidth:150 height:40];
  }];
}

- (CGFloat)menuItemSpacing {
  return self.options.menuItemSpacing;
}

- (void)setMenuItemSpacing:(CGFloat)menuItemSpacing {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuItemSpacing = menuItemSpacing;
  }];
}

- (CGFloat)menuItemLabelSpacing {
  return self.options.menuItemLabelSpacing;
}

- (void)setMenuItemLabelSpacing:(CGFloat)menuItemLabelSpacing {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuItemLabelSpacing = menuItemLabelSpacing;
  }];
}

- (UIEdgeInsets)menuInsets {
  return self.options.menuInsets;
}

- (void)setMenuInsets:(UIEdgeInsets)menuInsets {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuInsets = menuInsets;
  }];
}

- (NEPagingMenuHorizontalAlignment)menuHorizontalAlignment {
  return self.options.menuHorizontalAlignment;
}

- (void)setMenuHorizontalAlignment:(NEPagingMenuHorizontalAlignment)menuHorizontalAlignment {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuHorizontalAlignment = menuHorizontalAlignment;
  }];
}

- (NEPagingMenuPosition)menuPosition {
  return self.options.menuPosition;
}

- (void)setMenuPosition:(NEPagingMenuPosition)menuPosition {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuPosition = menuPosition;
  }];
}

- (NEPagingMenuTransition)menuTransition {
  return self.options.menuTransition;
}

- (void)setMenuTransition:(NEPagingMenuTransition)menuTransition {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuTransition = menuTransition;
  }];
}

- (PagingMenuInteraction)menuInteraction {
  return self.options.menuInteraction;
}

- (void)setMenuInteraction:(PagingMenuInteraction)menuInteraction {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuInteraction = menuInteraction;
  }];
}

- (Class)menuLayoutClass {
  return self.options.menuLayoutClass;
}

- (void)setMenuLayoutClass:(Class)menuLayoutClass {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuLayoutClass = menuLayoutClass ?: [NEPagingCollectionViewLayout class];
  }];
}

- (NEPagingSelectedScrollPosition)selectedScrollPosition {
  return self.options.selectedScrollPosition;
}

- (void)setSelectedScrollPosition:(NEPagingSelectedScrollPosition)selectedScrollPosition {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.selectedScrollPosition = selectedScrollPosition;
  }];
}

- (NEPagingIndicatorOptions *)indicatorOptions {
  return self.options.indicatorOptions;
}

- (void)setIndicatorOptions:(NEPagingIndicatorOptions *)indicatorOptions {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.indicatorOptions = indicatorOptions ?: [NEPagingIndicatorOptions hiddenOptions];
  }];
}

- (Class)indicatorClass {
  return self.options.indicatorClass;
}

- (void)setIndicatorClass:(Class)indicatorClass {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.indicatorClass = indicatorClass ?: [NEPagingIndicatorView class];
  }];
}

- (UIColor *)indicatorColor {
  return self.options.indicatorColor;
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.indicatorColor = indicatorColor ?: [UIColor clearColor];
  }];
}

- (NEPagingBorderOptions *)borderOptions {
  return self.options.borderOptions;
}

- (void)setBorderOptions:(NEPagingBorderOptions *)borderOptions {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.borderOptions = borderOptions ?: [NEPagingBorderOptions hiddenOptions];
  }];
}

- (Class)borderClass {
  return self.options.borderClass;
}

- (void)setBorderClass:(Class)borderClass {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.borderClass = borderClass ?: [NEPagingBorderView class];
  }];
}

- (UIColor *)borderColor {
  return self.options.borderColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.borderColor = borderColor ?: [UIColor clearColor];
  }];
}

- (BOOL)includeSafeAreaInsets {
  return self.options.includeSafeAreaInsets;
}

- (void)setIncludeSafeAreaInsets:(BOOL)includeSafeAreaInsets {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.includeSafeAreaInsets = includeSafeAreaInsets;
  }];
}

- (UIFont *)font {
  return self.options.font;
}

- (void)setFont:(UIFont *)font {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.font = font ?: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
  }];
}

- (UIFont *)selectedFont {
  return self.options.selectedFont;
}

- (void)setSelectedFont:(UIFont *)selectedFont {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.selectedFont = selectedFont ?: options.font;
  }];
}

- (UIColor *)textColor {
  return self.options.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.textColor = textColor ?: [UIColor blackColor];
  }];
}

- (UIColor *)selectedTextColor {
  return self.options.selectedTextColor;
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.selectedTextColor = selectedTextColor ?: options.textColor;
  }];
}

- (UIColor *)backgroundColor {
  return self.options.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.backgroundColor = backgroundColor ?: [UIColor clearColor];
  }];
}

- (UIColor *)selectedBackgroundColor {
  return self.options.selectedBackgroundColor;
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.selectedBackgroundColor = selectedBackgroundColor ?: [UIColor clearColor];
  }];
}

- (UIColor *)menuBackgroundColor {
  return self.options.menuBackgroundColor;
}

- (void)setMenuBackgroundColor:(UIColor *)menuBackgroundColor {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.menuBackgroundColor = menuBackgroundColor ?: [UIColor whiteColor];
  }];
}

- (NEPagingNavigationOrientation)contentNavigationOrientation {
  return self.options.contentNavigationOrientation;
}

- (void)setContentNavigationOrientation:(NEPagingNavigationOrientation)contentNavigationOrientation {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.contentNavigationOrientation = contentNavigationOrientation;
  }];
}

- (PagingContentInteraction)contentInteraction {
  return self.options.contentInteraction;
}

- (void)setContentInteraction:(PagingContentInteraction)contentInteraction {
  [self mutateOptions:^(NEPagingOptions *options) {
    options.contentInteraction = contentInteraction;
  }];
  [self configureContentInteraction];
}

- (void)reloadMenu {
  NSArray<id<NEPagingItem>> *updatedItems = [self refreshCurrentDataSourceItems];
  id<NEPagingItem> previouslySelected = self.state.currentPagingItem;
  id<NEPagingItem> targetItem = [self matchingItemForPagingItem:previouslySelected withinItems:updatedItems] ?: updatedItems.firstObject;
  if (targetItem) {
    [self.pagingController reloadMenuAround:targetItem];
  } else {
    [self.pagingController removeAll];
  }
  [self reloadCurrentIndex];
}

- (void)reloadData {
  NSArray<id<NEPagingItem>> *updatedItems = [self refreshCurrentDataSourceItems];
  id<NEPagingItem> previouslySelected = self.state.currentPagingItem;
  id<NEPagingItem> targetItem = [self matchingItemForPagingItem:previouslySelected withinItems:updatedItems] ?: updatedItems.firstObject;
  if (targetItem) {
    [self.pagingController reloadDataAround:targetItem];
  } else {
    [self.pagingController removeAll];
  }
  [self reloadCurrentIndex];
}

- (void)reloadDataAround:(id<NEPagingItem>)pagingItem {
  [self refreshCurrentDataSourceItems];
  [self.pagingController reloadDataAround:pagingItem];
  [self updateCurrentIndexForPagingItem:pagingItem];
}

- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated {
  [self.pagingController selectPagingItem:pagingItem animated:animated];
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated {
  id<NEPagingItem> pagingItem = [self pagingItemAtIndex:index];
  if (pagingItem) {
    [self.pagingController selectPagingItem:pagingItem animated:animated];
  }
}

- (void)registerClass:(Class)cellClass forPagingItemType:(Class)pagingItemType {
  [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(pagingItemType)];
}

- (void)registerNib:(UINib *)nib forPagingItemType:(Class)pagingItemType {
  [self.collectionView registerNib:nib forCellWithReuseIdentifier:NSStringFromClass(pagingItemType)];
}

- (void)configurePagingController {
  self.pagingController.collectionView = self.collectionView;
  self.pagingController.collectionViewLayout = self.collectionViewLayout;
  self.pagingController.dataSource = self;
  self.pagingController.delegate = self;
  self.pagingController.options = self.options;
}

- (NSArray<id<NEPagingItem>> *)itemsForFiniteDataSource {
  NSInteger numberOfItems = [self.dataSource numberOfViewControllersInPagingViewController:self];
  NSMutableArray<id<NEPagingItem>> *items = [NSMutableArray array];
  NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
  for (NSInteger index = 0; index < numberOfItems; index++) {
    id<NEPagingItem> item = [self.dataSource pagingViewController:self pagingItemAtIndex:index];
    UIViewController *viewController = [self.dataSource pagingViewController:self viewControllerAtIndex:index];
    if (item) {
      [items addObject:item];
    }
    if (viewController) {
      [viewControllers addObject:viewController];
    }
  }
  self.viewControllers = [viewControllers copy];
  return [items copy];
}

- (void)configureFiniteDataSource {
  if (!self.dataSource) {
    self.finiteDataSource = nil;
    if (self.dataSourceReferenceKind == NEPagingDataSourceReferenceKindFinite) {
      self.dataSourceReferenceKind = NEPagingDataSourceReferenceKindNone;
      self.infiniteDataSource = nil;
    }
    return;
  }

  NEPagingFiniteDataSource *dataSource = [[NEPagingFiniteDataSource alloc] init];
  dataSource.items = [self itemsForFiniteDataSource];
  __weak typeof(self) weakSelf = self;
  dataSource.viewControllerForIndex = ^UIViewController * _Nullable(NSInteger index) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    return [strongSelf.dataSource pagingViewController:strongSelf viewControllerAtIndex:index];
  };

  self.finiteDataSource = dataSource;
  self.staticDataSource = nil;
  self.dataSourceReferenceKind = NEPagingDataSourceReferenceKindFinite;
  _infiniteDataSource = dataSource;

  id<NEPagingItem> firstItem = dataSource.items.firstObject;
  if (firstItem) {
    [self.pagingController selectPagingItem:firstItem animated:NO];
    [self updateCurrentIndexForPagingItem:firstItem];
  }
}

- (void)configureDataSourceWithViewControllers:(NSArray<UIViewController *> *)viewControllers {
  self.viewControllers = [viewControllers copy] ?: @[];
  self.staticDataSource = [[NEPagingStaticDataSource alloc] initWithViewControllers:self.viewControllers];
  self.finiteDataSource = nil;
  self.dataSourceReferenceKind = NEPagingDataSourceReferenceKindStatic;
  _infiniteDataSource = self.staticDataSource;
  id<NEPagingItem> pagingItem = self.staticDataSource.items.firstObject;
  if (pagingItem) {
    [self.pagingController selectPagingItem:pagingItem animated:NO];
    [self updateCurrentIndexForPagingItem:pagingItem];
  }
}

- (NSArray<id<NEPagingItem>> *)refreshCurrentDataSourceItems {
  switch (self.dataSourceReferenceKind) {
    case NEPagingDataSourceReferenceKindStatic:
      [self.staticDataSource reloadItems];
      self.viewControllers = self.staticDataSource.viewControllers ?: self.viewControllers;
      return self.staticDataSource.items;
    case NEPagingDataSourceReferenceKindFinite:
      self.finiteDataSource.items = [self itemsForFiniteDataSource];
      return self.finiteDataSource.items;
    case NEPagingDataSourceReferenceKindNone:
      return @[];
  }
}

- (id<NEPagingItem>)pagingItemAtIndex:(NSInteger)index {
  switch (self.dataSourceReferenceKind) {
    case NEPagingDataSourceReferenceKindStatic:
      return (index >= 0 && index < (NSInteger)self.staticDataSource.items.count) ? self.staticDataSource.items[index] : nil;
    case NEPagingDataSourceReferenceKindFinite:
      return (index >= 0 && index < (NSInteger)self.finiteDataSource.items.count) ? self.finiteDataSource.items[index] : nil;
    case NEPagingDataSourceReferenceKindNone:
      return nil;
  }
}

- (id<NEPagingItem>)matchingItemForPagingItem:(id<NEPagingItem>)pagingItem withinItems:(NSArray<id<NEPagingItem>> *)items {
  if (!pagingItem) {
    return nil;
  }
  for (id<NEPagingItem> item in items) {
    if ([item isEqualToPagingItem:pagingItem]) {
      return item;
    }
  }
  return nil;
}

- (void)updateCurrentIndexForPagingItem:(id<NEPagingItem>)pagingItem {
  NSArray<id<NEPagingItem>> *items = nil;
  switch (self.dataSourceReferenceKind) {
    case NEPagingDataSourceReferenceKindStatic:
      items = self.staticDataSource.items;
      break;
    case NEPagingDataSourceReferenceKindFinite:
      items = self.finiteDataSource.items;
      break;
    case NEPagingDataSourceReferenceKindNone:
      items = @[];
      break;
  }

  __block NSInteger index = -1;
  [items enumerateObjectsUsingBlock:^(id<NEPagingItem> item, NSUInteger idx, BOOL *stop) {
    if ([item isEqualToPagingItem:pagingItem]) {
      index = (NSInteger)idx;
      *stop = YES;
    }
  }];
  self.currentIndex = index;
}

- (void)reloadCurrentIndex {
  if (self.state.currentPagingItem) {
    [self updateCurrentIndexForPagingItem:self.state.currentPagingItem];
  } else {
    self.currentIndex = -1;
  }
}

- (void)configureContentInteraction {
  self.pageViewController.scrollView.scrollEnabled = self.contentInteraction == PagingContentInteractionScrolling;
}

- (void)mutateOptions:(void (^)(NEPagingOptions *options))mutation {
  Class oldLayoutClass = self.options.menuLayoutClass;
  if (mutation) {
    mutation(self.options);
  }

  if (self.options.menuLayoutClass != oldLayoutClass) {
    self.collectionViewLayout = [[self.options.menuLayoutClass alloc] init];
    self.collectionViewLayout.options = self.options;
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:NO];
    self.pagingController.collectionViewLayout = self.collectionViewLayout;
  } else {
    self.collectionViewLayout.options = self.options;
  }

  self.pageViewController.options = self.options;
  self.pagingController.options = self.options;
  if (self.isViewLoaded) {
    ((NEPagingView *)self.view).options = self.options;
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self.pagingController menuScrolled];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  id<NEPagingItem> pagingItem = [self.visibleItems pagingItemForIndexPath:indexPath];
  if ([self.delegate respondsToSelector:@selector(pagingViewController:didSelectItem:)]) {
    [self.delegate pagingViewController:self didSelectItem:pagingItem];
  }
  [self.pagingController selectIndexPath:indexPath animated:YES];
}

- (UIViewController *)pageViewController:(NEPageViewController *)pageViewController
                viewControllerBeforeViewController:(UIViewController *)viewController {
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  id<NEPagingItem> pagingItem = [self.infiniteDataSource pagingViewController:self itemBefore:currentPagingItem];
  return pagingItem ? [self.infiniteDataSource pagingViewController:self viewControllerForItem:pagingItem] : nil;
}

- (UIViewController *)pageViewController:(NEPageViewController *)pageViewController
                 viewControllerAfterViewController:(UIViewController *)viewController {
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  id<NEPagingItem> pagingItem = [self.infiniteDataSource pagingViewController:self itemAfter:currentPagingItem];
  return pagingItem ? [self.infiniteDataSource pagingViewController:self viewControllerForItem:pagingItem] : nil;
}

- (void)pageViewController:(NEPageViewController *)pageViewController
           isScrollingFrom:(UIViewController *)startingViewController
 destinationViewController:(UIViewController *)destinationViewController
                  progress:(CGFloat)progress {
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  if (!currentPagingItem) {
    return;
  }
  [self.pagingController contentScrolledProgress:progress];
  if ([self.delegate respondsToSelector:@selector(pagingViewController:isScrollingFromItem:toItem:startingViewController:destinationViewController:progress:)]) {
    [self.delegate pagingViewController:self
                   isScrollingFromItem:currentPagingItem
                                toItem:self.state.upcomingPagingItem
                startingViewController:startingViewController
             destinationViewController:destinationViewController
                              progress:progress];
  }
}

- (void)pageViewController:(NEPageViewController *)pageViewController
     willStartScrollingFrom:(UIViewController *)startingViewController
  destinationViewController:(UIViewController *)destinationViewController {
  if (self.state.upcomingPagingItem &&
      [self.delegate respondsToSelector:@selector(pagingViewController:willScrollToItem:startingViewController:destinationViewController:)]) {
    [self.delegate pagingViewController:self
                       willScrollToItem:self.state.upcomingPagingItem
                 startingViewController:startingViewController
              destinationViewController:destinationViewController];
  }
}

- (void)pageViewController:(NEPageViewController *)pageViewController
    didFinishScrollingFrom:(UIViewController *)startingViewController
 destinationViewController:(UIViewController *)destinationViewController
   transitionSuccessful:(BOOL)transitionSuccessful {
  if (transitionSuccessful) {
    [self.pagingController contentFinishedScrolling];
  }
  id<NEPagingItem> currentPagingItem = self.state.currentPagingItem;
  if (currentPagingItem &&
      [self.delegate respondsToSelector:@selector(pagingViewController:didScrollToItem:startingViewController:destinationViewController:transitionSuccessful:)]) {
    [self.delegate pagingViewController:self
                        didScrollToItem:currentPagingItem
                 startingViewController:startingViewController
              destinationViewController:destinationViewController
                 transitionSuccessful:transitionSuccessful];
  }
  [self reloadCurrentIndex];
}

- (id<NEPagingItem>)pagingItemBeforePagingItem:(id<NEPagingItem>)pagingItem {
  return [self.infiniteDataSource pagingViewController:self itemBefore:pagingItem];
}

- (id<NEPagingItem>)pagingItemAfterPagingItem:(id<NEPagingItem>)pagingItem {
  return [self.infiniteDataSource pagingViewController:self itemAfter:pagingItem];
}

- (CGFloat)widthForPagingItem:(id<NEPagingItem>)pagingItem isSelected:(BOOL)isSelected {
  return [self.sizeDelegate pagingViewController:self widthForPagingItem:pagingItem isSelected:isSelected];
}

- (void)selectContentWithPagingItem:(id<NEPagingItem>)pagingItem
                          direction:(PagingDirection *)direction
                           animated:(BOOL)animated {
  if (!self.infiniteDataSource) {
    return;
  }
  if (direction.kind == PagingDirectionKindForward && direction.isSibling) {
    [self.pageViewController selectNextAnimated:animated];
    return;
  }
  if (direction.kind == PagingDirectionKindReverse && direction.isSibling) {
    [self.pageViewController selectPreviousAnimated:animated];
    return;
  }
  UIViewController *viewController = [self.infiniteDataSource pagingViewController:self viewControllerForItem:pagingItem];
  NEPageViewDirection pageDirection = NEPageViewDirectionNone;
  switch (direction.kind) {
    case PagingDirectionKindForward:
      pageDirection = NEPageViewDirectionForward;
      break;
    case PagingDirectionKindReverse:
      pageDirection = NEPageViewDirectionReverse;
      break;
    case PagingDirectionKindNone:
      pageDirection = NEPageViewDirectionNone;
      break;
  }
  [self.pageViewController selectViewController:viewController direction:pageDirection animated:animated];
}

- (void)removeContent {
  [self.pageViewController removeAll];
}

@end
