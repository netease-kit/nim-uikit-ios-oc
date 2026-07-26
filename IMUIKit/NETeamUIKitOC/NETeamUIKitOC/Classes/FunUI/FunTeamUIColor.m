// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamUIColor.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation UIColor (FunTeam)

+ (UIColor *)funTeamMemberDividerLine {
  return [UIColor ne_colorWithHexString:@"#E4E9F2"];
}

+ (UIColor *)funTeamMebmerSearchBg {
  return [UIColor ne_colorWithHexString:@"0xF1F1F6"];
}

+ (UIColor *)funTeamThemeColor {
  return [UIColor ne_funTheme];
}

+ (UIColor *)funTeamThemeDisableColor {
  return [[UIColor ne_colorWithHexString:@"#58BE6B"] colorWithAlphaComponent:0.5];
}

+ (UIColor *)funTeamBackgroundColor {
  return [UIColor ne_colorWithHexString:@"#EDEDED"];
}

+ (UIColor *)funTeamLineBorderColor {
  return [UIColor ne_colorWithHexString:@"#E5E5E5"];
}

+ (UIColor *)funTeamRemoveLabelColor {
  return [UIColor ne_colorWithHexString:@"#505D75"];
}

+ (UIColor *)funTeamMangerLabelTextColor {
  return [UIColor ne_colorWithHexString:@"#EA8339"];
}

+ (UIColor *)funTeamMangerLabelBackColor {
  return [[UIColor ne_colorWithHexString:@"#F2C46B"] colorWithAlphaComponent:0.1];
}

+ (UIColor *)funTeamManagerLabelBorderColor {
  return [UIColor ne_colorWithHexString:@"#F2C46B"];
}

+ (UIColor *)funTeamDetailTitleTextColor {
  return [UIColor ne_colorWithHexString:@"#525C8C"];
}

@end
