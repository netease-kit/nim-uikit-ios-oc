// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELottieAnimationView.h"

static UIView *NECreateLottieView(NSString *name, NSBundle *bundle) {
  Class lottieClass = NSClassFromString(@"LOTAnimationView");
  SEL namedSelector = NSSelectorFromString(@"animationNamed:inBundle:");
  if (lottieClass && [lottieClass respondsToSelector:namedSelector]) {
    IMP imp = [lottieClass methodForSelector:namedSelector];
    id (*func)(id, SEL, id, id) = (id (*)(id, SEL, id, id))imp;
    id animationView = func(lottieClass, namedSelector, name, bundle);
    if ([animationView isKindOfClass:[UIView class]]) {
      return animationView;
    }
  }
  return nil;
}

@interface NELottieAnimationView ()

@property (nonatomic, strong, nullable) UIView *animationView;

@end

@implementation NELottieAnimationView

- (void)layoutSubviews {
  [super layoutSubviews];
  self.animationView.frame = self.bounds;
}

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _loopMode = LottieLoopModePlayOnce;
    _animationPlaying = NO;
    UIView *animationView = NECreateLottieView(name, bundle);
    self.animationView = animationView;
    if (self.animationView) {
      self.animationView.frame = self.bounds;
      self.animationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      self.animationView.contentMode = self.contentMode;
      [self addSubview:self.animationView];
      [self applyLoopMode];
    }
  }
  return self;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
  [super setContentMode:contentMode];
  self.animationView.contentMode = contentMode;
}

- (void)setLoopMode:(LottieLoopMode)loopMode {
  _loopMode = loopMode;
  [self applyLoopMode];
}

- (void)applyLoopMode {
  if (!self.animationView) {
    return;
  }

  BOOL loopAnimation = self.loopMode != LottieLoopModePlayOnce;
  BOOL autoReverseAnimation = self.loopMode == LottieLoopModeAutoReverse;
  @try {
    [self.animationView setValue:@(loopAnimation) forKey:@"loopAnimation"];
    [self.animationView setValue:@(autoReverseAnimation) forKey:@"autoReverseAnimation"];
  } @catch (__unused NSException *exception) {
  }
}

- (void)play {
  if ([self.animationView respondsToSelector:@selector(play)]) {
    IMP imp = [self.animationView methodForSelector:@selector(play)];
    void (*func)(id, SEL) = (void (*)(id, SEL))imp;
    func(self.animationView, @selector(play));
  }
  self.animationPlaying = YES;
}

- (void)stop {
  if ([self.animationView respondsToSelector:@selector(stop)]) {
    IMP imp = [self.animationView methodForSelector:@selector(stop)];
    void (*func)(id, SEL) = (void (*)(id, SEL))imp;
    func(self.animationView, @selector(stop));
  }
  self.animationPlaying = NO;
}

@end
