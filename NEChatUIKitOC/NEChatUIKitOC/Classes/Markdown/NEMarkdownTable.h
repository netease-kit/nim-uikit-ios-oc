// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"
#import "NEMarkdownTableView.h"

NS_ASSUME_NONNULL_BEGIN

/// Markdown 表格解析 Element（GFM 表格语法）
/// 作为预处理器使用，在其他 Element 之前将表格块替换为 NSTextAttachment。
@interface NEMarkdownTable : NSObject <NEMarkdownElement>

@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, strong) UIFont *headerFont;
@property (nonatomic, strong) UIFont *cellFont;
@property (nonatomic, assign) CGFloat cellPadding;
@property (nonatomic, assign) CGFloat borderWidth;

- (instancetype)initWithMaxWidth:(CGFloat)maxWidth;

/// 扫描原始 Markdown 字符串，将 GFM 表格块替换为 NSTextAttachment
- (NSAttributedString *)preprocessText:(NSString *)rawText
                                  font:(UIFont *)font
                                 color:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
