// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"

NS_ASSUME_NONNULL_BEGIN

/// 分隔线渲染 Element。
/// 支持标准 GFM 分隔线语法（---、***、___，允许中间有空格）。
/// 将分隔线替换为自适应宽度的横线图片（NSTextAttachment）。
@interface NEMarkdownHorizontalRule : NSObject <NEMarkdownElement>

/// 分隔线颜色
@property (nonatomic, strong) UIColor *lineColor;
/// 分隔线高度（pt）
@property (nonatomic, assign) CGFloat lineHeight;
/// 分隔线上下额外间距
@property (nonatomic, assign) CGFloat verticalPadding;

- (instancetype)initWithLineColor:(nullable UIColor *)lineColor;

@end

NS_ASSUME_NONNULL_END
