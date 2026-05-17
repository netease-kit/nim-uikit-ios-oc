// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PhotoBrowserBigImgBackView.h"
#import "PhotoBrowserCell.h"
#import "PhotoBrowserFlowLayout.h"
#import <NEChatKitOC/NEConstant.h>

@interface PhotoBrowserBigImgBackView () <UICollectionViewDelegate, UICollectionViewDataSource, CAAnimationDelegate>

@property (nonatomic, assign) CFTimeInterval duration;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *urlArray;
@property (nonatomic, copy, readwrite) NSArray<UIImage *> *imgArray;

@end

@implementation PhotoBrowserBigImgBackView

- (instancetype)initWithUrlArr:(NSArray<NSString *> *)urlArr number:(NSInteger)number {
  self = [super initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight)];
  if (self) {
    _duration = 0.3;
    self.backgroundColor = UIColor.blackColor;
    [self showUrlScroll:urlArr number:number];
  }
  return self;
}

- (instancetype)initWithImgArr:(NSArray<UIImage *> *)imgArr number:(NSInteger)number {
  self = [super initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight)];
  if (self) {
    _duration = 0.3;
    self.backgroundColor = UIColor.blackColor;
    [self showImages:imgArr number:number];
  }
  return self;
}

- (void)showUrlScroll:(NSArray<NSString *> *)urlArr number:(NSInteger)number {
  self.urlArray = [urlArr copy];
  [self addSubview:self.collectionView];
  self.collectionView.frame = CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight);
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  if (self.urlArray.count > 0) {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:number inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  }
  [self setPageControlTotal:self.urlArray.count current:number];
}

- (void)showImages:(NSArray<UIImage *> *)images number:(NSInteger)number {
  self.imgArray = [images copy];
  [self addSubview:self.collectionView];
  self.collectionView.frame = CGRectMake(0, 0, NEConstant.screenWidth, NEConstant.screenHeight);
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  if (self.imgArray.count > 0) {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:number inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  }
  [self setPageControlTotal:self.imgArray.count current:number];
}

- (void)setPageControlTotal:(NSInteger)total current:(NSInteger)current {
  [self addSubview:self.pageControl];
  self.pageControl.frame = CGRectMake(0, NEConstant.screenHeight - 80, NEConstant.screenWidth, 30);
  self.pageControl.numberOfPages = total;
  self.pageControl.currentPage = current;
  self.pageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
  self.pageControl.pageIndicatorTintColor = UIColor.lightGrayColor;
  self.pageControl.hidesForSinglePage = YES;
}

- (NSInteger)currentIndex {
  return (NSInteger)(self.collectionView.contentOffset.x / NEConstant.screenWidth);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.urlArray.count > 0 ? self.urlArray.count : self.imgArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  PhotoBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
  if (self.urlArray.count > 0) {
    cell.imgUrl = self.urlArray[indexPath.item];
  } else {
    cell.image = self.imgArray[indexPath.item];
  }
  __weak typeof(self) weakSelf = self;
  cell.backRemoveCallBack = ^{
    [weakSelf backRemoveAnimation:weakSelf.duration];
  };
  cell.tapMoveCallBack = ^(UIView *view) {
    [weakSelf removeAnimation:view];
  };
  cell.changeAlphaCallBack = ^(CGFloat alpha) {
    [weakSelf changeBackAlpha:alpha];
  };
  return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (scrollView == self.collectionView) {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset];
    if (indexPath) {
      self.pageControl.currentPage = indexPath.item;
    }
  }
}

- (void)dismissPhotoBrowser {
  PhotoBrowserCell *cell = (PhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self currentIndex] inSection:0]];
  if ([cell isKindOfClass:[PhotoBrowserCell class]]) {
    [self removeAnimation:cell.imgView];
  }
}

- (void)transformAnimation {
  [self.collectionView reloadData];
  [self.collectionView setNeedsLayout];
  [self.collectionView layoutIfNeeded];
  NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset];
  if (!indexPath) {
    return;
  }
  PhotoBrowserCell *cell = (PhotoBrowserCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
  if (![cell isKindOfClass:[PhotoBrowserCell class]]) {
    return;
  }
  [self showAnimation];
  [self transformScaleAnimationFromValue:0.3 toValue:1.0 duration:0.3 view:cell.imgView];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.collectionView reloadData];
  });
}

- (void)removeAnimation:(UIView *)imgView {
  if (imgView.frame.size.height <= NEConstant.screenHeight) {
    [self transformScaleAnimationFromValue:1.0 toValue:0.3 duration:0.3 view:imgView];
  }
  [self backRemoveAnimation:self.duration];
}

- (void)transformScaleAnimationFromValue:(CGFloat)fromValue toValue:(CGFloat)toValue duration:(CFTimeInterval)duration view:(UIView *)view {
  CABasicAnimation *scale = [CABasicAnimation animation];
  scale.keyPath = @"transform.scale";
  scale.fromValue = @(fromValue);
  scale.toValue = @(toValue);
  scale.duration = duration;
  scale.fillMode = kCAFillModeForwards;
  scale.removedOnCompletion = NO;
  [view.layer addAnimation:scale forKey:nil];
}

- (void)showAnimation {
  CAKeyframeAnimation *backAnimation = [CAKeyframeAnimation animation];
  backAnimation.keyPath = @"opacity";
  backAnimation.duration = self.duration;
  backAnimation.values = @[@0.10f, @0.40f, @0.80f, @1.0f];
  backAnimation.keyTimes = @[@0.1, @0.2, @0.3, @0.4];
  backAnimation.fillMode = kCAFillModeForwards;
  backAnimation.removedOnCompletion = NO;
  [self.layer addAnimation:backAnimation forKey:nil];
}

- (void)backRemoveAnimation:(CFTimeInterval)duration {
  CAKeyframeAnimation *backAnimation = [CAKeyframeAnimation animation];
  backAnimation.delegate = self;
  backAnimation.keyPath = @"opacity";
  backAnimation.duration = duration;
  backAnimation.values = @[@0.90f, @0.60f, @0.30f, @0.0f];
  backAnimation.keyTimes = @[@0.1, @0.2, @0.3, @0.4];
  backAnimation.fillMode = kCAFillModeForwards;
  backAnimation.removedOnCompletion = NO;
  [self.layer addAnimation:backAnimation forKey:nil];
}

- (void)changeBackAlpha:(CGFloat)alpha {
  self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:alpha];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  if ([anim isKindOfClass:[CAKeyframeAnimation class]] && flag) {
    !self.dismissCallBack ?: self.dismissCallBack();
  }
}

- (UICollectionView *)collectionView {
  if (!_collectionView) {
    PhotoBrowserFlowLayout *flowLayout = [[PhotoBrowserFlowLayout alloc] init];
    flowLayout.sectionHeadersPinToVisibleBounds = YES;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake(floor(NEConstant.screenWidth), NEConstant.screenHeight);
    flowLayout.sectionInset = UIEdgeInsetsZero;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.scrollEnabled = YES;
    _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _collectionView.alwaysBounceVertical = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    [_collectionView registerClass:[PhotoBrowserCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
  }
  return _collectionView;
}

- (UIPageControl *)pageControl {
  if (!_pageControl) {
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.userInteractionEnabled = NO;
    _pageControl.hidden = YES;
  }
  return _pageControl;
}

@end
