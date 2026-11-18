// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELottieAnimationViewBase.h"

@interface NELottieAnimationViewBase ()

- (void)layoutAnimation;
- (void)animationMovedToWindow;
- (void)animationWillMoveToBackground;
- (void)animationWillEnterForeground;

@end

@implementation NELottieAnimationViewBase

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self ne_commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self ne_commonInit];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)ne_commonInit {
  self.contentMode = UIViewContentModeScaleAspectFit;
  self.clipsToBounds = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(animationWillEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(animationWillMoveToBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode {
  [super setContentMode:contentMode];
  [self setNeedsLayout];
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  [self animationMovedToWindow];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self layoutAnimation];
}

- (void)layoutAnimation {}

- (void)animationMovedToWindow {}

- (void)animationWillMoveToBackground {}

- (void)animationWillEnterForeground {}

@end
