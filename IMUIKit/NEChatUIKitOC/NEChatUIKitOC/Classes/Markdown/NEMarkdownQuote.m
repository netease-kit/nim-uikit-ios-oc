// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownQuote.h"

static NSString * const NEMarkdownQuoteRegexTemplate = @"^(\\>{1,%@})\\s*(.+)$";

@implementation NEMarkdownQuote

- (instancetype)initWithFont:(nullable UIFont *)font
                    maxLevel:(NSInteger)maxLevel
                   indicator:(NSString *)indicator
                   separator:(NSString *)separator
                       color:(nullable UIColor *)color {
    self = [super init];
    if (self) {
        self.font = font;
        self.maxLevel = maxLevel;
        self.indicator = indicator;
        self.separator = separator;
        self.color = color;
    }
    return self;
}

- (instancetype)initWithFont:(nullable UIFont *)font {
    return [self initWithFont:font maxLevel:0 indicator:@">" separator:@"  " color:nil];
}

- (instancetype)init {
    return [self initWithFont:nil maxLevel:0 indicator:@">" separator:@"  " color:nil];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    NSString *level = self.maxLevel > 0 ? [NSString stringWithFormat:@"%ld", (long)self.maxLevel] : @"";
    return [NSString stringWithFormat:NEMarkdownQuoteRegexTemplate, level];
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
    NSInteger level = [match rangeAtIndex:1].length;
    [self addAttributes:attributedString range:[match rangeAtIndex:2] level:level];
    NSRange range = NSMakeRange([match rangeAtIndex:1].location,
                                [match rangeAtIndex:2].location - [match rangeAtIndex:1].location);
    [self formatText:attributedString range:range level:level];
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
    NSMutableString *string = [NSMutableString string];
    for (NSInteger i = 0; i < level; i++) {
        [string appendString:self.separator];
    }
    [string appendFormat:@"%@ ", self.indicator];
    [attributedString replaceCharactersInRange:range withString:string];
}

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [attributedString addAttributes:[self attributesForLevel:level - 1] range:range];
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level {
    return self.attributes;
}

@end
