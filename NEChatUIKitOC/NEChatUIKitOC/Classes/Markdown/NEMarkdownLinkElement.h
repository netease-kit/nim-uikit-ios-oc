// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"
#import "NEMarkdownStyle.h"

NS_ASSUME_NONNULL_BEGIN

/// LinkElement 协议：链接类 Markdown 元素的基础协议
@protocol NEMarkdownLinkElement <NEMarkdownElement, NEMarkdownStyle>

@required
- (void)formatText:(NSMutableAttributedString *)attributedString range:(NSRange)range link:(NSString *)link;
- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range link:(NSString *)link;

@end

NS_ASSUME_NONNULL_END
