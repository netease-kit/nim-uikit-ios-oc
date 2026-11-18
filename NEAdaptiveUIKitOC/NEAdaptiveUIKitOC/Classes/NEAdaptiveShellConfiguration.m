// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveShellConfiguration.h"

@implementation NEAdaptiveShellConfiguration

- (instancetype)initWithRailWidth:(CGFloat)railWidth
          singleContentMinimumWidth:(CGFloat)singleContentMinimumWidth
               masterMinimumWidth:(CGFloat)masterMinimumWidth
               detailMinimumWidth:(CGFloat)detailMinimumWidth
                     dividerWidth:(CGFloat)dividerWidth
                 mediumMasterWidth:(CGFloat)mediumMasterWidth
               expandedMasterWidth:(CGFloat)expandedMasterWidth
               masterMaximumWidth:(CGFloat)masterMaximumWidth {
  self = [super init];
  if (self) {
    _railWidth = railWidth;
    _singleContentMinimumWidth = singleContentMinimumWidth;
    _masterMinimumWidth = masterMinimumWidth;
    _detailMinimumWidth = detailMinimumWidth;
    _dividerWidth = dividerWidth;
    _mediumMasterWidth = mediumMasterWidth;
    _expandedMasterWidth = expandedMasterWidth;
    _masterMaximumWidth = masterMaximumWidth;

    _mediumThreshold = 600;
    _expandedThreshold = 840;
    _compactAspectRatio = 1.2;

    _railBackgroundColor = [UIColor secondarySystemBackgroundColor];
    _dividerColor = [UIColor separatorColor];
    _selectedTintColor = [UIColor systemBlueColor];
    _normalTintColor = [UIColor secondaryLabelColor];
    _backTintColor = [UIColor labelColor];
    _usesSystemBackButtonStyle = YES;

    _railUsesTrailingEdge = NO;
    _railItemHeight = 64;
    _railItemSpacing = 18;
    _railItemsTopInset = 268;
    _railItemsBottomInset = 12;
    _railBackButtonSize = 44;
    _railActionButtonSize = 52;
    _railActionSpacing = 12;
    _railActionTopSpacing = 8;

    _railControlBackgroundColor = [UIColor secondarySystemBackgroundColor];
    _railControlBorderColor = [UIColor separatorColor];
    _railControlBorderWidth = 0.5;
    _railActionTextColor = [UIColor labelColor];
    _railActionTextFont = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _railBadgeTextColor = [UIColor systemBackgroundColor];

    _railBackTopInset = 0;
    _contentTopInset = 0;
    _contentBackgroundColor = [UIColor systemBackgroundColor];
  }
  return self;
}

- (NEAdaptiveLayoutConfiguration)policyConfiguration {
  NEAdaptiveLayoutConfiguration configuration =
      NEAdaptiveLayoutConfigurationMake(self.railWidth, self.singleContentMinimumWidth,
                                        self.masterMinimumWidth, self.detailMinimumWidth,
                                        self.dividerWidth,
                                        NEAdaptiveColumnConfigurationMake(self.mediumMasterWidth,
                                                                          self.masterMaximumWidth),
                                        NEAdaptiveColumnConfigurationMake(self.expandedMasterWidth,
                                                                          self.masterMaximumWidth));
  configuration.mediumThreshold = self.mediumThreshold;
  configuration.expandedThreshold = self.expandedThreshold;
  configuration.compactAspectRatio = self.compactAspectRatio;
  configuration.railUsesTrailingEdge = self.railUsesTrailingEdge;
  return configuration;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEAdaptiveShellConfiguration: rail=%g master=%g/%g detail>=%g divider=%g>",
                                    self.railWidth, self.mediumMasterWidth, self.expandedMasterWidth,
                                    self.detailMinimumWidth, self.dividerWidth];
}

@end
