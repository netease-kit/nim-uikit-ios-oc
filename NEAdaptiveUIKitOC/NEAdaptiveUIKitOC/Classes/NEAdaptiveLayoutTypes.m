// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveLayoutTypes.h"

NEAdaptiveWindowGeometry NEAdaptiveWindowGeometryMake(CGFloat width,
                                                      CGFloat height,
                                                      CGFloat top,
                                                      CGFloat left,
                                                      CGFloat bottom,
                                                      CGFloat right) {
  NEAdaptiveWindowGeometry geometry;
  geometry.width = width;
  geometry.height = height;
  geometry.top = top;
  geometry.left = left;
  geometry.bottom = bottom;
  geometry.right = right;
  return geometry;
}

NEAdaptiveWindowGeometry NEAdaptiveWindowGeometryMakeSimple(CGFloat width, CGFloat height) {
  return NEAdaptiveWindowGeometryMake(width, height, 0, 0, 0, 0);
}

NEAdaptiveColumnConfiguration NEAdaptiveColumnConfigurationMake(CGFloat preferredMasterWidth,
                                                                CGFloat maximumMasterWidth) {
  NEAdaptiveColumnConfiguration configuration;
  configuration.preferredMasterWidth = preferredMasterWidth;
  configuration.maximumMasterWidth = maximumMasterWidth;
  return configuration;
}

NEAdaptiveLayoutConfiguration NEAdaptiveLayoutConfigurationMake(CGFloat railWidth,
                                                                CGFloat singleContentMinimumWidth,
                                                                CGFloat masterMinimumWidth,
                                                                CGFloat detailMinimumWidth,
                                                                CGFloat dividerWidth,
                                                                NEAdaptiveColumnConfiguration medium,
                                                                NEAdaptiveColumnConfiguration expanded) {
  NEAdaptiveLayoutConfiguration configuration;
  configuration.mediumThreshold = 600;
  configuration.expandedThreshold = 840;
  configuration.compactAspectRatio = 1.2;
  configuration.railUsesTrailingEdge = NO;
  configuration.railWidth = railWidth;
  configuration.singleContentMinimumWidth = singleContentMinimumWidth;
  configuration.masterMinimumWidth = masterMinimumWidth;
  configuration.detailMinimumWidth = detailMinimumWidth;
  configuration.dividerWidth = dividerWidth;
  configuration.medium = medium;
  configuration.expanded = expanded;
  return configuration;
}

NEAdaptiveLayoutDecision NEAdaptiveLayoutDecisionLegacy(NEAdaptiveLayoutFallback fallback) {
  NEAdaptiveLayoutDecision decision;
  decision.hasMode = NO;
  decision.mode = NEAdaptiveLayoutModeCompact;
  decision.fallback = fallback;
  decision.contentWidth = 0;
  decision.contentHeight = 0;
  decision.masterWidth = 0;
  decision.detailWidth = 0;
  decision.dividerWidth = 0;
  return decision;
}
