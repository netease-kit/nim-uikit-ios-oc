// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NELottieAnimationView;

NS_ASSUME_NONNULL_BEGIN

/// Base control that keeps Lottie layer visibility in sync with UIControl state.
@interface NEAnimatedControl : UIControl

@property (nonatomic, strong, readonly) NELottieAnimationView *animationView;
@property (nonatomic, assign) CGFloat animationSpeed;

- (void)animationDidSet;
- (void)setLayerWithNamed:(NSString *)named forState:(UIControlState)forState;

@end

NS_ASSUME_NONNULL_END
