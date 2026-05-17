// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UITabBar+Badge.h"

static const NSInteger NEFlag = 666;

@implementation UITabBar (Badge)

- (void)showBadgOnWithIndex:(NSInteger)itemIndex tabbarItemNums:(CGFloat)tabbarItemNums {
  [self removeBadgeOnIndex:itemIndex];

  UIView *badgeView = [[UIView alloc] init];
  badgeView.tag = itemIndex + NEFlag;
  badgeView.layer.cornerRadius = 3.0;
  badgeView.backgroundColor = [UIColor redColor];
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

- (void)hideBadgOn:(NSInteger)itemIndex {
  [self removeBadgeOnIndex:itemIndex];
}

- (void)removeBadgeOnIndex:(NSInteger)itemIndex {
  for (UIView *subview in self.subviews) {
    if (subview.tag == itemIndex + NEFlag) {
      [subview removeFromSuperview];
    }
  }
}

@end
