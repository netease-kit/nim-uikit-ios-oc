// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotBindController.h"
#import "NormalContactUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation AIRobotBindController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.createBotArrowView.hidden = NO;
}

- (UIColor *)pageBackgroundColor {
  return [UIColor ne_lightBackgroundColor];
}

- (UIColor *)confirmButtonColor {
  return [UIColor normalContactThemeColor];
}

@end
