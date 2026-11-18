// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAnimatedButton.h"
#import "NELottieAnimationView.h"

@interface NEAnimatedButton ()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *rangesForEvents;
@end

@implementation NEAnimatedButton

- (instancetype)init {
  self = [super init];
  if (self) {
    [self ne_setupAnimatedButton];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_setupAnimatedButton];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self ne_setupAnimatedButton];
  }
  return self;
}

- (void)ne_setupAnimatedButton {
  self.isAccessibilityElement = YES;
  self.rangesForEvents = [@{
    @(UIControlEventTouchUpInside) : @[@0, @1],
  } mutableCopy];
}

- (UIAccessibilityTraits)accessibilityTraits {
  return [super accessibilityTraits] | UIAccessibilityTraitButton;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [super beginTrackingWithTouch:touch withEvent:event];
  [self ne_playRangeForEvent:UIControlEventTouchDown];
  return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [super endTrackingWithTouch:touch withEvent:event];
  UIControlEvents touchEvent = UIControlEventTouchUpOutside;
  if (touch && CGRectContainsPoint(self.bounds, [touch locationInView:self])) {
    touchEvent = UIControlEventTouchUpInside;
    if (self.performAction) {
      self.performAction();
    }
  }
  [self ne_playRangeForEvent:touchEvent];
}

- (void)setPlayRangeFromProgress:(CGFloat)fromProgress
                      toProgress:(CGFloat)toProgress
                           event:(UIControlEvents)event {
  self.rangesForEvents[@(event)] = @[@(fromProgress), @(toProgress)];
}

- (void)setPlayRangeFromMarker:(NSString *)fromName
                      toMarker:(NSString *)toName
                         event:(UIControlEvents)event {
  NSNumber *start = [self.animationView progressTimeForMarker:fromName];
  NSNumber *end = [self.animationView progressTimeForMarker:toName];
  if (start && end) {
    [self setPlayRangeFromProgress:start.doubleValue toProgress:end.doubleValue event:event];
  }
}

- (void)ne_playRangeForEvent:(UIControlEvents)event {
  NSArray<NSNumber *> *range = self.rangesForEvents[@(event)];
  if (range.count == 2) {
    self.animationView.loopMode = LottieLoopModePlayOnce;
    [self.animationView playFromProgress:range[0].doubleValue
                              toProgress:range[1].doubleValue
                              completion:nil];
  }
}

@end
