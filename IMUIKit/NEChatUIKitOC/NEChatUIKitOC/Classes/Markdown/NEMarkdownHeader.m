// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownHeader.h"
#import "UIFont+Traits.h"

static NSString * const NEMarkdownHeaderRegexTemplate = @"^(#{1,%@})\\s*(.+)$";

@implementation NEMarkdownHeader

+ (UIFont *)defaultFont {
    return [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
}

- (instancetype)initWithFont:(nullable UIFont *)font
                    maxLevel:(NSInteger)maxLevel
                fontIncrease:(NSInteger)fontIncrease
                       color:(nullable UIColor *)color {
    self = [super init];
    if (self) {
        self.font = font ?: [NEMarkdownHeader defaultFont];
        self.maxLevel = maxLevel;
        self.fontIncrease = fontIncrease;
        self.color = color;
    }
    return self;
}

- (instancetype)initWithFont:(nullable UIFont *)font {
    return [self initWithFont:font maxLevel:0 fontIncrease:2 color:nil];
}

- (instancetype)init {
    return [self initWithFont:[NEMarkdownHeader defaultFont]];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    NSString *level = self.maxLevel > 0 ? [NSString stringWithFormat:@"%ld", (long)self.maxLevel] : @"";
    return [NSString stringWithFormat:NEMarkdownHeaderRegexTemplate, level];
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
    [attributedString deleteCharactersInRange:range];
}

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level {
    [attributedString addAttributes:[self attributesForLevel:level - 1] range:range];
}

- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level {
    NSMutableDictionary *attrs = [self.attributes mutableCopy];
    if (self.font) {
        CGFloat headerFontSize = self.font.pointSize + 4 + (-1 * (CGFloat)level * (CGFloat)self.fontIncrease);
        UIFont *boldFont = [[self.font fontWithSize:headerFontSize] ne_bold];
        if (boldFont) {
            attrs[NSFontAttributeName] = boldFont;
        }
    }
    return [attrs copy];
}

@end
