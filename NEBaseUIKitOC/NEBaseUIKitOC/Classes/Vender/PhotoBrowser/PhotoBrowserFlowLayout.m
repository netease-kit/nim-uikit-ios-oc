// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PhotoBrowserFlowLayout.h"

@implementation PhotoBrowserFlowLayout

- (instancetype)init {
  self = [super init];
  if (self) {
    _lastOffset = CGPointZero;
  }
  return self;
}

- (void)prepareLayout {
  [super prepareLayout];
  self.lastOffset = self.collectionView.contentOffset;
  self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
                                  withScrollingVelocity:(CGPoint)velocity {
  CGFloat pageSpace = [self stepSpace];
  CGFloat contentWidth = self.collectionView.contentSize.width > 0 ? self.collectionView.contentSize.width
                                                                   : CGRectGetWidth(self.collectionView.bounds);
  CGFloat offsetMax = contentWidth - (pageSpace + self.sectionInset.right + self.minimumLineSpacing);
  CGFloat offsetMin = 0;
  if (self.lastOffset.x < offsetMin) {
    self.lastOffset = CGPointMake(offsetMin, self.lastOffset.y);
  } else if (self.lastOffset.x > offsetMax) {
    self.lastOffset = CGPointMake(offsetMax, self.lastOffset.y);
  }

  CGFloat offsetForCurrentPointX = fabs(proposedContentOffset.x - self.lastOffset.x);
  CGFloat velocityX = velocity.x;
  BOOL direction = (proposedContentOffset.x - self.lastOffset.x) > 0;

  if (offsetForCurrentPointX > (pageSpace / 8.0) &&
      self.lastOffset.x >= offsetMin &&
      self.lastOffset.x <= offsetMax) {
    CGFloat pageFactor = 0;
    if (velocityX != 0) {
      pageFactor = fabs(velocityX);
    } else {
      pageFactor = fabs(offsetForCurrentPointX / pageSpace);
    }
    pageFactor = pageFactor < 1 ? 1 : 1;
    CGFloat pageOffsetX = pageSpace * pageFactor;
    proposedContentOffset = CGPointMake(self.lastOffset.x + (direction ? pageOffsetX : -pageOffsetX),
                                        proposedContentOffset.y);
  } else {
    proposedContentOffset = self.lastOffset;
  }
  self.lastOffset = CGPointMake(proposedContentOffset.x, self.lastOffset.y);
  return proposedContentOffset;
}

- (CGFloat)stepSpace {
  return self.itemSize.width + self.minimumLineSpacing;
}

@end
