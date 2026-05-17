// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownCommonElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEMarkdownCode : NSObject <NEMarkdownCommonElement>

@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, strong, nullable) UIColor *textHighlightColor;
@property (nonatomic, strong, nullable) UIColor *textBackgroundColor;

/// 默认高亮颜色（红色调）
@property (class, nonatomic, readonly) UIColor *defaultHighlightColor;
/// 默认背景颜色（浅灰色）
@property (class, nonatomic, readonly) UIColor *defaultBackgroundColor;
/// 默认字体（Menlo-Regular, 16pt）
@property (class, nonatomic, readonly, nullable) UIFont *defaultFont;

- (instancetype)initWithFont:(nullable UIFont *)font
                       color:(nullable UIColor *)color
          textHighlightColor:(nullable UIColor *)textHighlightColor
         textBackgroundColor:(nullable UIColor *)textBackgroundColor;

@end

NS_ASSUME_NONNULL_END
