// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
/// 行尾控件与左滑操作会在列尾留下空白。开启时记录原始值并接管，关闭时原样归还。
@interface UIScrollView (NEAdaptiveContentInsets)

/// 姿态变化（折叠/展开）后丢弃上一次捕获的“原始 inset”快照。
///
/// 自适应外壳在 Duo 上会接管横向安全区；旧快照里可能带着上一姿态的安全区/边距，
/// 继续沿用会把折叠态的 inset 带进展开态（或反之）。重置后下一次托管调用会
/// 按当前页面状态重新采集。实现上先还原再清缓存，避免 bottom 安全区被叠加两次。
- (void)ne_resetContentInsetsManagedByContainer;

/// 姿态变化后丢弃上一次捕获的“原始 inset”快照（同 `ne_resetContentInsetsManagedByContainer`）。
///
/// 外壳每次布局都会重新设置托管 inset；但“原始值”只在第一次托管时捕获，跨姿态
/// 继续使用会带上上一姿态的安全区，表现为折叠后整列右移、切 tab 才恢复。
- (void)ne_resetScrollIndicatorsManagedByContainer;

/// `managed == YES`：关闭安全区自动内缩、滚动指示器自动调整与可读宽度边距，
/// 按安全区补足 bottom；`managed == NO`：恢复调用前的原始值。
- (void)ne_setContentInsetsManagedByContainer:(BOOL)managed;

/// 普通 UIScrollView（包括 UICollectionView）只由容器接管滚动指示器，
/// 不改写内容 inset、layoutMargins 或 cell 安全区状态。
- (void)ne_setScrollIndicatorsManagedByContainer:(BOOL)managed;

@end

NS_ASSUME_NONNULL_END
