// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingMenuItemSize.h"

@interface NEPagingMenuItemSize ()

@property (nonatomic, assign, readwrite) CGFloat width;
@property (nonatomic, assign, readwrite) CGFloat minimumWidth;
@property (nonatomic, assign, readwrite) CGFloat height;
@property (nonatomic, assign, readwrite) NEPagingMenuItemSizingMode sizingMode;

@end

@implementation NEPagingMenuItemSize

+ (instancetype)fixedWidth:(CGFloat)width height:(CGFloat)height {
  NEPagingMenuItemSize *size = [[self alloc] init];
  size.width = width;
  size.minimumWidth = width;
  size.height = height;
  size.sizingMode = NEPagingMenuItemSizingModeFixed;
  return size;
}

+ (instancetype)sizeToFitMinWidth:(CGFloat)minimumWidth height:(CGFloat)height {
  NEPagingMenuItemSize *size = [[self alloc] init];
  size.width = minimumWidth;
  size.minimumWidth = minimumWidth;
  size.height = height;
  size.sizingMode = NEPagingMenuItemSizingModeSizeToFit;
  return size;
}

+ (instancetype)selfSizingEstimatedWidth:(CGFloat)estimatedWidth height:(CGFloat)height {
  NEPagingMenuItemSize *size = [[self alloc] init];
  size.width = estimatedWidth;
  size.minimumWidth = estimatedWidth;
  size.height = height;
  size.sizingMode = NEPagingMenuItemSizingModeSelfSizing;
  return size;
}

- (BOOL)isHidden {
  return self.height <= 0.0 ||
         ((self.sizingMode == NEPagingMenuItemSizingModeFixed ||
           self.sizingMode == NEPagingMenuItemSizingModeSelfSizing) &&
          self.width <= 0.0);
}

- (id)copyWithZone:(NSZone *)zone {
  NEPagingMenuItemSize *copy = [[[self class] allocWithZone:zone] init];
  copy.width = self.width;
  copy.minimumWidth = self.minimumWidth;
  copy.height = self.height;
  copy.sizingMode = self.sizingMode;
  return copy;
}

@end
