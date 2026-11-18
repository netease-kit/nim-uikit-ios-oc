// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElementBase.h"
#import "NEMarkdownLevelElement.h"

NS_ASSUME_NONNULL_BEGIN

/// NEMarkdownLevelElement 协议的 NSObject 基类，继承 NEMarkdownElementBase。
///
/// 对应 Swift NEMarkdownLevelElement protocol extension 的 default implementation：
///   - regularExpression：使用 AnchorsMatchLines 选项编译 regex（level 元素通常是行首锚定）
///   - match:attributedString:：取 group(1).length 作为 level，调用 addAttributes:range:level: 和 formatText:range:level:
///   - addAttributes:range:level:：调用 attributesForLevel:level-1 应用到 range
///   - attributesForLevel:：返回 self.attributes（子类通常覆盖以按 level 调整字体大小等）
///
/// 子类必须实现：
///   - regex
///   - attributes（NEMarkdownStyle 协议要求）
///   - formatText:range:level:（处理标记符号的格式化/替换）
///
/// 子类可覆盖：
///   - regularExpressionWithError: 以传入不同正则选项
///   - match:attributedString: 以自定义 group 解析逻辑（如 NEMarkdownOrderedList 使用不同 group）
///   - addAttributes:range:level: 以自定义样式应用逻辑
///   - attributesForLevel: 以按 level 返回不同属性（如 NEMarkdownHeader 按 level 调整字号）
@interface NEMarkdownLevelElementBase : NEMarkdownElementBase <NEMarkdownLevelElement>

/// 样式属性字典，由 font 和 color 合成。
/// 对应 Swift NEMarkdownStyle protocol extension 中的 attributes 默认实现。
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;

/// 最大级别（0 表示不限制），对应 NEMarkdownLevelElement.maxLevel。
@property (nonatomic, assign) NSInteger maxLevel;

@end

NS_ASSUME_NONNULL_END
