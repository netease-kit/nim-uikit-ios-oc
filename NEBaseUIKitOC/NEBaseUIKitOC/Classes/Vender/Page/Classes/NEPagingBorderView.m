// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingBorderView.h"
#import "NEPagingBorderLayoutAttributes.h"

@implementation NEPagingBorderView

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
  [super applyLayoutAttributes:layoutAttributes];
  if ([layoutAttributes isKindOfClass:[NEPagingBorderLayoutAttributes class]]) {
    self.backgroundColor = ((NEPagingBorderLayoutAttributes *)layoutAttributes).backgroundColor;
  }
}

@end
