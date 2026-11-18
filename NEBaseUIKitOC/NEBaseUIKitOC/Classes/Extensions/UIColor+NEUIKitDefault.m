// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIColor+NEUIKitDefault.h"

static UIColor *NEUIKitDefaultColor(uint32_t rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                         green:((rgb >> 8) & 0xFF) / 255.0
                          blue:(rgb & 0xFF) / 255.0
                         alpha:1.0];
}

@implementation UIColor (NEUIKitDefault)

+ (UIColor *)ne_defaultPrimaryColor {
  return NEUIKitDefaultColor(0x337EFF);
}

+ (UIColor *)ne_defaultPageBackgroundColor {
  return NEUIKitDefaultColor(0xEDEDED);
}

+ (UIColor *)ne_defaultLineColor {
  return NEUIKitDefaultColor(0xE5E5E5);
}

+ (UIColor *)ne_defaultNavigationDividerColor {
  return NEUIKitDefaultColor(0xE9EFF5);
}

+ (UIColor *)ne_defaultReplyBackgroundColor {
  return NEUIKitDefaultColor(0xEFF1F2);
}

@end
