// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElementBase.h"
#import "NEMarkdownCommonElement.h"

NS_ASSUME_NONNULL_BEGIN

/// NEMarkdownCommonElement 协议的 NSObject 基类，继承 NEMarkdownElementBase。
///
/// 对应 Swift NEMarkdownCommonElement protocol extension 的 default implementation：
///   - regularExpression：使用 options:0 编译 regex
///   - addAttributes:range:：调用 self.attributes 应用到 attributedString
///   - match:attributedString:：删除 group(4)尾部标记 → 应用样式到 group(3) → 删除 group(2)头部标记
///
/// 子类必须实现：
///   - regex
///   - attributes（NEMarkdownStyle 协议要求）
///
/// 子类可覆盖：
///   - regularExpressionWithError: 以传入特殊正则选项
///   - addAttributes:range: 以自定义样式应用逻辑（如 NEMarkdownCode）
///   - match:attributedString: 以自定义 group 处理（如特殊结构的元素）
@interface NEMarkdownCommonElementBase : NEMarkdownElementBase <NEMarkdownCommonElement>

/// 样式属性字典，由 font 和 color 合成。
/// 对应 Swift NEMarkdownStyle protocol extension 中的 attributes 默认实现。
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;

@end

NS_ASSUME_NONNULL_END
