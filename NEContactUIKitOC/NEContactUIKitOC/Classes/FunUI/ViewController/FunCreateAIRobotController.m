// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunCreateAIRobotController.h"
#import "FunContactUIColor.h"

@implementation FunCreateAIRobotController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.avatarImageView.layer.cornerRadius = 4.0;
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (UIColor *)saveButtonColor {
  return [UIColor funContactThemeColor];
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

- (void)setupCardBorderRadius {
  self.cardView.layer.cornerRadius = 8.0;
  self.cardView.clipsToBounds = YES;
  self.sectionDivider.backgroundColor = [UIColor funContactDividerLineColor];
}

@end
