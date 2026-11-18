// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENavigationController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "NEAdaptiveDeviceGate.h"

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
    if ([self ne_managesTabBarVisibility]) {
      self.tabBarController.tabBar.hidden = YES;
    }
  }

  if (animated) {
    [super pushViewController:viewController animated:YES];
    [self updateTabBarAfterTransition];
    return;
  }

  // 把 push、外层布局和 tab bar 显隐收进同一个关闭动画的事务里，
  [UIView performWithoutAnimation:^{
    [super pushViewController:viewController animated:NO];
    [self.view layoutIfNeeded];
    [self.tabBarController.view layoutIfNeeded];
    [viewController.viewIfLoaded layoutIfNeeded];
  }];
  if ([self ne_managesTabBarVisibility]) {
    [self updateTabBarVisibilityForTopViewController];
  }
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated {
  UIViewController *controller = [super popViewControllerAnimated:animated];
  [self updateTabBarAfterTransition];
  return controller;
}

- (BOOL)ne_managesTabBarVisibility {
  return ![NEAdaptiveDeviceGate adaptiveHostActive] && ![NEAdaptiveDeviceGate isFoldableDevice];
}

- (void)updateTabBarAfterTransition {
  if (![self ne_managesTabBarVisibility]) {
    return;
  }
  id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
  if (!coordinator) {
    [self updateTabBarVisibilityForTopViewController];
    return;
  }
  __weak typeof(self) weakSelf = self;
  [coordinator animateAlongsideTransition:nil
                              completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
    [weakSelf updateTabBarVisibilityForTopViewController];
  }];
}

- (void)updateTabBarVisibilityForTopViewController {
  if (!self.tabBarController || ![self ne_managesTabBarVisibility]) {
    return;
  }
  self.tabBarController.tabBar.hidden = self.viewControllers.count > 1;
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (self.viewControllers.count > 0) {
    viewController.hidesBottomBarWhenPushed = YES;
  }
  NSArray<UIViewController *> *controllers = [super popToViewController:viewController animated:animated];
  [self updateTabBarAfterTransition];
  return controllers;
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
