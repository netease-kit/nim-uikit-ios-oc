// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "EmojiPageView.h"

@interface EmojiPageView () <UIScrollViewDelegate>

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSMutableArray *pages;
@property (nonatomic, assign) CGSize lastLayoutSize;
@property (nonatomic, assign) BOOL userScrolling;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation EmojiPageView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupControls];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupControls];
  }
  return self;
}

- (void)setupControls {
  _currentPage = 0;
  _pages = [NSMutableArray array];
  [self addSubview:self.scrollView];
}

- (UIScrollView *)scrollView {
  if (!_scrollView) {
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
  }
  return _scrollView;
}

- (void)scrollToPage:(NSInteger)page {
  BOOL animated = NO;
  if ([self.pageViewDelegate respondsToSelector:@selector(needScrollAnimation)]) {
    animated = [self.pageViewDelegate needScrollAnimation];
  }
  [self scrollToPage:page animated:animated];
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated {
  NSInteger targetPage = [self boundedPage:page];
  self.userScrolling = NO;
  self.currentPage = targetPage;
  [self loadPagesAroundPage:targetPage];
  [self setContentOffsetForPage:targetPage animated:animated];
  if (!animated) {
    [self raisePageIndexChangedDelegate];
  }
}

- (void)reloadData {
  [self reloadDataWithCurrentPage:self.currentPage];
}

- (void)reloadDataWithCurrentPage:(NSInteger)page {
  self.userScrolling = NO;
  for (id object in self.pages) {
    if ([object isKindOfClass:[UIView class]]) {
      [(UIView *)object removeFromSuperview];
    }
  }

  NSInteger pageCount = 0;
  if ([self.dataSource respondsToSelector:@selector(numberOfPages:)]) {
    pageCount = MAX(0, [self.dataSource numberOfPages:self]);
  }
  self.pages = [NSMutableArray arrayWithCapacity:(NSUInteger)pageCount];
  for (NSInteger index = 0; index < pageCount; index++) {
    [self.pages addObject:NSNull.null];
  }

  self.currentPage = [self boundedPage:page];
  self.scrollView.delegate = self;
  [self updatePageFrames];
  [self loadPagesAroundPage:self.currentPage];
  [self setContentOffsetForPage:self.currentPage animated:NO];
  [self raisePageIndexChangedDelegate];
}

- (nullable UIView *)viewAtIndex:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)self.pages.count) {
    return nil;
  }
  id object = self.pages[index];
  return [object isKindOfClass:[UIView class]] ? object : nil;
}

- (NSInteger)boundedPage:(NSInteger)page {
  if (self.pages.count == 0) {
    return 0;
  }
  return MIN(MAX(page, 0), (NSInteger)self.pages.count - 1);
}

- (void)setContentOffsetForPage:(NSInteger)page animated:(BOOL)animated {
  if (self.bounds.size.width <= 0) {
    return;
  }
  CGPoint offset = CGPointMake((CGFloat)page * self.bounds.size.width, 0);
  [self.scrollView setContentOffset:offset animated:animated];
}

- (CGRect)frameForPage:(NSInteger)index {
  return CGRectMake(self.bounds.size.width * (CGFloat)index,
                    0,
                    self.bounds.size.width,
                    self.bounds.size.height);
}

- (void)updatePageFrames {
  self.scrollView.frame = self.bounds;
  self.scrollView.contentSize = CGSizeMake(self.bounds.size.width * self.pages.count,
                                           self.bounds.size.height);
  for (NSInteger index = 0; index < (NSInteger)self.pages.count; index++) {
    id object = self.pages[index];
    if ([object isKindOfClass:[UIView class]]) {
      ((UIView *)object).frame = [self frameForPage:index];
    }
  }
}

- (void)loadPagesAroundPage:(NSInteger)page {
  if (self.pages.count == 0) {
    return;
  }
  NSInteger first = MAX(page - 1, 0);
  NSInteger last = MIN(page + 1, (NSInteger)self.pages.count - 1);

  for (NSInteger index = 0; index < (NSInteger)self.pages.count; index++) {
    id object = self.pages[index];
    if (index >= first && index <= last) {
      if (![object isKindOfClass:[UIView class]] &&
          [self.dataSource respondsToSelector:@selector(pageView:index:)]) {
        UIView *pageView = [self.dataSource pageView:self index:index];
        if (pageView) {
          pageView.frame = [self frameForPage:index];
          self.pages[index] = pageView;
          [self.scrollView addSubview:pageView];
        }
      }
    } else if ([object isKindOfClass:[UIView class]]) {
      [(UIView *)object removeFromSuperview];
      self.pages[index] = NSNull.null;
    }
  }
}

- (NSInteger)pageForCurrentOffset {
  if (self.bounds.size.width <= 0 || self.pages.count == 0) {
    return 0;
  }
  CGFloat rawPage = self.scrollView.contentOffset.x / self.bounds.size.width;
  return [self boundedPage:(NSInteger)llround(rawPage)];
}

- (void)finishScrolling {
  self.userScrolling = NO;
  self.currentPage = [self pageForCurrentOffset];
  [self loadPagesAroundPage:self.currentPage];
  [self setContentOffsetForPage:self.currentPage animated:NO];
  [self raisePageIndexChangedDelegate];
}

- (void)raisePageIndexChangedDelegate {
  if ([self.pageViewDelegate respondsToSelector:
      @selector(pageViewScrollEnd:currentIndex:totolPages:)]) {
    [self.pageViewDelegate pageViewScrollEnd:self
                                currentIndex:self.currentPage
                                  totolPages:(NSInteger)self.pages.count];
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  BOOL sizeChanged = !CGSizeEqualToSize(self.bounds.size, self.lastLayoutSize);
  self.lastLayoutSize = self.bounds.size;
  [self updatePageFrames];
  if (sizeChanged) {
    [self setContentOffsetForPage:self.currentPage animated:NO];
    [self loadPagesAroundPage:self.currentPage];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  NSInteger visiblePage = [self pageForCurrentOffset];
  [self loadPagesAroundPage:visiblePage];
  if (self.userScrolling && self.currentPage != visiblePage) {
    self.currentPage = visiblePage;
    [self raisePageIndexChangedDelegate];
  }
  if ([self.pageViewDelegate respondsToSelector:@selector(pageViewDidScroll:)]) {
    [self.pageViewDelegate pageViewDidScroll:self];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.userScrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self finishScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    [self finishScrolling];
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  if (!self.userScrolling) {
    [self finishScrolling];
  }
}

@end
