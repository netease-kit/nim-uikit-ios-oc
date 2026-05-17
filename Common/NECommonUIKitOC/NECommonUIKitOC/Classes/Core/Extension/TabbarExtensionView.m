// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TabbarExtensionView.h"

static NSInteger const kNEBadgeDotTagBase = 666;

@implementation UITabBar (TabbarExtensionView)

- (void)showBadgOnIndex:(NSInteger)itemIndex tabbarItemNums:(CGFloat)tabbarItemNums {
  [self hideBadgOnIndex:itemIndex];

  UIView *badgeView = [[UIView alloc] init];
  badgeView.tag = itemIndex + kNEBadgeDotTagBase;
  badgeView.layer.cornerRadius = 3.0;
  badgeView.backgroundColor = UIColor.redColor;
  badgeView.accessibilityIdentifier = @"id.bageDot";

  CGRect tabFrame = self.frame;
  void (^layoutBadge)(void) = ^{
    CGFloat percentX = ((CGFloat)itemIndex + 0.59) / tabbarItemNums;
    CGFloat x = ceilf((float)(percentX * tabFrame.size.width));
    CGFloat y = ceilf((float)(0.015 * tabFrame.size.height));
    if (@available(iOS 26.0, *)) {
      NSNumber *compatibilityValue = NSBundle.mainBundle.infoDictionary[@"UIDesignRequiresCompatibility"];
      if (![compatibilityValue boolValue]) {
        UIView *firstSubview = self.subviews.firstObject;
        if (firstSubview) {
          percentX = ((CGFloat)itemIndex + 0.05) / tabbarItemNums;
          x = tabFrame.size.width - firstSubview.frame.size.width + ceilf((float)(percentX * firstSubview.frame.size.width));
          y = ceilf((float)(0.1 * tabFrame.size.height));
        }
      }
    }
    badgeView.frame = CGRectMake(x, y, 6.0, 6.0);
    [self addSubview:badgeView];
  };

  if (@available(iOS 26.0, *)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)), dispatch_get_main_queue(), layoutBadge);
  } else {
    layoutBadge();
  }
}

- (void)setRedDotViewWithIndex:(NSInteger)itemIndex {
  UITabBarItem *tabBarItem = self.items.count > itemIndex ? self.items[itemIndex] : nil;
  tabBarItem.badgeValue = @"·";
  tabBarItem.badgeColor = UIColor.clearColor;
  if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    tabBarItem.badgeValue = @"●";
  } else {
    [tabBarItem setBadgeTextAttributes:@{
      NSForegroundColorAttributeName: UIColor.redColor,
      NSFontAttributeName: [UIFont systemFontOfSize:50.0],
    } forState:UIControlStateNormal];
  }
}

- (void)hideRedDocViewWithIndex:(NSInteger)itemIndex {
  UITabBarItem *tabBarItem = self.items.count > itemIndex ? self.items[itemIndex] : nil;
  tabBarItem.badgeValue = nil;
}

- (void)hideBadgOnIndex:(NSInteger)itemIndex {
  NSInteger targetTag = itemIndex + kNEBadgeDotTagBase;
  for (UIView *subview in self.subviews.copy) {
    if (subview.tag == targetTag) {
      [subview removeFromSuperview];
    }
  }
}

- (void)setServerBadge:(NSString *)count {
  UITabBarItem *item = self.items.count > 1 ? self.items[1] : nil;
  item.badgeValue = count;
}

@end

