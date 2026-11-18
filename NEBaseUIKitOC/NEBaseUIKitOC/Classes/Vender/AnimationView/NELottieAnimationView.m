// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELottieAnimationView.h"
#import <Lottie/Lottie.h>
#import <objc/message.h>

@interface NELottieAnimationView ()

@property (nonatomic, strong) LOTAnimationView *animationView;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *animationJSON;

@end

@implementation NELottieAnimationView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_setUpAnimationView:[[LOTAnimationView alloc] init]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self ne_setUpAnimationView:[[LOTAnimationView alloc] init]];
  }
  return self;
}

- (CGSize)intrinsicContentSize {
  return self.animationView.intrinsicContentSize;
}

- (void)layoutAnimation {
  self.animationView.frame = self.bounds;
}

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self ne_setUpAnimationView:[LOTAnimationView animationNamed:name inBundle:bundle]];
    NSString *path = [bundle pathForResource:name ofType:@"json"];
    NSData *data = path.length > 0 ? [NSData dataWithContentsOfFile:path] : nil;
    id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
      self.animationJSON = json;
    }
  }
  return self;
}

- (NSNumber *)progressTimeForMarker:(NSString *)name {
  NSArray *markers = self.animationJSON[@"markers"];
  for (id value in markers) {
    if ([value isKindOfClass:[NSDictionary class]] && [value[@"cm"] isEqualToString:name]) {
      LOTComposition *composition = self.animationView.sceneModel;
      CGFloat start = composition.startFrame.doubleValue;
      CGFloat end = composition.endFrame.doubleValue;
      if (end == start) {
        return @0;
      }
      return @(([value[@"tm"] doubleValue] - start) / (end - start));
    }
  }
  return nil;
}

- (void)ne_setVisibleLayerNamed:(NSString *)name {
  SEL layerSelector = NSSelectorFromString(@"layerForKey:");
  SEL layersSelector = NSSelectorFromString(@"compositionLayers");
  if (![self.animationView respondsToSelector:layerSelector] ||
      ![self.animationView respondsToSelector:layersSelector]) {
    return;
  }
  CALayer *(*layerFunction)(id, SEL, NSString *) =
      (CALayer *(*)(id, SEL, NSString *))objc_msgSend;
  NSArray<CALayer *> *(*layersFunction)(id, SEL) =
      (NSArray<CALayer *> *(*)(id, SEL))objc_msgSend;
  CALayer *visibleLayer = layerFunction(self.animationView, layerSelector, name);
  if (visibleLayer == nil) {
    return;
  }
  for (CALayer *layer in layersFunction(self.animationView, layersSelector)) {
    layer.hidden = YES;
  }
  visibleLayer.hidden = NO;
}

- (void)ne_setUpAnimationView:(LOTAnimationView *)animationView {
  _loopMode = LottieLoopModePlayOnce;
  self.animationView = animationView;
  self.animationView.frame = self.bounds;
  self.animationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.animationView.contentMode = self.contentMode;
  self.animationView.userInteractionEnabled = NO;
  [self addSubview:self.animationView];
  [self applyLoopMode];
}

- (void)setContentMode:(UIViewContentMode)contentMode {
  [super setContentMode:contentMode];
  self.animationView.contentMode = contentMode;
}

- (void)setLoopMode:(LottieLoopMode)loopMode {
  _loopMode = loopMode;
  [self applyLoopMode];
}

- (BOOL)isAnimationPlaying {
  return self.animationView.isAnimationPlaying;
}

- (void)setAnimationPlaying:(BOOL)animationPlaying {
  if (animationPlaying == self.isAnimationPlaying) return;
  if (animationPlaying) {
    [self play];
  } else {
    [self pause];
  }
}

- (CGFloat)currentProgress {
  return self.animationView.animationProgress;
}

- (void)setCurrentProgress:(CGFloat)currentProgress {
  self.animationView.animationProgress = currentProgress;
}

- (CGFloat)animationSpeed {
  return self.animationView.animationSpeed;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
  self.animationView.animationSpeed = animationSpeed;
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
  [self.animationView play];
}

- (void)playWithCompletion:(void (^)(BOOL))completion {
  [self.animationView playWithCompletion:completion];
}

- (void)playFromProgress:(CGFloat)fromProgress
              toProgress:(CGFloat)toProgress
              completion:(void (^)(BOOL))completion {
  [self.animationView playFromProgress:fromProgress
                            toProgress:toProgress
                        withCompletion:completion];
}

- (void)stop {
  [self.animationView stop];
}

- (void)pause {
  [self.animationView pause];
}

@end
