// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingIndicatorOptions.h"

@implementation NEPagingIndicatorOptions

+ (instancetype)visibleWithHeight:(CGFloat)height
                           zIndex:(NSInteger)zIndex
                          spacing:(UIEdgeInsets)spacing
                           insets:(UIEdgeInsets)insets {
  NEPagingIndicatorOptions *options = [[self alloc] init];
  options.visible = YES;
  options.height = height;
  options.zIndex = zIndex;
  options.spacing = spacing;
  options.insets = insets;
  return options;
}

+ (instancetype)hiddenOptions {
  NEPagingIndicatorOptions *options = [[self alloc] init];
  options.visible = NO;
  options.height = 0;
  options.zIndex = 0;
  options.spacing = UIEdgeInsetsZero;
  options.insets = UIEdgeInsetsZero;
  return options;
}

- (id)copyWithZone:(NSZone *)zone {
  NEPagingIndicatorOptions *copy = [[[self class] allocWithZone:zone] init];
  copy.visible = self.visible;
  copy.height = self.height;
  copy.zIndex = self.zIndex;
  copy.spacing = self.spacing;
  copy.insets = self.insets;
  return copy;
}

@end
