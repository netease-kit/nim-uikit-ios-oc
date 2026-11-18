// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 长按菜单的最终位置：纯几何，不读屏幕常量、不依赖视图层级，便于单测。
///
/// 1. 原消息不在 `visibleRect` 内时不出菜单（返回 NO）；
/// 2. 纵向优先放在消息上方，上方放不下则放下方；
/// 3. 横向按 `containerBounds` 夹取，左右各留 `margin`，绝不越出详情列。
FOUNDATION_EXPORT BOOL ChatMenuFrameForMessage(CGRect messageRect,
                                               CGRect containerBounds,
                                               CGRect visibleRect,
                                               CGSize menuSize,
                                               CGFloat margin,
                                               CGRect *_Nullable outFrame);

NS_ASSUME_NONNULL_END
