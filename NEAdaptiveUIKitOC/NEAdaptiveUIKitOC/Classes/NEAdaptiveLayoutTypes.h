// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEAdaptiveLayoutMode) {
  NEAdaptiveLayoutModeCompact = 0,
  NEAdaptiveLayoutModeMedium,
  NEAdaptiveLayoutModeExpanded,
};

/// 降级原因。`NEAdaptiveLayoutFallbackNone` 表示按当前形态正常出布局。
typedef NS_ENUM(NSInteger, NEAdaptiveLayoutFallback) {
  NEAdaptiveLayoutFallbackNone = 0,
  NEAdaptiveLayoutFallbackInvalidInput,
  NEAdaptiveLayoutFallbackInsufficientSingleContent,
  NEAdaptiveLayoutFallbackInsufficientPairedContent,
};

/// 原始窗口几何；insets 属于窗口自身，不是已经内缩过的内容宿主。
typedef struct {
  CGFloat width;
  CGFloat height;
  CGFloat top;
  CGFloat left;
  CGFloat bottom;
  CGFloat right;
} NEAdaptiveWindowGeometry;

/// 单档位的列宽偏好与上限。
typedef struct {
  CGFloat preferredMasterWidth;
  CGFloat maximumMasterWidth;
} NEAdaptiveColumnConfiguration;

typedef struct {
  CGFloat mediumThreshold;
  CGFloat expandedThreshold;
  CGFloat compactAspectRatio;
  BOOL railUsesTrailingEdge;
  CGFloat railWidth;
  CGFloat singleContentMinimumWidth;
  CGFloat masterMinimumWidth;
  CGFloat detailMinimumWidth;
  CGFloat dividerWidth;
  NEAdaptiveColumnConfiguration medium;
  NEAdaptiveColumnConfiguration expanded;
} NEAdaptiveLayoutConfiguration;

typedef struct {
  BOOL hasMode;
  NEAdaptiveLayoutMode mode;
  NEAdaptiveLayoutFallback fallback;
  CGFloat contentWidth;
  CGFloat contentHeight;
  CGFloat masterWidth;
  CGFloat detailWidth;
  CGFloat dividerWidth;
} NEAdaptiveLayoutDecision;

FOUNDATION_EXPORT NEAdaptiveWindowGeometry NEAdaptiveWindowGeometryMake(CGFloat width,
                                                                        CGFloat height,
                                                                        CGFloat top,
                                                                        CGFloat left,
                                                                        CGFloat bottom,
                                                                        CGFloat right);

FOUNDATION_EXPORT NEAdaptiveWindowGeometry NEAdaptiveWindowGeometryMakeSimple(CGFloat width, CGFloat height);

FOUNDATION_EXPORT NEAdaptiveColumnConfiguration NEAdaptiveColumnConfigurationMake(CGFloat preferredMasterWidth,
                                                                                  CGFloat maximumMasterWidth);

FOUNDATION_EXPORT NEAdaptiveLayoutConfiguration
NEAdaptiveLayoutConfigurationMake(CGFloat railWidth,
                                  CGFloat singleContentMinimumWidth,
                                  CGFloat masterMinimumWidth,
                                  CGFloat detailMinimumWidth,
                                  CGFloat dividerWidth,
                                  NEAdaptiveColumnConfiguration medium,
                                  NEAdaptiveColumnConfiguration expanded);

FOUNDATION_EXPORT NEAdaptiveLayoutDecision NEAdaptiveLayoutDecisionLegacy(NEAdaptiveLayoutFallback fallback);

NS_ASSUME_NONNULL_END
