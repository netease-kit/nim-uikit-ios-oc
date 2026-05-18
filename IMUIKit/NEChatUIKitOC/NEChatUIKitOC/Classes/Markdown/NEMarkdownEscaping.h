// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEMarkdownElement.h"

NS_ASSUME_NONNULL_BEGIN

/// 将 \X 形式的转义字符编码为 4 位十六进制，防止后续解析误处理
@interface NEMarkdownEscaping : NSObject <NEMarkdownElement>

@end

NS_ASSUME_NONNULL_END
