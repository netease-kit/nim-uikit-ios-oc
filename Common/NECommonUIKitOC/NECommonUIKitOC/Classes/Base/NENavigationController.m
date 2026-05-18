// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENavigationController.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation NENavigationController

- (void)viewDidLoad {
  [super viewDidLoad];
  _barBackgroundColor = UIColor.whiteColor;
  _barTintColor = UIColor.ne_darkText;
  _titleColor = UIColor.ne_darkText;
  _titleFontSize = 17.0;
  [self applyNavigationBarAppearance];
}

- (void)applyNavigationBarAppearance {
  NSDictionary *titleAttrs = @{
    NSForegroundColorAttributeName: _titleColor,
    NSFontAttributeName: [UIFont boldSystemFontOfSize:_titleFontSize],
  };

  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    appearance.backgroundImage = [[UIImage alloc] init];
    appearance.backgroundColor = _barBackgroundColor;
    appearance.shadowColor = UIColor.ne_navLineColor;
    appearance.titleTextAttributes = titleAttrs;
    self.navigationBar.standardAppearance = appearance;
    self.navigationBar.scrollEdgeAppearance = appearance;
    if (@available(iOS 15.0, *)) {
      self.navigationBar.compactAppearance = appearance;
    }
  } else {
    self.navigationBar.barTintColor = _barBackgroundColor;
    self.navigationBar.titleTextAttributes = titleAttrs;
    [self.navigationBar setShadowImage:[[UIImage alloc] init]];
  }
  self.navigationBar.tintColor = _barTintColor;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (self.viewControllers.count > 0) {
    viewController.hidesBottomBarWhenPushed = YES;
  }
  [super pushViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (self.viewControllers.count > 0) {
    viewController.hidesBottomBarWhenPushed = YES;
  }
  return [super popToViewController:viewController animated:animated];
}

// 支持动态更新属性
- (void)setBarBackgroundColor:(UIColor *)barBackgroundColor {
  _barBackgroundColor = barBackgroundColor;
  [self applyNavigationBarAppearance];
}
- (void)setBarTintColor:(UIColor *)barTintColor {
  _barTintColor = barTintColor;
  self.navigationBar.tintColor = barTintColor;
}
- (void)setTitleColor:(UIColor *)titleColor {
  _titleColor = titleColor;
  [self applyNavigationBarAppearance];
}
- (void)setTitleFontSize:(CGFloat)titleFontSize {
  _titleFontSize = titleFontSize;
  [self applyNavigationBarAppearance];
}

@end
