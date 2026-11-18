// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownElementBase.h"

@implementation NEMarkdownElementBase

#pragma mark - NEMarkdownElement（子类必须覆盖）

- (NSString *)regex {
    // 子类必须覆盖此方法
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ 必须实现 -regex", NSStringFromClass([self class])];
    return @"";
}

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    // 子类必须覆盖此方法
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ 必须实现 -regularExpressionWithError:", NSStringFromClass([self class])];
    return nil;
}

- (void)match:(NSTextCheckingResult *)match
attributedString:(NSMutableAttributedString *)attributedString {
    // 子类必须覆盖此方法
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ 必须实现 -match:attributedString:", NSStringFromClass([self class])];
}

#pragma mark - NEMarkdownElement（Default Implementation）

/// 对应 Swift NEMarkdownElement protocol extension 中的 parse 默认实现：
/// 通过正则表达式循环匹配 attributedString，对每个匹配结果调用 match:attributedString:。
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

@end
