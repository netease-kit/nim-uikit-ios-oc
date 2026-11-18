// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAnimatedSwitch.h"
#import "NELottieAnimationView.h"

@interface NEAnimatedSwitch ()
@property (nonatomic, assign) BOOL internalOn;
@property (nonatomic, assign) CGFloat onStartProgress;
@property (nonatomic, assign) CGFloat onEndProgress;
@property (nonatomic, assign) CGFloat offStartProgress;
@property (nonatomic, assign) CGFloat offEndProgress;
@end

@implementation NEAnimatedSwitch

- (instancetype)init {
  self = [super init];
  if (self) {
    [self ne_setupAnimatedSwitch];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_setupAnimatedSwitch];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self ne_setupAnimatedSwitch];
  }
  return self;
}

- (void)ne_setupAnimatedSwitch {
  self.isAccessibilityElement = YES;
  self.animateUpdateWhenChangingAnimation = YES;
  self.onStartProgress = 0;
  self.onEndProgress = 1;
  self.offStartProgress = 1;
  self.offEndProgress = 0;
  [self ne_updateOnState:NO animated:NO shouldFireHaptics:NO];
}

- (UIAccessibilityTraits)accessibilityTraits {
  return [super accessibilityTraits] | UIAccessibilityTraitButton;
}

- (void)animationDidSet {
  [self ne_updateOnState:self.internalOn
                animated:self.animateUpdateWhenChangingAnimation
       shouldFireHaptics:NO];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [super endTrackingWithTouch:touch withEvent:event];
  [self ne_updateOnState:!self.internalOn animated:YES shouldFireHaptics:YES];
  [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)isOn {
  return self.internalOn;
}

- (void)setIsOn:(BOOL)isOn {
  if (isOn != self.internalOn) {
    [self ne_updateOnState:isOn animated:NO shouldFireHaptics:NO];
  }
}

- (void)setIsOn:(BOOL)isOn animated:(BOOL)animated shouldFireHaptics:(BOOL)shouldFireHaptics {
  if (isOn != self.internalOn) {
    [self ne_updateOnState:isOn animated:animated shouldFireHaptics:shouldFireHaptics];
  }
}

- (void)setProgressForStateFromProgress:(CGFloat)fromProgress
                             toProgress:(CGFloat)toProgress
                             forOnState:(BOOL)forOnState {
  if (forOnState) {
    self.onStartProgress = fromProgress;
    self.onEndProgress = toProgress;
  } else {
    self.offStartProgress = fromProgress;
    self.offEndProgress = toProgress;
  }
  [self ne_updateOnState:self.internalOn animated:NO shouldFireHaptics:NO];
}

- (void)ne_updateOnState:(BOOL)isOn animated:(BOOL)animated shouldFireHaptics:(BOOL)shouldFireHaptics {
  CGFloat startProgress = isOn ? self.onStartProgress : self.offStartProgress;
  CGFloat endProgress = isOn ? self.onEndProgress : self.offEndProgress;
  CGFloat realtimeProgress = self.animationView.currentProgress;
  CGFloat previousStart = isOn ? self.offStartProgress : self.onStartProgress;
  CGFloat previousEnd = isOn ? self.offEndProgress : self.onEndProgress;
  if (realtimeProgress >= MIN(previousStart, previousEnd) &&
      realtimeProgress <= MAX(previousStart, previousEnd)) {
    startProgress = previousEnd;
    endProgress = previousStart;
  }

  self.internalOn = isOn;
  self.accessibilityValue = isOn ? NSLocalizedString(@"On", @"On") : NSLocalizedString(@"Off", @"Off");
  if (self.stateUpdated) {
    self.stateUpdated(isOn);
  }

  if (!animated) {
    self.animationView.currentProgress = isOn ? self.onEndProgress : self.offEndProgress;
    return;
  }

  if (shouldFireHaptics) {
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
  }
  self.animationView.loopMode = LottieLoopModePlayOnce;
  [self.animationView playFromProgress:startProgress toProgress:endProgress completion:nil];
}

@end
