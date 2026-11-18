// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECollectionView.h"

@implementation UICollectionView (NECollectionView)

- (BOOL)ne_nearEdge:(NECollectionViewEdge)edge clearance:(CGFloat)clearance {
  switch (edge) {
    case NECollectionViewEdgeLeft:
      return self.contentOffset.x + self.contentInset.left - clearance <= 0;
    case NECollectionViewEdgeRight:
      return self.contentOffset.x + CGRectGetWidth(self.bounds) + clearance >= self.contentSize.width;
    case NECollectionViewEdgeTop:
      return self.contentOffset.y + self.contentInset.top - clearance <= 0;
    case NECollectionViewEdgeBottom:
      return self.contentOffset.y + CGRectGetHeight(self.bounds) + clearance >= self.contentSize.height;
  }
}

@end
