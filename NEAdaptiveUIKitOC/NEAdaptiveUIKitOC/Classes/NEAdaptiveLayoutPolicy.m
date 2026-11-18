// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveLayoutPolicy.h"

#import <math.h>

static BOOL NEAdaptiveIsPositiveFinite(CGFloat value) {
  return isfinite((double)value) && value > 0;
}

static BOOL NEAdaptiveIsNonNegativeFinite(CGFloat value) {
  return isfinite((double)value) && value >= 0;
}

static NEAdaptiveLayoutDecision NEAdaptiveMakeDecision(BOOL hasMode,
                                                       NEAdaptiveLayoutMode mode,
                                                       NEAdaptiveLayoutFallback fallback,
                                                       CGFloat contentWidth,
                                                       CGFloat contentHeight,
                                                       CGFloat masterWidth,
                                                       CGFloat detailWidth,
                                                       CGFloat dividerWidth) {
  NEAdaptiveLayoutDecision decision;
  decision.hasMode = hasMode;
  decision.mode = mode;
  decision.fallback = fallback;
  decision.contentWidth = contentWidth;
  decision.contentHeight = contentHeight;
  decision.masterWidth = masterWidth;
  decision.detailWidth = detailWidth;
  decision.dividerWidth = dividerWidth;
  return decision;
}

@implementation NEAdaptiveLayoutPolicy

+ (NEAdaptiveLayoutDecision)resolveWithWindow:(NEAdaptiveWindowGeometry)window
                                configuration:(NEAdaptiveLayoutConfiguration)configuration {
  NEAdaptiveLayoutConfiguration c = configuration;

  BOOL positiveInputsValid =
      NEAdaptiveIsPositiveFinite(window.width) && NEAdaptiveIsPositiveFinite(window.height) &&
      NEAdaptiveIsPositiveFinite(c.mediumThreshold) && NEAdaptiveIsPositiveFinite(c.expandedThreshold) &&
      NEAdaptiveIsPositiveFinite(c.compactAspectRatio) &&
      NEAdaptiveIsPositiveFinite(c.singleContentMinimumWidth) &&
      NEAdaptiveIsPositiveFinite(c.masterMinimumWidth) &&
      NEAdaptiveIsPositiveFinite(c.detailMinimumWidth) &&
      NEAdaptiveIsPositiveFinite(c.medium.preferredMasterWidth) &&
      NEAdaptiveIsPositiveFinite(c.medium.maximumMasterWidth) &&
      NEAdaptiveIsPositiveFinite(c.expanded.preferredMasterWidth) &&
      NEAdaptiveIsPositiveFinite(c.expanded.maximumMasterWidth);
  BOOL nonNegativeInputsValid =
      NEAdaptiveIsNonNegativeFinite(window.top) && NEAdaptiveIsNonNegativeFinite(window.left) &&
      NEAdaptiveIsNonNegativeFinite(window.bottom) && NEAdaptiveIsNonNegativeFinite(window.right) &&
      NEAdaptiveIsNonNegativeFinite(c.dividerWidth) && NEAdaptiveIsNonNegativeFinite(c.railWidth);
  BOOL thresholdsValid = c.expandedThreshold > c.mediumThreshold &&
                         c.medium.maximumMasterWidth >= c.masterMinimumWidth &&
                         c.expanded.maximumMasterWidth >= c.masterMinimumWidth;
  if (!positiveInputsValid || !nonNegativeInputsValid || !thresholdsValid) {
    return NEAdaptiveLayoutDecisionLegacy(NEAdaptiveLayoutFallbackInvalidInput);
  }

  CGFloat safeWidth = window.width - window.left - window.right;
  CGFloat safeHeight = window.height - window.top - window.bottom;
  CGFloat contentWidth = c.railUsesTrailingEdge ? (window.width - window.left - c.railWidth)
                                                : (safeWidth - c.railWidth);
  if (!isfinite((double)safeWidth) || !isfinite((double)safeHeight) ||
      !isfinite((double)contentWidth) || safeWidth <= 0 || safeHeight <= 0 ||
      contentWidth < c.singleContentMinimumWidth) {
    return NEAdaptiveLayoutDecisionLegacy(NEAdaptiveLayoutFallbackInsufficientSingleContent);
  }

  NEAdaptiveLayoutMode candidate;
  if (window.width < c.mediumThreshold || window.height / window.width >= c.compactAspectRatio) {
    candidate = NEAdaptiveLayoutModeCompact;
  } else if (window.width < c.expandedThreshold) {
    candidate = NEAdaptiveLayoutModeMedium;
  } else {
    candidate = NEAdaptiveLayoutModeExpanded;
  }

  CGFloat pairedMinimum = c.masterMinimumWidth + c.dividerWidth + c.detailMinimumWidth;
  if (!isfinite((double)pairedMinimum)) {
    return NEAdaptiveLayoutDecisionLegacy(NEAdaptiveLayoutFallbackInvalidInput);
  }

  if (candidate == NEAdaptiveLayoutModeCompact || contentWidth < pairedMinimum) {
    BOOL isCompact = (candidate == NEAdaptiveLayoutModeCompact);
    return NEAdaptiveMakeDecision(YES, NEAdaptiveLayoutModeCompact,
                                  isCompact ? NEAdaptiveLayoutFallbackNone
                                            : NEAdaptiveLayoutFallbackInsufficientPairedContent,
                                  contentWidth, safeHeight, 0, contentWidth, 0);
  }

  NEAdaptiveColumnConfiguration columns =
      (candidate == NEAdaptiveLayoutModeMedium) ? c.medium : c.expanded;
  CGFloat upper = MIN(columns.maximumMasterWidth, contentWidth - c.dividerWidth - c.detailMinimumWidth);
  CGFloat master = MIN(MAX(columns.preferredMasterWidth, c.masterMinimumWidth), upper);
  return NEAdaptiveMakeDecision(YES, candidate, NEAdaptiveLayoutFallbackNone, contentWidth,
                                safeHeight, master, contentWidth - master - c.dividerWidth,
                                c.dividerWidth);
}

@end
