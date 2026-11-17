// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveLayoutTypes.h"

NS_ASSUME_NONNULL_BEGIN

/// 纯几何策略：每次调用独立计算，不读全局几何、SDK 状态、键盘，也不持有视图。
@interface NEAdaptiveLayoutPolicy : NSObject

/// 只有内容宽度满足双栏最小宽才出 `medium` / `expanded`。
///
+ (NEAdaptiveLayoutDecision)resolveWithWindow:(NEAdaptiveWindowGeometry)window
                                configuration:(NEAdaptiveLayoutConfiguration)configuration;

@end

NS_ASSUME_NONNULL_END
