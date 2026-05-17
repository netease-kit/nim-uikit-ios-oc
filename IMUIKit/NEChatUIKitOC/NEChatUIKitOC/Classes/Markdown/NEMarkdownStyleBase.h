// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownStyle.h"

NS_ASSUME_NONNULL_BEGIN

/// NEMarkdownStyle 协议的 NSObject 基类，提供 attributes 的默认实现。
///
/// 对应 Swift NEMarkdownStyle protocol extension 中的 default implementation：
///   - attributes：由 font 和 color 合成属性字典
///
/// 注意：NEMarkdownCommonElementBase 和 NEMarkdownLevelElementBase 已包含此逻辑。
/// NEMarkdownStyleBase 供仅实现 NEMarkdownStyle（不需要 parse 能力）的类使用。
@interface NEMarkdownStyleBase : NSObject <NEMarkdownStyle>

/// 字体（nil 表示不设置）
@property (nonatomic, strong, nullable) UIFont *font;
/// 颜色（nil 表示不设置）
@property (nonatomic, strong, nullable) UIColor *color;

@end

NS_ASSUME_NONNULL_END
