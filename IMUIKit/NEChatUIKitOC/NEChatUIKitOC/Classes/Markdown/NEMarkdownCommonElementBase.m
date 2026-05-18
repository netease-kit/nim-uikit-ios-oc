// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownCommonElementBase.h"

@implementation NEMarkdownCommonElementBase

#pragma mark - NEMarkdownStyle（Default Implementation）

/// 对应 Swift NEMarkdownStyle protocol extension 中的 attributes 默认实现：
/// 由 font 和 color 合成属性字典。
- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    if (self.font) attrs[NSFontAttributeName] = self.font;
    if (self.color) attrs[NSForegroundColorAttributeName] = self.color;
    return [attrs copy];
}

#pragma mark - NEMarkdownElement（Default Implementation）

/// 对应 Swift NEMarkdownCommonElement protocol extension 中的 regularExpression 默认实现：
/// 使用 options:0（无特殊选项）编译 regex。
- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex options:0 error:error];
}

/// 对应 Swift NEMarkdownCommonElement protocol extension 中的 match 默认实现：
/// 删除 group(4) 尾部标记 → 应用样式到 group(3) → 删除 group(2) 头部标记。
- (void)match:(NSTextCheckingResult *)match
attributedString:(NSMutableAttributedString *)attributedString {
    [attributedString deleteCharactersInRange:[match rangeAtIndex:4]];
    [self addAttributes:attributedString range:[match rangeAtIndex:3]];
    [attributedString deleteCharactersInRange:[match rangeAtIndex:2]];
}

#pragma mark - NEMarkdownCommonElement（Default Implementation）

/// 对应 Swift NEMarkdownCommonElement protocol extension 中的 addAttributes 默认实现：
/// 将 self.attributes 应用到指定 range。
- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range {
    [attributedString addAttributes:self.attributes range:range];
}

@end
