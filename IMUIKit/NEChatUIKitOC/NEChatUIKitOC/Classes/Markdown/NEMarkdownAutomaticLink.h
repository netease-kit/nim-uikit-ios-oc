// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownLink.h"

NS_ASSUME_NONNULL_BEGIN

/// 自动链接检测 Element（使用 NSDataDetector 检测文字中的 URL）
@interface NEMarkdownAutomaticLink : NEMarkdownLink

@end

NS_ASSUME_NONNULL_END
