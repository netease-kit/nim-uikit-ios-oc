// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalContactUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ContactUIConfig.h"

@implementation UIColor (NormalContact)

+ (UIColor *)normalContactThemeColor {
  return [UIColor ne_normalTheme];
}

+ (UIColor *)normalContactNavigationBackgroundColor {
  return [UIColor whiteColor];
}

+ (UIColor *)normalContactNavigationDivideBg {
  return [UIColor ne_colorWithHexString:@"#E9EFF5"];
}

+ (UIColor *)normalContactBackgroundColor {
  return [UIColor normalContactNavigationBackgroundColor];
}

+ (UIColor *)normalContactBodyTopViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)normalContactBodyViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)normalContactTableViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)normalContactTableViewSectionIndexColor {
  return [UIColor ne_greyText];
}

+ (UIColor *)normalContactBodyBottomViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)normalContactSectionViewBackgroundColor {
  return [UIColor whiteColor];
}

+ (UIColor *)normalContactSectionViewLineColor {
  return [ContactUIConfig shared].contactProperties.divideLineColor;
}

+ (UIColor *)normalContactSectionViewTitleLabelTextColor {
  UIColor *color = [ContactUIConfig shared].contactProperties.indexTitleColor;
  return color ?: [UIColor ne_emptyTitleColor];
}

+ (UIColor *)normalContactItemBackgroundColor {
  return [UIColor whiteColor];
}

+ (UIColor *)normalContactItemLineBackgroundColor {
  return [UIColor ne_greyLine];
}

+ (UIColor *)disableButtonTitleColor {
  return [UIColor ne_colorWithHexString:@"#DDDDDD"];
}

+ (UIColor *)searchTextFeildBackColor {
  return [UIColor ne_colorWithHexString:@"#F2F4F5"];
}

+ (UIColor *)contactBlueDividerLineColor {
  return [UIColor ne_colorWithHexString:@"#337EFF"];
}

+ (UIColor *)contactNormalTextColor {
  return [UIColor ne_colorWithHexString:@"#333333"];
}

+ (UIColor *)contactFusionSelectButtonBGColor {
  return [UIColor ne_colorWithHexString:@"#337EFF"];
}

@end
