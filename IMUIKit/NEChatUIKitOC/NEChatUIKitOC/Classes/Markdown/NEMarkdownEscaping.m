// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownEscaping.h"

static NSString * const NEMarkdownEscapingRegex = @"\\\\.";

@implementation NEMarkdownEscaping

- (NSString *)regex {
    return NEMarkdownEscapingRegex;
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
    // 取 \X 中的 X（跳过第一个字符 \）
    NSRange range = NSMakeRange(match.range.location + 1, 1);
    NSString *matchString = [attributedString attributedSubstringFromRange:range].string;
    if (matchString.length == 0) return;

    unichar c = [matchString characterAtIndex:0];
    NSString *escapedString = [NSString stringWithFormat:@"%04x", (unsigned int)c];
    [attributedString replaceCharactersInRange:range withString:escapedString];
}

@end
