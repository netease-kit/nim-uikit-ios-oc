// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
/// 与 UITableViewCell 自带的 selectionStyle 不同：本实现不改变 selectionStyle，
/// 因此按下期间不会出现系统灰/系统选中高亮；只在选中后覆盖底色，
/// 取消选中时还原 cell 配置后的原始底色（置顶会话等特殊底色因此得以保留）。
@interface UITableViewCell (NEAdaptiveSelection)

/// 记录 cell 配置完成后的原始底色。每次配置 cell 后调用一次。
- (void)ne_captureAdaptiveSelectionBackground;

/// 应用/还原选中底色。
/// @param color 选中色；nil 时还原原始底色。
/// @param selected 当前 cell 是否选中。
- (void)ne_applyAdaptiveSelectionColor:(nullable UIColor *)color selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
