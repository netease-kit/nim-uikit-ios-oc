// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalTeamUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation UIColor (NormalTeam)

+ (UIColor *)normalTeamBlueColor {
  return [UIColor ne_colorWithHexString:@"#337EFF"];
}

+ (UIColor *)normalTeamOwnerColor {
  return [UIColor ne_colorWithHexString:@"#656A72"];
}

+ (UIColor *)normalTeamOwnerBgColor {
  return [UIColor ne_colorWithHexString:@"#F7F7F7"];
}

+ (UIColor *)normalTeamOwnerBorderColor {
  return [UIColor ne_colorWithHexString:@"#D6D8DB"];
}

@end
