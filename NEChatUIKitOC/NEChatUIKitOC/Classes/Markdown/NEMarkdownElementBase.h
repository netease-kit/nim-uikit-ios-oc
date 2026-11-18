// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEMarkdownElement.h"

NS_ASSUME_NONNULL_BEGIN

/// NEMarkdownElement 协议的 NSObject 基类，提供 parse 的默认实现。
///
/// 对应 Swift 中 NEMarkdownElement protocol extension 的 default implementation：
/// 通过正则表达式循环匹配 attributedString，对每个匹配结果调用 match:attributedString:。
///
/// 子类必须实现：
///   - regex（@property readonly NSString *regex）
///   - regularExpressionWithError:
///   - match:attributedString:
///
/// 子类可覆盖 parse: 以使用不同的正则选项（如 NEMarkdownHeader 需要 AnchorsMatchLines）。
@interface NEMarkdownElementBase : NSObject <NEMarkdownElement>

/// 默认 parse 实现：使用 regularExpressionWithError: 获取正则，循环 firstMatch 并调用 match:attributedString:。
/// 子类通常不需要覆盖此方法，仅当需要特殊正则选项时才覆盖。
- (void)parse:(NSMutableAttributedString *)attributedString;

@end

NS_ASSUME_NONNULL_END
