// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownCode.h"
#import "NSString+UTF16.h"

static NSString * const NEMarkdownCodeRegex = @"(.?|^)(\\`{1,3})(.+?)(\\2)";

@implementation NEMarkdownCode

+ (UIColor *)defaultHighlightColor {
    return [UIColor colorWithRed:0.90 green:0.20 blue:0.40 alpha:1.0];
}

+ (UIColor *)defaultBackgroundColor {
    return [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
}

+ (nullable UIFont *)defaultFont {
    return [UIFont fontWithName:@"Menlo-Regular" size:16];
}

- (instancetype)initWithFont:(nullable UIFont *)font
                       color:(nullable UIColor *)color
          textHighlightColor:(nullable UIColor *)textHighlightColor
         textBackgroundColor:(nullable UIColor *)textBackgroundColor {
    self = [super init];
    if (self) {
        self.font = font;
        self.color = color;
        self.textHighlightColor = textHighlightColor;
        self.textBackgroundColor = textBackgroundColor;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFont:[NEMarkdownCode defaultFont]
                        color:nil
           textHighlightColor:[NEMarkdownCode defaultHighlightColor]
          textBackgroundColor:[NEMarkdownCode defaultBackgroundColor]];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    return NEMarkdownCodeRegex;
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
    // 删除尾部标记 group(4)
    [attributedString deleteCharactersInRange:[match rangeAtIndex:4]];
    // 应用样式到 group(3)
    [self addAttributes:attributedString range:[match rangeAtIndex:3]];
    // 删除头部标记 group(2)
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
    NSString *matchString = [attributedString attributedSubstringFromRange:range].string;
    NSString *unescapedString = [matchString ne_unescapeUTF16];
    if (!unescapedString) return;

    [attributedString replaceCharactersInRange:range withString:unescapedString];

    NSMutableDictionary *codeAttributes = [self.attributes mutableCopy];
    if (self.textHighlightColor) {
        codeAttributes[NSForegroundColorAttributeName] = self.textHighlightColor;
    }
    if (self.textBackgroundColor) {
        codeAttributes[NSBackgroundColorAttributeName] = self.textBackgroundColor;
    }
    if (self.font) {
        codeAttributes[NSFontAttributeName] = self.font;
    }

    // 直接用 range.location + unescapedString.length 计算应用范围
    NSRange applyRange = NSMakeRange(range.location, unescapedString.length);
    [attributedString addAttributes:codeAttributes range:applyRange];
}

@end
