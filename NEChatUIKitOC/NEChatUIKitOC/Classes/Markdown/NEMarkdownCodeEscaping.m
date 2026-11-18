// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownCodeEscaping.h"

// 两分支合并为一个正则：
// 分支1 — 多反引号(2+)：内容可跨行 [\s\S]+?
// 分支2 — 单反引号：内容不含换行和反引号 [^\n`]+
static NSString * const NEMarkdownCodeEscapingRegex =
    @"(\\s+|^)(?<!\\\\)(?:\\\\\\\\)*+(?:(\\`{2,})([\\s\\S]+?)(\\2)|(\\`)([^\\n`]+)(\\5))";

@implementation NEMarkdownCodeEscaping

- (NSString *)regex {
    return NEMarkdownCodeEscapingRegex;
}

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex options:0 error:error];
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
    // 分支1（多反引号）：group 3；分支2（单反引号）：group 6
    NSInteger contentGroupIndex;
    if (match.numberOfRanges > 2 && [match rangeAtIndex:2].location != NSNotFound) {
        contentGroupIndex = 3;
    } else {
        contentGroupIndex = 6;
    }

    NSRange range = [match rangeAtIndex:contentGroupIndex];
    NSString *matchString = [attributedString attributedSubstringFromRange:range].string;

    // 将每个 UTF-16 字符编码为 4 位十六进制
    NSMutableString *escapedString = [NSMutableString string];
    NSUInteger len = matchString.length;
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [matchString characterAtIndex:i];
        [escapedString appendFormat:@"%04x", (unsigned int)c];
    }
    [attributedString replaceCharactersInRange:range withString:escapedString];
}

@end
