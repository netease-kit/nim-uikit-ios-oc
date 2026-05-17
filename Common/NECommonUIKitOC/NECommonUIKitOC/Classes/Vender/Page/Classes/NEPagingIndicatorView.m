// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingIndicatorView.h"
#import "NEPagingIndicatorLayoutAttributes.h"

@implementation NEPagingIndicatorView

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
  [super applyLayoutAttributes:layoutAttributes];
  if ([layoutAttributes isKindOfClass:[NEPagingIndicatorLayoutAttributes class]]) {
    self.backgroundColor = ((NEPagingIndicatorLayoutAttributes *)layoutAttributes).backgroundColor;
  }
}

@end
