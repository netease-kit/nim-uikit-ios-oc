// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabPagingMenuViewController.h"

#import "UIView+constraints.h"

@interface NETabPagingMenuViewController () <PagingMenuViewDataSource, PagingMenuViewDelegate, UIScrollViewDelegate>

@property (nonatomic, copy, nullable) dispatch_block_t fireInvalidateLayout;
@property (nonatomic, strong, readwrite) NETabPagingMenuView *menuView;

@end

@implementation NETabPagingMenuViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _menuView = [[NETabPagingMenuView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    _menuView.backgroundColor = UIColor.clearColor;
    _menuView.showsHorizontalScrollIndicator = NO;
    _menuView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return self;
}

- (PagingMenuFocusView *)focusView {
  return self.menuView.focusView;
}

- (CGPoint)focusPointerOffset {
  return self.menuView.focusView.center;
}

- (CGFloat)percentOffset {
  if (self.menuView.contentSize.width <= 0) {
    return 0;
  }
  return self.menuView.contentOffset.x / self.menuView.contentSize.width;
}

- (NETabPagingMenuViewAlignment)cellAlignment {
  return self.menuView.cellAlignment;
}

- (void)setCellAlignment:(NETabPagingMenuViewAlignment)cellAlignment {
  self.menuView.cellAlignment = cellAlignment;
}

- (CGFloat)cellSpacing {
  return self.menuView.cellSpacing;
}

- (void)setCellSpacing:(CGFloat)cellSpacing {
  self.menuView.cellSpacing = cellSpacing;
}

- (UIEdgeInsets)contentInset {
  return self.menuView.contentInset;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  self.menuView.contentInset = contentInset;
}

- (NSArray<NEPagingMenuViewCell *> *)visibleCells {
  return self.menuView.visibleCells;
}

- (NEPagingMenuViewCell *)currentFocusedCell {
  return self.currentFocusedIndex ? [self.menuView cellForItemAtIndex:self.currentFocusedIndex.integerValue] : nil;
}

- (NSNumber *)currentFocusedIndex {
  return self.menuView.focusView.selectedIndex;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.menuView.menuDelegate = self;
  self.menuView.delegate = self;
  self.menuView.dataSource = self;
  [self.view addSubview:self.menuView];
  [self.view constrainToEdges:self.menuView];

  __weak typeof(self) weakSelf = self;
  self.fireInvalidateLayout = ^{
    [weakSelf invalidateMenuViewLayout];
  };
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (self.fireInvalidateLayout) {
    self.fireInvalidateLayout();
    self.fireInvalidateLayout = nil;
  }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  __weak typeof(self) weakSelf = self;
  self.fireInvalidateLayout = ^{
    [weakSelf invalidateMenuViewLayout];
  };
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
  [self scrollToIndex:index percent:0 animated:animated];
}

- (void)scrollToIndex:(NSInteger)index percent:(CGFloat)percent animated:(BOOL)animated {
  if (animated) {
    [self.menuView scrollToIndex:index completion:^(BOOL finished) {
      if (finished &&
          percent == 0 &&
          [self.delegate respondsToSelector:@selector(menuViewController:focusViewDidEndTransition:)]) {
        [self.delegate menuViewController:self focusViewDidEndTransition:self.menuView.focusView];
      }
    }];
    return;
  }

  [self.menuView scrollToIndex:index percent:percent];
  if (percent == 0 &&
      [self.delegate respondsToSelector:@selector(menuViewController:focusViewDidEndTransition:)]) {
    [self.delegate menuViewController:self focusViewDidEndTransition:self.menuView.focusView];
  }
}

- (nullable NEPagingMenuViewCell *)cellForItemAtIndex:(NSInteger)index {
  return [self.menuView cellForItemAtIndex:index];
}

- (void)registerFocusView:(UIView *)view isBehindCell:(BOOL)isBehindCell {
  [self.menuView registerFocusView:view isBehindCell:isBehindCell];
}

- (void)registerFocusViewNib:(UINib *)nib isBehindCell:(BOOL)isBehindCell {
  [self.menuView registerFocusViewNib:nib isBehindCell:isBehindCell];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
  [self.menuView registerNib:nib withIdentifier:identifier];
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
  [self.menuView registerClass:cellClass withIdentifier:identifier];
}

- (NEPagingMenuViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier
                                                        forIndex:(NSInteger)index {
  return [self.menuView dequeueWithIdentifier:identifier];
}

- (void)reloadData {
  [self reloadDataWithPreferredFocusIndex:nil completionHandler:nil];
}

- (void)reloadDataWithPreferredFocusIndex:(NSNumber *)preferredFocusIndex
                        completionHandler:(NEPagingKitAnimationCompletion)completionHandler {
  NSInteger selectedIndex = preferredFocusIndex ? preferredFocusIndex.integerValue :
      (self.currentFocusedIndex ? self.currentFocusedIndex.integerValue : 0);
  __weak typeof(self) weakSelf = self;
  self.fireInvalidateLayout = ^{
    [weakSelf.menuView reloadDataWithIndex:selectedIndex completion:completionHandler];
  };
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
}

- (void)invalidateLayout {
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
  [self invalidateMenuViewLayout];
}

- (void)invalidateMenuViewLayout {
  [self.menuView invalidateLayout];
  if (self.menuView.focusView.selectedIndex) {
    [self scrollToIndex:self.menuView.focusView.selectedIndex.integerValue percent:0 animated:NO];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if ([self.delegate respondsToSelector:@selector(menuViewController:focusViewDidEndTransition:)]) {
    [self.delegate menuViewController:self focusViewDidEndTransition:self.menuView.focusView];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate &&
      [self.delegate respondsToSelector:@selector(menuViewController:focusViewDidEndTransition:)]) {
    [self.delegate menuViewController:self focusViewDidEndTransition:self.menuView.focusView];
  }
}

#pragma mark - PagingMenuViewDelegate

- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
           willDisplay:(NEPagingMenuViewCell *)cell
             forItemAt:(NSInteger)index {
  if ([self.delegate respondsToSelector:@selector(menuViewController:willDisplay:forItemAt:)]) {
    [self.delegate menuViewController:self willDisplay:cell forItemAt:index];
  }
}

- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
willAnimateFocusViewTo:(NSInteger)index
        withCoordinator:(PagingMenuFocusViewAnimationCoordinator *)coordinator {
  if ([self.delegate respondsToSelector:@selector(menuViewController:willAnimateFocusViewTo:withCoordinator:)]) {
    [self.delegate menuViewController:self willAnimateFocusViewTo:index withCoordinator:coordinator];
  }
}

- (void)pagingMenuView:(NETabPagingMenuView *)pagingMenuView didSelectItemAt:(NSInteger)index {
  NSInteger previousPage = self.menuView.focusView.selectedIndex.integerValue;
  [self.delegate menuViewController:self didSelect:index previousPage:previousPage];
  if (previousPage == index) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.menuView scrollToIndex:index completion:^(BOOL finished) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || !finished) {
      return;
    }
    if ([strongSelf.delegate respondsToSelector:@selector(menuViewController:focusViewDidEndTransition:)]) {
      [strongSelf.delegate menuViewController:strongSelf
                    focusViewDidEndTransition:strongSelf.menuView.focusView];
    }
  }];
}

#pragma mark - PagingMenuViewDataSource

- (NSInteger)numberOfItemForPagingMenuView {
  return [self.dataSource numberOfItemsForMenuViewController:self];
}

- (CGFloat)pagingMenuView:(NETabPagingMenuView *)pagingMenuView widthForItemAt:(NSInteger)index {
  return [self.dataSource menuViewController:self widthForItemAt:index];
}

- (NEPagingMenuViewCell *)pagingMenuView:(NETabPagingMenuView *)pagingMenuView
                           cellForItemAt:(NSInteger)index {
  return [self.dataSource menuViewController:self cellForItemAt:index];
}

@end
