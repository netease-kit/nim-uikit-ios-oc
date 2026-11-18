// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingIndicatorLayoutAttributes.h"
#import "NEPagingIndicatorMetric.h"
#import "NEPagingOptions.h"
#import "NEPagingIndicatorOptions.h"
#import "NEPagingMenuPosition.h"
#import "Tween.h"

@implementation NEPagingIndicatorLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
  NEPagingIndicatorLayoutAttributes *copy = [super copyWithZone:zone];
  copy.backgroundColor = self.backgroundColor;
  return copy;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[NEPagingIndicatorLayoutAttributes class]]) {
    return NO;
  }
  NEPagingIndicatorLayoutAttributes *other = (NEPagingIndicatorLayoutAttributes *)object;
  if ((self.backgroundColor != other.backgroundColor) &&
      ![self.backgroundColor isEqual:other.backgroundColor]) {
    return NO;
  }
  return [super isEqual:object];
}

- (void)configureWithOptions:(NEPagingOptions *)options {
  if (!options.indicatorOptions.visible) {
    return;
  }
  self.backgroundColor = options.indicatorColor;
  self.frame = CGRectMake(CGRectGetMinX(self.frame),
                          CGRectGetMinY(self.frame),
                          CGRectGetWidth(self.frame),
                          options.indicatorOptions.height);
  switch (options.menuPosition) {
    case NEPagingMenuPositionTop:
      self.frame = CGRectMake(CGRectGetMinX(self.frame),
                              options.menuHeight - options.indicatorOptions.height - options.indicatorOptions.insets.bottom + options.indicatorOptions.insets.top,
                              CGRectGetWidth(self.frame),
                              options.indicatorOptions.height);
      break;
    case NEPagingMenuPositionBottom:
      self.frame = CGRectMake(CGRectGetMinX(self.frame),
                              options.indicatorOptions.insets.bottom,
                              CGRectGetWidth(self.frame),
                              options.indicatorOptions.height);
      break;
  }
  self.zIndex = (NSInteger)options.indicatorOptions.zIndex;
}

- (void)updateFromMetric:(NEPagingIndicatorMetric *)fromMetric
                toMetric:(NEPagingIndicatorMetric *)toMetric
                progress:(CGFloat)progress {
  self.frame = CGRectMake(NEPagingTween(fromMetric.x, toMetric.x, progress),
                          CGRectGetMinY(self.frame),
                          NEPagingTween(fromMetric.width, toMetric.width, progress),
                          CGRectGetHeight(self.frame));
}

- (void)updateToMetric:(NEPagingIndicatorMetric *)metric {
  self.frame = CGRectMake(metric.x,
                          CGRectGetMinY(self.frame),
                          metric.width,
                          CGRectGetHeight(self.frame));
}

@end
