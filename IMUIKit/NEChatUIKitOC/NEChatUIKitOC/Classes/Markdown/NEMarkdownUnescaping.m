// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownUnescaping.h"
#import "NSString+UTF16.h"

static NSString * const NEMarkdownUnescapingRegex = @"\\\\[0-9a-z]{4}";

@implementation NEMarkdownUnescaping

- (NSString *)regex {
    return NEMarkdownUnescapingRegex;
}

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex
                                                     options:NSRegularExpressionDotMatchesLineSeparators
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
    // 跳过开头的 \，取后面 4 位十六进制
    NSRange range = NSMakeRange(match.range.location + 1, 4);
    NSString *matchString = [attributedString attributedSubstringFromRange:range].string;
    NSString *unescapedString = [matchString ne_unescapeUTF16];
    if (!unescapedString) return;
    [attributedString replaceCharactersInRange:match.range withString:unescapedString];
}

@end
