// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingMenuView.h"
#import "NEPagingCollectionViewLayout.h"
#import "NEPagingController.h"
#import "NEPagingOptions.h"
#import "UIView+constraints.h"

@interface NEPagingMenuView () <UICollectionViewDelegate>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) NEPagingCollectionViewLayout *collectionViewLayout;
@property (nonatomic, strong) NEPagingController *pagingController;

@end

@implementation NEPagingMenuView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _options = [[NEPagingOptions alloc] init];
    _collectionViewLayout = [[_options.menuLayoutClass alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
    _pagingController = [[NEPagingController alloc] initWithOptions:_options];
    [self configure];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _options = [[NEPagingOptions alloc] init];
    _collectionViewLayout = [[_options.menuLayoutClass alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
    _pagingController = [[NEPagingController alloc] initWithOptions:_options];
    [self configure];
  }
  return self;
}

- (NEPagingState *)state {
  return self.pagingController.state;
}

- (NEPagingItems *)visibleItems {
  return self.pagingController.visibleItems;
}

- (void)setDelegate:(id<NEPagingMenuDelegate>)delegate {
  _delegate = delegate;
  self.pagingController.delegate = delegate;
}

- (void)setDataSource:(id<NEPagingMenuDataSource>)dataSource {
  _dataSource = dataSource;
  self.pagingController.dataSource = dataSource;
}

- (void)setOptions:(NEPagingOptions *)options {
  NEPagingOptions *oldValue = _options;
  _options = options ?: [[NEPagingOptions alloc] init];
  if (_options.menuLayoutClass != oldValue.menuLayoutClass) {
    self.collectionViewLayout = [[_options.menuLayoutClass alloc] init];
    self.collectionViewLayout.options = _options;
    [self.collectionView setCollectionViewLayout:self.collectionViewLayout animated:NO];
    self.pagingController.collectionViewLayout = self.collectionViewLayout;
  } else {
    self.collectionViewLayout.options = _options;
  }
  self.pagingController.options = _options;
}

- (void)configure {
  self.collectionView.backgroundColor = self.options.menuBackgroundColor;
  self.collectionView.delegate = self;
  [self addSubview:self.collectionView];
  [self constrainToEdges:self.collectionView];
  self.pagingController.collectionView = self.collectionView;
  self.pagingController.collectionViewLayout = self.collectionViewLayout;
}

- (void)viewAppeared {
  [self.pagingController viewAppeared];
}

- (void)transitionSize {
  [self.pagingController transitionSize];
}

- (void)contentScrolledProgress:(CGFloat)progress {
  [self.pagingController contentScrolledProgress:progress];
}

- (void)contentFinishedScrolling {
  [self.pagingController contentFinishedScrolling];
}

- (void)reloadAround:(id<NEPagingItem>)pagingItem {
  [self.pagingController reloadMenuAround:pagingItem];
}

- (void)selectPagingItem:(id<NEPagingItem>)pagingItem animated:(BOOL)animated {
  [self.pagingController selectPagingItem:pagingItem animated:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self.pagingController menuScrolled];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  [self.pagingController selectIndexPath:indexPath animated:YES];
}

@end
