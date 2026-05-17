// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownLink.h"

static NSString * const NEMarkdownLinkRegex = @"\\[[^\\]]+\\]\\(\\S+(?=\\))\\)";
static NSString * const NEMarkdownLinkOnlyLinkRegex = @"\\(\\S+(?=\\))\\)";

@implementation NEMarkdownLink

+ (UIColor *)defaultColor {
    return UIColor.blueColor;
}

- (instancetype)initWithFont:(nullable UIFont *)font color:(nullable UIColor *)color {
    self = [super init];
    if (self) {
        self.font = font;
        self.color = color ?: [NEMarkdownLink defaultColor];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFont:nil color:[NEMarkdownLink defaultColor]];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    return NEMarkdownLinkRegex;
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
    NSString *string = attributedString.string;
    NSString *urlString = [string substringWithRange:match.range];

    NSError *error = nil;
    NSRegularExpression *onlyLinkRegex =
        [NSRegularExpression regularExpressionWithPattern:NEMarkdownLinkOnlyLinkRegex
                                                  options:NSRegularExpressionDotMatchesLineSeparators
                                                    error:&error];
    if (!onlyLinkRegex) return;

    NSRange searchRange = NSMakeRange(0, urlString.length);
    NSTextCheckingResult *linkMatch = [onlyLinkRegex firstMatchInString:urlString
                                                                options:NSMatchingWithoutAnchoringBounds
                                                                  range:searchRange];
    if (!linkMatch) return;

    NSInteger urlLinkAbsoluteStart = match.range.location;

    NSString *linkURLString = [string substringWithRange:
        NSMakeRange(urlLinkAbsoluteStart + linkMatch.range.location + 1,
                    linkMatch.range.length - 2)];

    // 删除尾部 Markdown
    NSRange trailingMarkdownRange =
        NSMakeRange(urlLinkAbsoluteStart + linkMatch.range.location - 1,
                    linkMatch.range.length + 1);
    [attributedString deleteCharactersInRange:trailingMarkdownRange];

    // 删除头部 [
    NSRange leadingMarkdownRange = NSMakeRange(match.range.location, 1);
    [attributedString deleteCharactersInRange:leadingMarkdownRange];

    NSRange formatRange = NSMakeRange(match.range.location, linkMatch.range.location - 2);

    [self formatText:attributedString range:formatRange link:linkURLString];
    [self addAttributes:attributedString range:formatRange link:linkURLString];
}

#pragma mark - NEMarkdownStyle

- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    if (self.font) attrs[NSFontAttributeName] = self.font;
    if (self.color) attrs[NSForegroundColorAttributeName] = self.color;
    return [attrs copy];
}

#pragma mark - NEMarkdownLinkElement

- (void)formatText:(NSMutableAttributedString *)attributedString range:(NSRange)range link:(NSString *)link {
    NSString *encodedLink = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:link] ?: (encodedLink ? [NSURL URLWithString:encodedLink] : nil);
    if (!url) return;
    [attributedString addAttribute:NSLinkAttributeName value:url range:range];
}

- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range link:(NSString *)link {
    [attributedString addAttributes:self.attributes range:range];
}

@end
