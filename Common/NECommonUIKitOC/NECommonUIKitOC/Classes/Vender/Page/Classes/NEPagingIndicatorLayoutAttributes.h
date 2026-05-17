// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingIndicatorMetric;
@class NEPagingOptions;

@interface NEPagingIndicatorLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, strong, nullable) UIColor *backgroundColor;

- (void)configureWithOptions:(NEPagingOptions *)options;
- (void)updateFromMetric:(NEPagingIndicatorMetric *)fromMetric
                toMetric:(NEPagingIndicatorMetric *)toMetric
                progress:(CGFloat)progress;
- (void)updateToMetric:(NEPagingIndicatorMetric *)metric;

@end

NS_ASSUME_NONNULL_END
