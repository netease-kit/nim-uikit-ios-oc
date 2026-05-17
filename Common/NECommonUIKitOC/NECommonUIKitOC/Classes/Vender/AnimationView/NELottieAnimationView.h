// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LottieLoopMode) {
  LottieLoopModePlayOnce = 0,
  LottieLoopModeLoop = 1,
  LottieLoopModeAutoReverse = 2,
};

/// OC 版 Lottie 动画视图占位实现，对齐 Swift 版公共模块的类型归属。
@interface NELottieAnimationView : UIView

@property (nonatomic, assign) LottieLoopMode loopMode;
@property (nonatomic, assign, getter=isAnimationPlaying) BOOL animationPlaying;

- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle;
- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
