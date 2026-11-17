// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotDetailController.h"
#import "NormalContactUIColor.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation AIRobotDetailController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [self pageBackgroundColor];
}

- (UIColor *)pageBackgroundColor {
  return [UIColor ne_lightBackgroundColor];
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

- (CGFloat)headerTopMargin {
  return 0.0;
}

- (CGFloat)headerHeight {
  return 74.0;
}

- (CGFloat)avatarSize {
  return 42.0;
}

- (CGFloat)avatarCornerRadius {
  return 21.0;
}

- (CGFloat)sectionSpacing {
  return 12.0;
}

- (CGFloat)rowHeight {
  return 48.0;
}

- (CGFloat)chatSeparatorHeight {
  return 6.0;
}

- (CGFloat)chatRowHeight {
  return 50.0;
}

- (CGFloat)deleteSeparatorHeight {
  return 0.0;
}

- (CGFloat)deleteRowHeight {
  return 50.0;
}

- (UIColor *)chatTextColor {
  return [UIColor ne_normalTheme];
}

- (UIFont *)chatLabelFont {
  return [UIFont systemFontOfSize:16.0];
}

- (UIFont *)deleteLabelFont {
  return [UIFont systemFontOfSize:16.0];
}

- (UIColor *)confirmButtonColor {
  return [UIColor normalContactThemeColor];
}

- (void)setupHeaderStyle {
  self.headerView.layer.cornerRadius = 8.0;
  self.headerView.clipsToBounds = YES;
}

- (void)setupTableStyle {
  self.tableView.layer.cornerRadius = 8.0;
  self.tableView.clipsToBounds = YES;
  self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)setupChatRowStyle {
  self.chatRowView.layer.cornerRadius = 8.0;
  self.chatRowView.clipsToBounds = YES;
}

@end
