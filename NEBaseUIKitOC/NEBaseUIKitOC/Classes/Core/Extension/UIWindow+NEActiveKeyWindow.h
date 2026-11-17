// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (NEActiveKeyWindow)

/// 当前活跃场景的 key window（主线程使用）。
///
/// 场景窗口上；没有活跃场景时退回任一场景的 key window。
@property (nonatomic, class, readonly, nullable) UIWindow *ne_activeKeyWindow;

@end

NS_ASSUME_NONNULL_END
