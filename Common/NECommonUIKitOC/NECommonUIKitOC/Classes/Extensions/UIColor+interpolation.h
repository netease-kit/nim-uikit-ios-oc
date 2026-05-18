// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (interpolation)

- (void)ne_componentsRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
+ (UIColor *)interpolateFrom:(UIColor *)from to:(UIColor *)to withFraction:(CGFloat)fraction;

@end

NS_ASSUME_NONNULL_END

