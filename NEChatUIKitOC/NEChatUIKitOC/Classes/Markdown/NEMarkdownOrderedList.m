// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownOrderedList.h"

static NSString * const NEMarkdownOrderedListRegexTemplate = @"^( {0,%@})(\\d+)\\.\\s+(.+)$";

@implementation NEMarkdownOrderedList

- (instancetype)initWithFont:(nullable UIFont *)font maxLevel:(NSInteger)maxLevel color:(nullable UIColor *)color {
    self = [super init];
    if (self) {
        self.font = font;
        self.maxLevel = maxLevel;
        self.color = color;
    }
    return self;
}

- (instancetype)initWithFont:(nullable UIFont *)font {
    return [self initWithFont:font maxLevel:6 color:nil];
}

- (instancetype)init {
    return [self initWithFont:nil maxLevel:6 color:nil];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    NSString *level = self.maxLevel > 0 ? [NSString stringWithFormat:@"%ld", (long)self.maxLevel] : @"";
    return [NSString stringWithFormat:NEMarkdownOrderedListRegexTemplate, level];
}

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex
                                                     options:NSRegularExpressionAnchorsMatchLines
                                                       error:error];
}

- (void)parse:(NSMutableAttributedString *)attributedString {
    NSInteger location = 0;
    NSError *error = nil;
    NSRegularExpression *regex = [self regularExpressionWithError:&error];
    if (!regex) return;
    while (YES) {
        NSRange searchRange = NSMakeRange(location, attributedString.length - location);
        NSTextCheckingResult *regexMatch = [regex firstMatchInString:attributedString.string
                                                             options:NSMatchingWithoutAnchoringBounds
                                                               range:searchRange];
        if (!regexMatch) break;
        NSInteger oldLength = attributedString.length;
        [self match:regexMatch attributedString:attributedString];
        NSInteger newLength = attributedString.length;
        location = regexMatch.range.location + regexMatch.range.length + newLength - oldLength;
    }
}

- (void)match:(NSTextCheckingResult *)match attributedString:(NSMutableAttributedString *)attributedString {
    // group(3)：内容文字范围 —— 应用字体/颜色属性
    NSRange contentRange = [match rangeAtIndex:3];
    [self addAttributes:attributedString range:contentRange level:1];

    // group(1)：前导空格范围 —— 传给 formatText 做缩进处理
    NSRange indentRange = [match rangeAtIndex:1];
    NSInteger level = (NSInteger)indentRange.length + 1;
    [self formatText:attributedString range:indentRange level:level];
}

#pragma mark - NEMarkdownStyle

- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    if (self.font) attrs[NSFontAttributeName] = self.font;
    if (self.color) attrs[NSForegroundColorAttributeName] = self.color;
    return [attrs copy];
}

#pragma mark - NEMarkdownLevelElement

- (void)formatText:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    NSString *nsString = attributedString.string;

    // 找到序号：range 结束位置之后，读取到 '.' 之前
    NSInteger afterIndent = range.location + range.length;
    NSInteger dotPos = afterIndent;
    while (dotPos < (NSInteger)nsString.length && [nsString characterAtIndex:dotPos] != '.') {
        dotPos++;
    }
    NSString *numberStr = [nsString substringWithRange:NSMakeRange(afterIndent, dotPos - afterIndent)];

    NSInteger indentDepth = (MAX(1, level) - 1) / 2;
    NSMutableString *prefix = [NSMutableString string];
    for (NSInteger i = 0; i < indentDepth; i++) [prefix appendString:@"  "];
    [prefix appendFormat:@"%@. ", numberStr];

    [attributedString replaceCharactersInRange:range withString:prefix];

    CGFloat indentPt = 8 + indentDepth * 16;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = indentPt;
    paragraphStyle.headIndent = indentPt + 16;
    paragraphStyle.paragraphSpacing = 4;

    NSRange newRange = NSMakeRange(range.location, prefix.length);
    [attributedString addAttributes:@{NSParagraphStyleAttributeName: paragraphStyle} range:newRange];
}

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [attributedString addAttributes:[self attributesForLevel:level - 1] range:range];
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level {
    return self.attributes;
}

@end
