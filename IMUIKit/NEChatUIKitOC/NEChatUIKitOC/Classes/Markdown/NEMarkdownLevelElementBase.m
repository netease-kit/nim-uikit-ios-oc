// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownLevelElementBase.h"

@implementation NEMarkdownLevelElementBase

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

/// 对应 Swift NEMarkdownLevelElement protocol extension 中的 regularExpression 默认实现：
/// 使用 AnchorsMatchLines 选项编译 regex（level 类元素通常是行首锚定正则）。
- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex
                                                     options:NSRegularExpressionAnchorsMatchLines
                                                       error:error];
}

/// 对应 Swift NEMarkdownLevelElement protocol extension 中的 match 默认实现：
/// 取 group(1).length 作为 level，依次调用 addAttributes:range:level: 和 formatText:range:level:。
- (void)match:(NSTextCheckingResult *)match
attributedString:(NSMutableAttributedString *)attributedString {
    NSInteger level = [match rangeAtIndex:1].length;
    [self addAttributes:attributedString range:[match rangeAtIndex:2] level:level];
    NSRange range = NSMakeRange([match rangeAtIndex:1].location,
                                [match rangeAtIndex:2].location - [match rangeAtIndex:1].location);
    [self formatText:attributedString range:range level:level];
}

#pragma mark - NEMarkdownLevelElement（Default Implementation）

/// 对应 Swift NEMarkdownLevelElement protocol extension 中的 addAttributes 默认实现：
/// 调用 attributesForLevel:level-1 将属性应用到 range。
- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [attributedString addAttributes:[self attributesForLevel:level - 1] range:range];
}

/// 对应 Swift NEMarkdownLevelElement protocol extension 中的 attributesForLevel 默认实现：
/// 直接返回 self.attributes（不按 level 区分）。
/// 需要按 level 调整样式的子类（如 NEMarkdownHeader）应覆盖此方法。
- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level {
    return self.attributes;
}

#pragma mark - NEMarkdownLevelElement（子类必须实现）

- (void)formatText:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ 必须实现 -formatText:range:level:", NSStringFromClass([self class])];
}

@end
