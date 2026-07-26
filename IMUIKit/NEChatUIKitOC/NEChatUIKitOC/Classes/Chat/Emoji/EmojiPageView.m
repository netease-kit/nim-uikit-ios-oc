// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "EmojiPageView.h"
#import <NEChatKit/NEALog.h>

static NSString *const kClassTag = @"EmojiPageView";

@interface EmojiPageView () <UIScrollViewDelegate>

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSMutableArray *pages;

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation EmojiPageView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _currentPage = 0;
    _pages = [NSMutableArray array];
    [self setupControls];
  }
  return self;
}

- (UIScrollView *)scrollView {
  if (!_scrollView) {
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
  }
  return _scrollView;
}

- (void)setupControls {
  [self addSubview:self.scrollView];
}

- (void)setFrame:(CGRect)frame {
  CGFloat originalWidth = self.frame.size.width;
  [super setFrame:frame];
  if (originalWidth != self.frame.size.width) {
    [self reloadData];
  }
}

- (void)scrollToPage:(NSInteger)page {
  if (self.currentPage != page || page == 0) {
    self.currentPage = page;
    [self reloadData];
  }
}

- (void)reloadData {
  [self calculatePageNumbers];
  [self setupInit];
}

- (nullable UIView *)viewAtIndex:(NSInteger)index {
  if (index >= 0 && index < (NSInteger)self.pages.count) {
    id obj = self.pages[index];
    if ([obj isKindOfClass:[UIView class]]) {
      return (UIView *)obj;
    }
  }
  return nil;
}

- (void)reloadPage {
  if (self.currentPage >= (NSInteger)self.pages.count) {
    self.currentPage = (NSInteger)self.pages.count - 1;
  }
  if (self.currentPage < 0) {
    self.currentPage = 0;
  }
  [self loadPages:self.currentPage];
  [self raisePageIndexChangedDelegate];
  [self setNeedsLayout];
}

- (void)calculatePageNumbers {
  NSInteger numberOfPages = 0;
  for (id obj in self.pages) {
    if ([obj isKindOfClass:[UIView class]]) {
      [(UIView *)obj removeFromSuperview];
    }
  }
  [self.pages removeAllObjects];

  if ([self.dataSource respondsToSelector:@selector(numberOfPages:)]) {
    numberOfPages = [self.dataSource numberOfPages:self];
  }

  for (NSInteger i = 0; i < numberOfPages; i++) {
    [self.pages addObject:[NSNull null]];
  }
  self.scrollView.delegate = nil;
  CGSize size = self.bounds.size;
  self.scrollView.contentSize = CGSizeMake(size.width * numberOfPages, size.height);
  self.scrollView.delegate = nil;
}

- (NSInteger)pageInBoundValue:(NSInteger)value min:(NSInteger)minVal max:(NSInteger)maxVal {
  NSInteger maxUse = maxVal;
  if (maxUse < minVal) {
    maxUse = minVal;
  }
  NSInteger bounded = value;
  if (bounded > maxUse) bounded = maxUse;
  if (bounded < minVal) bounded = minVal;
  return bounded;
}

- (void)setupInit {
  NSInteger count = (NSInteger)self.pages.count;
  for (NSInteger i = 0; i < count; i++) {
    if ([self.dataSource respondsToSelector:@selector(pageView:index:)]) {
      UIView *targetView = [self.dataSource pageView:self index:i];
      if (targetView) {
        self.pages[i] = targetView;
        [self.scrollView addSubview:targetView];
        CGSize size = self.bounds.size;
        targetView.frame = CGRectMake(size.width * i, 0, size.width, size.height);
      }
    }
  }
}

- (void)loadPages:(NSInteger)curPage {
  NSInteger count = (NSInteger)self.pages.count;
  if (count == 0) return;

  NSInteger first = [self pageInBoundValue:curPage - 1 min:0 max:count - 1];
  NSInteger last = [self pageInBoundValue:curPage + 1 min:0 max:count - 1];
  NSRange range = NSMakeRange(first, last - first + 1);

  for (NSInteger i = 0; i < count; i++) {
    if (NSLocationInRange(i, range)) {
      id obj = self.pages[i];
      if (![obj isKindOfClass:[UIView class]]) {
        if ([self.dataSource respondsToSelector:@selector(pageView:index:)]) {
          UIView *targetView = [self.dataSource pageView:self index:i];
          if (targetView) {
            self.pages[i] = targetView;
            [self.scrollView addSubview:targetView];
            CGSize size = self.bounds.size;
            targetView.frame = CGRectMake(size.width * i, 0, size.width, size.height);
          }
        }
      }
    } else {
      id obj = self.pages[i];
      if ([obj isKindOfClass:[UIView class]]) {
        [(UIView *)obj removeFromSuperview];
        self.pages[i] = [NSNull null];
      }
    }
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGSize size = self.bounds.size;
  self.scrollView.contentSize = CGSizeMake(size.width * self.pages.count, size.height);

  for (NSInteger i = 0; i < (NSInteger)self.pages.count; i++) {
    id obj = self.pages[i];
    if ([obj isKindOfClass:[UIView class]]) {
      ((UIView *)obj).frame = CGRectMake(size.width * i, 0, size.width, size.height);
    }
  }

  BOOL animation = NO;
  if ([self.pageViewDelegate respondsToSelector:@selector(needScrollAnimation)]) {
    animation = [self.pageViewDelegate needScrollAnimation];
  }
  self.scrollView.delegate = self;
  [self.scrollView scrollRectToVisible:CGRectMake(self.currentPage * size.width, 0, size.width, size.height)
                              animated:animation];
}

- (void)raisePageIndexChangedDelegate {
  if ([self.pageViewDelegate respondsToSelector:@selector(pageViewScrollEnd:currentIndex:totolPages:)]) {
    [self.pageViewDelegate pageViewScrollEnd:self
                                currentIndex:self.currentPage
                                  totolPages:(NSInteger)self.pages.count];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat width = scrollView.bounds.size.width;
  CGFloat offsetX = scrollView.contentOffset.x;
  NSInteger page = (NSInteger)fabs(offsetX / width);

  if (page >= 0 && page < (NSInteger)self.pages.count) {
    if (self.currentPage != page) {
      self.currentPage = page;
      [self loadPages:self.currentPage];
    }
  }

  if ([self.pageViewDelegate respondsToSelector:@selector(pageViewDidScroll:)]) {
    [self.pageViewDelegate pageViewDidScroll:self];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if ([self.pageViewDelegate respondsToSelector:@selector(pageViewScrollEnd:currentIndex:totolPages:)]) {
    [self.pageViewDelegate pageViewScrollEnd:self
                                currentIndex:self.currentPage
                                  totolPages:(NSInteger)self.pages.count];
  }
}

@end
