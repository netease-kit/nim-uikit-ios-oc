// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownItalic.h"
#import "UIFont+Traits.h"

static NSString * const NEMarkdownItalicRegex = @"(\\s|^)(\\*|_)(?![\\*_\\s])(.+?)(?<![\\*_\\s])(\\2)";

@implementation NEMarkdownItalic

- (instancetype)initWithFont:(nullable UIFont *)font color:(nullable UIColor *)color {
    self = [super init];
    if (self) {
        self.font = [font ne_italic] ?: font;
        self.color = color;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFont:nil color:nil];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    return NEMarkdownItalicRegex;
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
    [attributedString deleteCharactersInRange:[match rangeAtIndex:4]];
    [self addAttributes:attributedString range:[match rangeAtIndex:3]];
    [attributedString deleteCharactersInRange:[match rangeAtIndex:2]];
}

#pragma mark - NEMarkdownStyle

- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    if (self.font) attrs[NSFontAttributeName] = self.font;
    if (self.color) attrs[NSForegroundColorAttributeName] = self.color;
    return [attrs copy];
}

#pragma mark - NEMarkdownCommonElement

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range {
    [attributedString addAttributes:self.attributes range:range];
}

@end
