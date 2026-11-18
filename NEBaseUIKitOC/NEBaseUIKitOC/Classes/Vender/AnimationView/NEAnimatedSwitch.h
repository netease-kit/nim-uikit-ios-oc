// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAnimatedControl.h"

NS_ASSUME_NONNULL_BEGIN

/// Interactive switch backed by an animation progress range.
@interface NEAnimatedSwitch : NEAnimatedControl

@property (nonatomic, assign) BOOL animateUpdateWhenChangingAnimation;
@property (nonatomic, copy, nullable) void (^stateUpdated)(BOOL isOn);
@property (nonatomic, assign) BOOL isOn;

- (void)setIsOn:(BOOL)isOn animated:(BOOL)animated shouldFireHaptics:(BOOL)shouldFireHaptics;
- (void)setProgressForStateFromProgress:(CGFloat)fromProgress
                             toProgress:(CGFloat)toProgress
                             forOnState:(BOOL)forOnState;

@end

NS_ASSUME_NONNULL_END
