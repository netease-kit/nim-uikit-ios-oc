// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 页面自绘标题栏的统一返回按钮。
///
/// 与 `NENavigationView` 的返回按钮共用同一张皮肤返回图和 32pt 命中高度。
/// 自绘标题栏中的「取消」文本返回入口统一替换为该按钮，原文案只保留为
@interface NEUnifiedBackButton : UIButton

/// 与导航栏返回按钮一致的默认尺寸（宽 × 高）。
@property (nonatomic, class, readonly) CGSize unifiedSize;

/// 指定初始化：`accessibilityLabel` 保留原入口语义（如「取消」「关闭」）。
- (instancetype)initWithAccessibilityLabel:(nullable NSString *)accessibilityLabel;

@end

NS_ASSUME_NONNULL_END
