// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotConfigController.h"
#import "FunContactUIColor.h"

@implementation FunAIRobotConfigController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.view.backgroundColor = [UIColor funContactNavigationBackgroundColor];
}

- (CGFloat)cardTopMargin {
  return 12.0;
}

- (CGFloat)cardHorizontalMargin {
  return 0.0;
}

- (CGFloat)copyButtonHorizontalMargin {
  return 16.0;
}

- (CGFloat)copyButtonCornerRadius {
  return 12.0;
}

- (void)setupCardCornerRadius {
  self.cardView.layer.cornerRadius = 0.0;
  self.cardView.clipsToBounds = YES;
}

- (UIColor *)copyButtonColor {
  return [UIColor funContactThemeColor];
}

@end
