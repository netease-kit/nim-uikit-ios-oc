// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingBorderOptions.h"

@implementation NEPagingBorderOptions

+ (instancetype)visibleWithHeight:(CGFloat)height
                           zIndex:(NSInteger)zIndex
                           insets:(UIEdgeInsets)insets {
  NEPagingBorderOptions *options = [[self alloc] init];
  options.visible = YES;
  options.height = height;
  options.zIndex = zIndex;
  options.insets = insets;
  return options;
}

+ (instancetype)hiddenOptions {
  NEPagingBorderOptions *options = [[self alloc] init];
  options.visible = NO;
  options.height = 0;
  options.zIndex = 0;
  options.insets = UIEdgeInsetsZero;
  return options;
}

- (id)copyWithZone:(NSZone *)zone {
  NEPagingBorderOptions *copy = [[[self class] allocWithZone:zone] init];
  copy.visible = self.visible;
  copy.height = self.height;
  copy.zIndex = self.zIndex;
  copy.insets = self.insets;
  return copy;
}

@end
