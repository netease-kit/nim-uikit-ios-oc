// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CreateAIRobotController.h"
#import "FunContactUIColor.h"
#import "NormalContactUIColor.h"

@implementation CreateAIRobotController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [self pageBackgroundColor];
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (UIColor *)saveButtonColor {
  return [UIColor normalContactThemeColor];
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

@end
