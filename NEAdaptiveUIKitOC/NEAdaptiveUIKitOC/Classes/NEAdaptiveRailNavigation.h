// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
/// 按钮，因此数量、权限、禁用态和业务回调始终只有页面一个权威来源。
@interface NEAdaptiveRailAction : NSObject

/// 按钮文本；有文本时优先展示文本（产品稿要求右侧按钮保留原文案）。
@property (nonatomic, copy, nullable) NSString *title;
/// 文本尾部计数拆出的角标（如「确定(10)」中的 10）。
@property (nonatomic, copy, nullable) NSString *badge;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, copy, nullable) NSString *accessibilityText;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, copy, nullable) NSString *identifier;
/// 转发目标（页面原按钮的 target）；弱引用，页面销毁后点击自动失效。
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign, nullable) SEL selector;
/// 直接回调；优先于 `target` / `selector`。
@property (nonatomic, copy, nullable) void (^handler)(void);

/// 与页面原按钮完全一致的点击语义。
- (void)perform;

@end

NS_ASSUME_NONNULL_END
