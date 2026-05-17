// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (Traits)

/// 返回带有指定符号特征的新字体，失败时返回 nil
- (nullable UIFont *)ne_fontWithTraits:(UIFontDescriptorSymbolicTraits)traits;

/// 返回粗体版本
- (nullable UIFont *)ne_bold;

/// 返回斜体版本
- (nullable UIFont *)ne_italic;

@end

NS_ASSUME_NONNULL_END
