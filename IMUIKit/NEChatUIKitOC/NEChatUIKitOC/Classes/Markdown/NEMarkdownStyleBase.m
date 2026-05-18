// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownStyleBase.h"

@implementation NEMarkdownStyleBase

/// 对应 Swift NEMarkdownStyle protocol extension 中的 attributes 默认实现：
/// 由 font 和 color 合成属性字典。
- (NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    if (self.font) attrs[NSFontAttributeName] = self.font;
    if (self.color) attrs[NSForegroundColorAttributeName] = self.color;
    return [attrs copy];
}

@end
