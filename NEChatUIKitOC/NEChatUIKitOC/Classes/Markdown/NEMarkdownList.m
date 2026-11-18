// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownList.h"

static NSString * const NEMarkdownListRegexTemplate = @"^( {0,%@}[\\*\\+\\-])\\s+(.+)$";

@implementation NEMarkdownList

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
    return [self initWithFont:font maxLevel:6 indicator:@"•" separator:@"  " color:nil];
}

- (instancetype)init {
    return [self initWithFont:nil maxLevel:6 indicator:@"•" separator:@"  " color:nil];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    NSString *level = self.maxLevel > 0 ? [NSString stringWithFormat:@"%ld", (long)self.maxLevel] : @"";
    return [NSString stringWithFormat:NEMarkdownListRegexTemplate, level];
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
    NSDictionary *levelIndicatorList = @{
        @1: [NSString stringWithFormat:@"%@  ", self.indicator],
        @2: [NSString stringWithFormat:@"%@  ", self.indicator],
        @3: @"◦  ",
        @4: @"◦  ",
        @5: @"▪︎  ",
        @6: @"▪︎  ",
    };
    NSDictionary *levelOffsetList = @{
        @1: @"", @2: @"", @3: @"  ", @4: @"  ", @5: @"    ", @6: @"    "
    };

    NSString *indicatorIcon = levelIndicatorList[@(level)];
    NSString *offset = levelOffsetList[@(level)];
    if (!indicatorIcon || !offset) return;

    NSString *indicatorStr = [NSString stringWithFormat:@"%@%@", offset, indicatorIcon];
    [attributedString replaceCharactersInRange:range withString:indicatorStr];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = 0;
    paragraphStyle.headIndent = 16;
    paragraphStyle.paragraphSpacing = 4;
    [attributedString addAttributes:@{NSParagraphStyleAttributeName: paragraphStyle} range:range];
}

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [attributedString addAttributes:[self attributesForLevel:level - 1] range:range];
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level {
    return self.attributes;
}

@end
