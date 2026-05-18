// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEMarkdownElement.h"

NS_ASSUME_NONNULL_BEGIN

/// 代码块转义 Element：将代码内容的每个字符转换为 4 位十六进制，防止 Markdown 符号被误处理。
@interface NEMarkdownCodeEscaping : NSObject <NEMarkdownElement>

@end

NS_ASSUME_NONNULL_END
