// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 所有 Markdown Element 的基础协议，通过正则表达式处理解析。
@protocol NEMarkdownElement <NSObject>

@required
/// 正则表达式字符串
@property (nonatomic, readonly) NSString *regex;

/// 返回编译好的正则表达式，可能抛出异常
- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error;

/// 对 attributedString 执行解析（默认实现在 NEMarkdownElementBase 中）
- (void)parse:(NSMutableAttributedString *)attributedString;

/// 处理单个匹配结果
- (void)match:(NSTextCheckingResult *)match
attributedString:(NSMutableAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
