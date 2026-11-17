// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingBorderLayoutAttributes.h"
#import "NEPagingOptions.h"
#import "NEPagingBorderOptions.h"
#import "NEPagingMenuPosition.h"
#import "UIEdgeInsets.h"

@implementation NEPagingBorderLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
  NEPagingBorderLayoutAttributes *copy = [super copyWithZone:zone];
  copy.backgroundColor = self.backgroundColor;
  copy.insets = self.insets;
  return copy;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[NEPagingBorderLayoutAttributes class]]) {
    return NO;
  }
  NEPagingBorderLayoutAttributes *other = (NEPagingBorderLayoutAttributes *)object;
  BOOL sameColor = (self.backgroundColor == other.backgroundColor) || [self.backgroundColor isEqual:other.backgroundColor];
  return sameColor && UIEdgeInsetsEqualToEdgeInsets(self.insets, other.insets) && [super isEqual:object];
}

- (void)configureWithOptions:(NEPagingOptions *)options {
  if (!options.borderOptions.visible) {
    return;
  }
  self.insets = options.borderOptions.insets;
  self.backgroundColor = options.borderColor;
  switch (options.menuPosition) {
    case NEPagingMenuPositionTop:
      self.frame = CGRectMake(CGRectGetMinX(self.frame),
                              options.menuHeight - options.borderOptions.height,
                              CGRectGetWidth(self.frame),
                              options.borderOptions.height);
      break;
    case NEPagingMenuPositionBottom:
      self.frame = CGRectMake(CGRectGetMinX(self.frame),
                              0,
                              CGRectGetWidth(self.frame),
                              options.borderOptions.height);
      break;
  }
  self.zIndex = (NSInteger)options.borderOptions.zIndex;
}

- (void)updateWithContentSize:(CGSize)contentSize
                       bounds:(CGRect)bounds
               safeAreaInsets:(UIEdgeInsets)safeAreaInsets {
  CGFloat width = MAX(CGRectGetWidth(bounds), contentSize.width);
  self.frame = CGRectMake(self.insets.left + safeAreaInsets.left,
                          CGRectGetMinY(self.frame),
                          width - NEUIEdgeInsetsHorizontal(self.insets) - NEUIEdgeInsetsHorizontal(safeAreaInsets),
                          CGRectGetHeight(self.frame));
}

@end
