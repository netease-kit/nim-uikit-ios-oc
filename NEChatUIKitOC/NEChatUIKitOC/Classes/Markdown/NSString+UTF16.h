// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (UTF16)

/// 将每个字符转换为 4 位十六进制 UTF-16 编码（例如 "H" -> "0048"）
- (NSString *)ne_escapeUTF16;

/// 将每 4 个字符的十六进制字符串还原为对应字符（例如 "0048" -> "H"）
/// 若长度不是 4 的倍数，返回 self 本身
- (nullable NSString *)ne_unescapeUTF16;

@end

NS_ASSUME_NONNULL_END
