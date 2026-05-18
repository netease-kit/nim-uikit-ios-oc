// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CornerView : UIView

@property (nonatomic, assign) UIRectCorner corner;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIColor *color;

- (instancetype)initWithCorner:(UIRectCorner)corner
                        radius:(CGFloat)radius
                         color:(UIColor *)color;

@end

/// Compatibility header. Corner-overlay implementation is shared in UIView+NECorner.
@interface UIImageView (NECommonUIKit)

- (void)addCustomCorner:(UIRectCorner)corners radius:(CGFloat)radius backcolor:(UIColor *)backcolor;
- (void)removeAllCustomCorner;

@end

NS_ASSUME_NONNULL_END
