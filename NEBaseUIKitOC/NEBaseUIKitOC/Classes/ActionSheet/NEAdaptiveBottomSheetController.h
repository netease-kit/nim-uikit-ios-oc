// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 可在内容列内嵌的底部弹窗基类。
/// 未嵌列时保持原 modal dismiss 行为。
@interface NEAdaptiveBottomSheetController : UIViewController

/// 列内嵌时的关闭回调；为 nil 时保持原 modal dismiss。
@property (nonatomic, copy, nullable) void (^columnDismissHandler)(void);

/// 嵌入承载页的内容区域（列）。
- (void)embedInColumnWithPresenter:(UIViewController *)presenter container:(UIView *)container;

/// 解除列内嵌入。
- (void)detachFromColumn;

@end

NS_ASSUME_NONNULL_END
