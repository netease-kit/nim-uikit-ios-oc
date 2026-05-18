// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEPagingIndicatorMetricInsetKind) {
  NEPagingIndicatorMetricInsetKindNone = 0,
  NEPagingIndicatorMetricInsetKindLeft = 1,
  NEPagingIndicatorMetricInsetKindRight = 2,
  NEPagingIndicatorMetricInsetKindBoth = 3,
};

@interface NEPagingIndicatorMetric : NSObject

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) UIEdgeInsets spacing;
@property (nonatomic, assign, readonly) NEPagingIndicatorMetricInsetKind insetKind;
@property (nonatomic, assign, readonly) CGFloat leftInset;
@property (nonatomic, assign, readonly) CGFloat rightInset;
@property (nonatomic, assign, readonly) CGFloat x;
@property (nonatomic, assign, readonly) CGFloat width;

- (instancetype)initWithFrame:(CGRect)frame
                      spacing:(UIEdgeInsets)spacing;
- (instancetype)initWithFrame:(CGRect)frame
                      spacing:(UIEdgeInsets)spacing
                    insetKind:(NEPagingIndicatorMetricInsetKind)insetKind
                    leftInset:(CGFloat)leftInset
                   rightInset:(CGFloat)rightInset;
+ (instancetype)metricWithFrame:(CGRect)frame spacing:(UIEdgeInsets)spacing;
+ (instancetype)metricWithFrame:(CGRect)frame
                        spacing:(UIEdgeInsets)spacing
                      insetKind:(NEPagingIndicatorMetricInsetKind)insetKind
                      leftInset:(CGFloat)leftInset
                     rightInset:(CGFloat)rightInset;

@end

NS_ASSUME_NONNULL_END
