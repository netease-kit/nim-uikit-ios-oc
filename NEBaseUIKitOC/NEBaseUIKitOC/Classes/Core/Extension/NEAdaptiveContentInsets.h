// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
/// 行尾控件与左滑操作会在列尾留下空白。开启时记录原始值并接管，关闭时原样归还。
@interface UIScrollView (NEAdaptiveContentInsets)

/// `managed == YES`：关闭安全区自动内缩、滚动指示器自动调整与可读宽度边距，
/// 按安全区补足 bottom；`managed == NO`：恢复调用前的原始值。
- (void)ne_setContentInsetsManagedByContainer:(BOOL)managed;

/// 普通 UIScrollView（包括 UICollectionView）只由容器接管滚动指示器，
/// 不改写内容 inset、layoutMargins 或 cell 安全区状态。
- (void)ne_setScrollIndicatorsManagedByContainer:(BOOL)managed;

@end

NS_ASSUME_NONNULL_END
