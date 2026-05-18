// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotConfigController.h"
#import "NormalContactUIColor.h"

@implementation AIRobotConfigController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [self pageBackgroundColor];
}

- (CGFloat)cardTopMargin {
  return 12.0;
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

- (CGFloat)copyButtonCornerRadius {
  return 8.0;
}

- (void)setupCardCornerRadius {
  self.cardView.layer.cornerRadius = 8.0;
  self.cardView.clipsToBounds = YES;
}

- (UIColor *)copyButtonColor {
  return [UIColor normalContactThemeColor];
}

@end
