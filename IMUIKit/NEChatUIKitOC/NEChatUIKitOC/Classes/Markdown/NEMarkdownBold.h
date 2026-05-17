// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownCommonElement.h"

NS_ASSUME_NONNULL_BEGIN

/// NEMarkdownBold 是实现 NEMarkdownCommonElement 协议的粗体解析类。
/// 使用 UIFont+Traits 将字体转换为粗体。
@interface NEMarkdownBold : NSObject <NEMarkdownCommonElement>

@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;

/// 初始化
/// @param font 字体（会自动转为 bold），nil 表示不设置
/// @param color 颜色，nil 表示不设置
- (instancetype)initWithFont:(nullable UIFont *)font color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
