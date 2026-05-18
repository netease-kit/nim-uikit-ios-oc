// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"
#import "NEMarkdownStyle.h"

NS_ASSUME_NONNULL_BEGIN

/// CommonElement 协议：既是 NEMarkdownElement 又是 NEMarkdownStyle，
/// 提供 addAttributes:range: 的默认实现，并通过 group(2/3/4) 删除 Markdown 标记符号。
@protocol NEMarkdownCommonElement <NEMarkdownElement, NEMarkdownStyle>

@optional
- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
