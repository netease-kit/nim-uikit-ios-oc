// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (NECorner)

/// 添加自定义圆角
/// @param corners  要圆角的角（UIRectCorner 位掩码）
/// @param radius   圆角半径
/// @param backcolor 背景颜色
- (void)addCustomCorner:(UIRectCorner)corners radius:(CGFloat)radius backcolor:(UIColor *)backcolor;

/// 兼容拼写变体 (conrners)
- (void)addCustomCornerWithConrners:(UIRectCorner)corners radius:(CGFloat)radius backcolor:(UIColor *)backcolor;

/// Removes constraints attached to the view and its current superview before re-parenting.
- (void)removeAllAutoLayout;

/// Removes corner helper subviews added by custom-corner drawing.
- (void)removeAllCustomCorner;

@end

NS_ASSUME_NONNULL_END
