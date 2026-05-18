// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunContactUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ContactUIConfig.h"

@implementation UIColor (FunContact)

+ (UIColor *)funContactThemeColor {
  return [UIColor ne_funTheme];
}

+ (UIColor *)funContactThemeDisableColor {
  return [[UIColor ne_colorWithHexString:@"#58BE6B"] colorWithAlphaComponent:0.5];
}

+ (UIColor *)funContactLineBorderColor {
  return [UIColor ne_colorWithHexString:@"#E5E5E5"];
}

+ (UIColor *)funContactUserViewChatTitleTextColor {
  return [UIColor ne_colorWithHexString:@"#525C8C"];
}

+ (UIColor *)funContactDividerLineColor {
  return [UIColor ne_colorWithHexString:@"#E4E9F2"];
}

+ (UIColor *)funContactBodyTopViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)funContactBodyViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)funContactTableViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)funContactTableViewSectionIndexColor {
  return [UIColor ne_greyText];
}

+ (UIColor *)funContactBodyBottomViewBackgroundColor {
  return [UIColor clearColor];
}

+ (UIColor *)funContactNavigationBackgroundColor {
  return [UIColor ne_colorWithHexString:@"#EDEDED"];
}

+ (UIColor *)funContactBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

+ (UIColor *)funContactItemBackgroundColor {
  return [UIColor whiteColor];
}

+ (UIColor *)funContactItemLineBackgroundColor {
  return [UIColor funContactLineBorderColor];
}

+ (UIColor *)funContactSectionViewBackgroundColor {
  return [UIColor whiteColor];
}

+ (UIColor *)funContactSectionViewTitleLabelTextColor {
  UIColor *color = [ContactUIConfig shared].contactProperties.indexTitleColor;
  return color ?: [UIColor ne_emptyTitleColor];
}

+ (UIColor *)funContactGreenDividerLineColor {
  return [UIColor ne_colorWithHexString:@"#58BE6B"];
}

+ (UIColor *)funContactNormalTextColor {
  return [UIColor ne_colorWithHexString:@"#333333"];
}

@end
