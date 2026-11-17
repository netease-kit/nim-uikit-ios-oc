// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAnimatedControl.h"
#import "NELottieAnimationView.h"

@interface NELottieAnimationView (NEAnimatedControlInternal)
- (void)ne_setVisibleLayerNamed:(NSString *)name;
@end

@interface NEAnimatedControl ()
@property (nonatomic, strong, readwrite) NELottieAnimationView *animationView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *stateMap;
@end

@implementation NEAnimatedControl

- (instancetype)init {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self ne_setupAnimatedControl];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_setupAnimatedControl];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self ne_setupAnimatedControl];
  }
  return self;
}

- (void)ne_setupAnimatedControl {
  self.clipsToBounds = YES;
  self.stateMap = [NSMutableDictionary dictionary];
  self.animationView = [[NELottieAnimationView alloc] initWithFrame:CGRectZero];
  self.animationView.clipsToBounds = NO;
  self.animationView.userInteractionEnabled = NO;
  self.animationView.translatesAutoresizingMaskIntoConstraints = NO;
  self.animationView.contentMode = UIViewContentModeScaleAspectFit;
  [self addSubview:self.animationView];
  [NSLayoutConstraint activateConstraints:@[
    [self.animationView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [self.animationView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [self.animationView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.animationView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
  ]];
}

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  [self ne_updateForState];
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  [self ne_updateForState];
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  [self ne_updateForState];
}

- (CGSize)intrinsicContentSize {
  return self.animationView.intrinsicContentSize;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [self ne_updateForState];
  return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [self ne_updateForState];
  return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  [self ne_updateForState];
  [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
  [self ne_updateForState];
  [super cancelTrackingWithEvent:event];
}

- (void)animationDidSet {}

- (CGFloat)animationSpeed {
  return self.animationView.animationSpeed;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
  self.animationView.animationSpeed = animationSpeed;
}

- (void)setLayerWithNamed:(NSString *)named forState:(UIControlState)forState {
  self.stateMap[@(forState)] = named;
  [self ne_updateForState];
}

- (void)ne_updateForState {
  NSString *name = self.stateMap[@(self.state)];
  if (name.length > 0) {
    [self.animationView ne_setVisibleLayerNamed:name];
  }
}

@end
