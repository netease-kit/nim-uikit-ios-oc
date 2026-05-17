// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownAutomaticLink.h"

@implementation NEMarkdownAutomaticLink

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:error];
}

- (void)match:(NSTextCheckingResult *)match attributedString:(NSMutableAttributedString *)attributedString {
    NSString *linkURLString = [attributedString attributedSubstringFromRange:match.range].string;
    [self formatText:attributedString range:match.range link:linkURLString];
    [self addAttributes:attributedString range:match.range link:linkURLString];
}

@end
