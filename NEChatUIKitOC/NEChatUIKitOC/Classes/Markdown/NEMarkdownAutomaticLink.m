// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownAutomaticLink.h"

@implementation NEMarkdownAutomaticLink

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:error];
}

- (void)match:(NSTextCheckingResult *)match attributedString:(NSMutableAttributedString *)attributedString {
    NSURL *url = match.URL;
    if (!url) return;
    [self formatText:attributedString range:match.range link:url.absoluteString];
    [self addAttributes:attributedString range:match.range link:url.absoluteString];
}

@end
