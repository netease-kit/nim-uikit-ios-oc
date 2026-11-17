// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownHorizontalRule.h"

static NSString * const NEMarkdownHorizontalRuleRegex = @"^[ \\t]*([\\-\\*\\_][ \\t]*){3,}[ \\t]*$";

// MARK: - 私有 Attachment 类

@interface NEMarkdownHorizontalRuleAttachment : NSTextAttachment
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, assign) CGFloat verticalPadding;

- (instancetype)initWithLineColor:(UIColor *)lineColor
                       lineHeight:(CGFloat)lineHeight
                  verticalPadding:(CGFloat)verticalPadding;
@end

@implementation NEMarkdownHorizontalRuleAttachment

- (instancetype)initWithLineColor:(UIColor *)lineColor
                       lineHeight:(CGFloat)lineHeight
                  verticalPadding:(CGFloat)verticalPadding {
    self = [super initWithData:nil ofType:nil];
    if (self) {
        _lineColor = lineColor;
        _lineHeight = lineHeight;
        _verticalPadding = verticalPadding;
    }
    return self;
}

- (CGRect)attachmentBoundsForTextContainer:(nullable NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
    CGFloat width = lineFrag.size.width;
    CGFloat height = _lineHeight + _verticalPadding * 2;
    return CGRectMake(0, 0, width, height);
}

- (nullable UIImage *)imageForBounds:(CGRect)imageBounds
                       textContainer:(nullable NSTextContainer *)textContainer
                       characterIndex:(NSUInteger)charIndex {
    CGSize size = imageBounds.size;
    if (size.width <= 0 || size.height <= 0) return nil;

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [self.lineColor setFill];
        CGRect lineRect = CGRectMake(0, self.verticalPadding, size.width, self.lineHeight);
        [ctx fillRect:lineRect];
    }];
}

@end

// MARK: - NEMarkdownHorizontalRule

@implementation NEMarkdownHorizontalRule

- (instancetype)initWithLineColor:(nullable UIColor *)lineColor {
    self = [super init];
    if (self) {
        _lineColor = lineColor ?: [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0];
        _lineHeight = 1.0;
        _verticalPadding = 6.0;
    }
    return self;
}

- (instancetype)init {
    return [self initWithLineColor:nil];
}

#pragma mark - NEMarkdownElement

- (NSString *)regex {
    return NEMarkdownHorizontalRuleRegex;
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
    NEMarkdownHorizontalRuleAttachment *attachment =
        [[NEMarkdownHorizontalRuleAttachment alloc] initWithLineColor:self.lineColor
                                                          lineHeight:self.lineHeight
                                                     verticalPadding:self.verticalPadding];
    NSAttributedString *lineAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributedString replaceCharactersInRange:match.range withAttributedString:lineAttrStr];
}

@end
