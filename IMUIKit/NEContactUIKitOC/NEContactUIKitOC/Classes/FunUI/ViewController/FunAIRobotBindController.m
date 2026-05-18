// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotBindController.h"
#import "FunAIRobotBindCell.h"
#import "FunContactUIColor.h"
#import "NEBaseAIRobotBindCell.h"

@implementation FunAIRobotBindController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  [self.tableView registerClass:[FunAIRobotBindCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseAIRobotBindCell class])];
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (CGFloat)bindRowHeight {
  return 74.0;
}

- (CGFloat)createBotRowHeight {
  return 74.0;
}

- (UIColor *)confirmButtonColor {
  return [UIColor funContactThemeColor];
}

- (CGFloat)dividerBlockHeight {
  return 8.0;
}

- (UIFont *)sectionLabelFont {
  return [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
}

- (UIColor *)sectionLabelColor {
  return [UIColor blackColor];
}

- (void)setupCreateBotIconStyle {
  self.createBotIconView.backgroundColor = [UIColor funContactThemeColor];
  self.createBotIconView.layer.cornerRadius = 4.0;
}

@end
