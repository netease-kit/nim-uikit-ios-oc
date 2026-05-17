// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownParser.h"
#import "NEMarkdownCodeEscaping.h"
#import "NEMarkdownEscaping.h"
#import "NEMarkdownUnescaping.h"

@interface NEMarkdownParser ()
@property (nonatomic, strong, readwrite) NEMarkdownHeader *header;
@property (nonatomic, strong, readwrite) NEMarkdownList *list;
@property (nonatomic, strong, readwrite) NEMarkdownQuote *quote;
@property (nonatomic, strong, readwrite) NEMarkdownLink *link;
@property (nonatomic, strong, readwrite) NEMarkdownAutomaticLink *automaticLink;
@property (nonatomic, strong, readwrite) NEMarkdownBold *bold;
@property (nonatomic, strong, readwrite) NEMarkdownItalic *italic;
@property (nonatomic, strong, readwrite) NEMarkdownCode *code;
@property (nonatomic, strong, readwrite) NEMarkdownStrikethrough *strikethrough;
@property (nonatomic, strong, readwrite) NEMarkdownTable *table;
@property (nonatomic, strong, readwrite) NEMarkdownOrderedList *orderedList;
@property (nonatomic, strong, readwrite) NEMarkdownHorizontalRule *horizontalRule;
@property (nonatomic, strong, readwrite) NEMarkdownImage *markdownImage;
@property (nonatomic, strong, readwrite) UIFont *font;
@property (nonatomic, strong, readwrite) UIColor *color;

@property (nonatomic, strong) NSArray<id<NEMarkdownElement>> *escapingElements;
@property (nonatomic, strong) NSArray<id<NEMarkdownElement>> *defaultElements;
@property (nonatomic, strong) NSArray<id<NEMarkdownElement>> *unescapingElements;

@property (nonatomic, strong) NEMarkdownCodeEscaping *codeEscaping;
@property (nonatomic, strong) NEMarkdownEscaping *escaping;
@property (nonatomic, strong) NEMarkdownUnescaping *unescaping;
@end

@implementation NEMarkdownParser

+ (UIFont *)defaultFont {
    return [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
}

+ (UIColor *)defaultColor {
    return UIColor.blackColor;
}

- (instancetype)initWithFont:(UIFont *)font
                       color:(UIColor *)color
             enabledElements:(NEEnabledElements)enabledElements
              customElements:(NSArray<id<NEMarkdownElement>> *)customElements {
    self = [super init];
    if (self) {
        _font = font;
        _color = color;

        _header = [[NEMarkdownHeader alloc] initWithFont:font];
        _list = [[NEMarkdownList alloc] initWithFont:font];
        _quote = [[NEMarkdownQuote alloc] initWithFont:font];
        _link = [[NEMarkdownLink alloc] initWithFont:font color:[NEMarkdownLink defaultColor]];
        _automaticLink = [[NEMarkdownAutomaticLink alloc] initWithFont:font color:[NEMarkdownLink defaultColor]];
        _bold = [[NEMarkdownBold alloc] initWithFont:font color:nil];
        _italic = [[NEMarkdownItalic alloc] initWithFont:font color:nil];
        _code = [[NEMarkdownCode alloc] init];
        _strikethrough = [[NEMarkdownStrikethrough alloc] init];
        _table = [[NEMarkdownTable alloc] init];
        _orderedList = [[NEMarkdownOrderedList alloc] initWithFont:font];
        _horizontalRule = [[NEMarkdownHorizontalRule alloc] init];
        _markdownImage = [[NEMarkdownImage alloc] init];

        _codeEscaping = [[NEMarkdownCodeEscaping alloc] init];
        _escaping = [[NEMarkdownEscaping alloc] init];
        _unescaping = [[NEMarkdownUnescaping alloc] init];

        _customElements = customElements ?: @[];
        _enabledElements = enabledElements;

        [self updateDefaultElements];
        [self updateEscapingElements];
        [self updateUnescapingElements];
    }
    return self;
}

- (instancetype)initWithFont:(UIFont *)font {
    return [self initWithFont:font
                        color:[NEMarkdownParser defaultColor]
              enabledElements:NEEnabledElementAll
               customElements:@[]];
}

- (instancetype)init {
    return [self initWithFont:[NEMarkdownParser defaultFont]];
}

- (void)setEnabledElements:(NEEnabledElements)enabledElements {
    _enabledElements = enabledElements;
    [self updateDefaultElements];
    [self updateEscapingElements];
    [self updateUnescapingElements];
}

#pragma mark - 解析

- (NSAttributedString *)parseMarkdownString:(NSString *)markdown {
    return [self parseMarkdownAttributedString:[[NSAttributedString alloc] initWithString:markdown]];
}

- (NSAttributedString *)parseMarkdownAttributedString:(NSAttributedString *)markdown {
    // 第一步：如果启用表格，先对纯文本做表格预处理
    NSAttributedString *preprocessed;
    if (_enabledElements & NEEnabledElementTable) {
        preprocessed = [_table preprocessText:markdown.string font:_font color:_color];
    } else {
        preprocessed = markdown;
    }

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:preprocessed];
    [attributedString addAttribute:NSFontAttributeName value:_font
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:_color
                             range:NSMakeRange(0, attributedString.length)];

    // 第二步：依次运行所有 element
    NSMutableArray<id<NEMarkdownElement>> *elements = [NSMutableArray array];
    [elements addObjectsFromArray:_escapingElements];
    for (id<NEMarkdownElement> element in _defaultElements) {
        if (element != (id<NEMarkdownElement>)_table) {
            [elements addObject:element];
        }
    }
    [elements addObjectsFromArray:_customElements];
    [elements addObjectsFromArray:_unescapingElements];

    for (id<NEMarkdownElement> element in elements) {
        [element parse:attributedString];
    }
    return [attributedString copy];
}

#pragma mark - Element 管理

- (void)addCustomElement:(id<NEMarkdownElement>)element {
    NSMutableArray *arr = [_customElements mutableCopy];
    [arr addObject:element];
    _customElements = [arr copy];
}

- (void)removeCustomElement:(id<NEMarkdownElement>)element {
    NSMutableArray *arr = [_customElements mutableCopy];
    NSUInteger idx = [arr indexOfObjectPassingTest:^BOOL(id<NEMarkdownElement> obj, NSUInteger i, BOOL *stop) {
        return obj == element;
    }];
    if (idx != NSNotFound) {
        [arr removeObjectAtIndex:idx];
    }
    _customElements = [arr copy];
}

#pragma mark - 私有更新方法

- (void)updateDefaultElements {
    NSMutableArray<id<NEMarkdownElement>> *elements = [NSMutableArray array];
    struct {
        NEEnabledElements flag;
        id<NEMarkdownElement> element;
    } pairs[] = {
        {NEEnabledElementImage,          _markdownImage},
        {NEEnabledElementHorizontalRule, _horizontalRule},
        {NEEnabledElementTable,          _table},
        {NEEnabledElementAutomaticLink,  _automaticLink},
        {NEEnabledElementHeader,         _header},
        {NEEnabledElementList,           _list},
        {NEEnabledElementOrderedList,    _orderedList},
        {NEEnabledElementQuote,          _quote},
        {NEEnabledElementLink,           _link},
        {NEEnabledElementBold,           _bold},
        {NEEnabledElementItalic,         _italic},
        {NEEnabledElementCode,           _code},
        {NEEnabledElementStrikethrough,  _strikethrough},
    };
    NSInteger count = sizeof(pairs) / sizeof(pairs[0]);
    for (NSInteger i = 0; i < count; i++) {
        if (_enabledElements & pairs[i].flag) {
            [elements addObject:pairs[i].element];
        }
    }
    _defaultElements = [elements copy];
}

- (void)updateEscapingElements {
    if (_enabledElements & NEEnabledElementCode) {
        _escapingElements = @[_codeEscaping, _escaping];
    } else {
        _escapingElements = @[_escaping];
    }
}

- (void)updateUnescapingElements {
    if (_enabledElements & NEEnabledElementCode) {
        _unescapingElements = @[_code, _unescaping];
    } else {
        _unescapingElements = @[_unescaping];
    }
}

@end
