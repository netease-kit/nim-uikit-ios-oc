// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELottieAnimationViewBase.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LottieLoopMode) {
  LottieLoopModePlayOnce = 0,
  LottieLoopModeLoop = 1,
  LottieLoopModeAutoReverse = 2,
};

/// A UIView subclass for rendering Lottie animations.
@interface NELottieAnimationView : NELottieAnimationViewBase

@property (nonatomic, assign) LottieLoopMode loopMode;
/// Writing YES starts playback; writing NO pauses it. The getter reports the actual player state.
@property (nonatomic, assign, getter=isAnimationPlaying) BOOL animationPlaying;
@property (nonatomic, assign) CGFloat currentProgress;
@property (nonatomic, assign) CGFloat animationSpeed;

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle;
- (void)play;
- (void)playWithCompletion:(nullable void (^)(BOOL finished))completion;
- (void)playFromProgress:(CGFloat)fromProgress
              toProgress:(CGFloat)toProgress
              completion:(nullable void (^)(BOOL finished))completion;
- (nullable NSNumber *)progressTimeForMarker:(NSString *)name;
- (void)stop;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
