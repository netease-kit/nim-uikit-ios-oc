// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"
#import "NEMarkdownHeader.h"
#import "NEMarkdownList.h"
#import "NEMarkdownQuote.h"
#import "NEMarkdownLink.h"
#import "NEMarkdownAutomaticLink.h"
#import "NEMarkdownBold.h"
#import "NEMarkdownItalic.h"
#import "NEMarkdownCode.h"
#import "NEMarkdownStrikethrough.h"
#import "NEMarkdownTable.h"
#import "NEMarkdownOrderedList.h"
#import "NEMarkdownHorizontalRule.h"
#import "NEMarkdownImage.h"

NS_ASSUME_NONNULL_BEGIN

/// 启用的 Markdown 元素选项（NS_OPTIONS，可位运算组合）
typedef NS_OPTIONS(NSUInteger, NEEnabledElements) {
    NEEnabledElementAutomaticLink  = 1 << 0,
    NEEnabledElementHeader         = 1 << 1,
    NEEnabledElementList           = 1 << 2,
    NEEnabledElementQuote          = 1 << 3,
    NEEnabledElementLink           = 1 << 4,
    NEEnabledElementBold           = 1 << 5,
    NEEnabledElementItalic         = 1 << 6,
    NEEnabledElementCode           = 1 << 7,
    NEEnabledElementStrikethrough  = 1 << 8,
    NEEnabledElementTable          = 1 << 9,
    NEEnabledElementOrderedList    = 1 << 10,
    NEEnabledElementHorizontalRule = 1 << 11,
    NEEnabledElementImage          = 1 << 12,

    NEEnabledElementDisabledAutomaticLink =
        NEEnabledElementHeader | NEEnabledElementList | NEEnabledElementQuote |
        NEEnabledElementLink | NEEnabledElementBold | NEEnabledElementItalic |
        NEEnabledElementCode | NEEnabledElementStrikethrough | NEEnabledElementTable |
        NEEnabledElementOrderedList | NEEnabledElementHorizontalRule | NEEnabledElementImage,

    NEEnabledElementAll =
        NEEnabledElementDisabledAutomaticLink | NEEnabledElementAutomaticLink,
};

/// Markdown 解析器
@interface NEMarkdownParser : NSObject

// MARK: - 基础 Elements
@property (nonatomic, strong, readonly) NEMarkdownHeader *header;
@property (nonatomic, strong, readonly) NEMarkdownList *list;
@property (nonatomic, strong, readonly) NEMarkdownQuote *quote;
@property (nonatomic, strong, readonly) NEMarkdownLink *link;
@property (nonatomic, strong, readonly) NEMarkdownAutomaticLink *automaticLink;
@property (nonatomic, strong, readonly) NEMarkdownBold *bold;
@property (nonatomic, strong, readonly) NEMarkdownItalic *italic;
@property (nonatomic, strong, readonly) NEMarkdownCode *code;
@property (nonatomic, strong, readonly) NEMarkdownStrikethrough *strikethrough;
@property (nonatomic, strong, readonly) NEMarkdownTable *table;
@property (nonatomic, strong, readonly) NEMarkdownOrderedList *orderedList;
@property (nonatomic, strong, readonly) NEMarkdownHorizontalRule *horizontalRule;
@property (nonatomic, strong, readonly) NEMarkdownImage *markdownImage;

// MARK: - 配置
@property (nonatomic, strong, readonly) UIFont *font;
@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, assign) NEEnabledElements enabledElements;
@property (nonatomic, strong) NSArray<id<NEMarkdownElement>> *customElements;

// MARK: - 默认值
@property (class, nonatomic, readonly) UIFont *defaultFont;
@property (class, nonatomic, readonly) UIColor *defaultColor;

// MARK: - 初始化
- (instancetype)initWithFont:(UIFont *)font
                       color:(UIColor *)color
             enabledElements:(NEEnabledElements)enabledElements
              customElements:(NSArray<id<NEMarkdownElement>> *)customElements;

- (instancetype)initWithFont:(UIFont *)font;

// MARK: - 解析
- (NSAttributedString *)parseMarkdownString:(NSString *)markdown;
- (NSAttributedString *)parseMarkdownAttributedString:(NSAttributedString *)markdown;

// MARK: - 自定义 Element 管理
- (void)addCustomElement:(id<NEMarkdownElement>)element;
- (void)removeCustomElement:(id<NEMarkdownElement>)element;

@end

NS_ASSUME_NONNULL_END
