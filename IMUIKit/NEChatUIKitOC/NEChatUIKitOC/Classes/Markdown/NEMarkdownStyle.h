// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 所有 NEMarkdownElement 的样式协议
@protocol NEMarkdownStyle <NSObject>

@optional
/// 字体（nil 表示不设置）
@property (nonatomic, strong, nullable) UIFont *font;
/// 颜色（nil 表示不设置）
@property (nonatomic, strong, nullable) UIColor *color;

@required
/// 返回由 font 和 color 合成的属性字典
@property (nonatomic, readonly) NSDictionary<NSAttributedStringKey, id> *attributes;

@end

NS_ASSUME_NONNULL_END
