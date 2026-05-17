// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalChatUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation UIColor (NormalChat)

+ (UIColor *)normalChatNavigationBg {
    return UIColor.whiteColor;
}

+ (UIColor *)normalChatNavigationDivideBg {
    return [UIColor ne_colorWithHexString:@"#E9EFF5"];
}

+ (UIColor *)normalChatBodyTopViewBg {
    return UIColor.clearColor;
}

+ (UIColor *)normalChatBodyViewBg {
    return UIColor.clearColor;
}

+ (UIColor *)normalChatNetworkBrokenViewBg {
    return [UIColor ne_colorWithHexString:@"#FEE3E6"];
}

+ (UIColor *)normalChatNetworkBrokenTitleColor {
    return [UIColor ne_colorWithHexString:@"#FC596A"];
}

+ (UIColor *)normalChatTableViewBg {
    UIColor *color = [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor;
    return color ?: UIColor.whiteColor;
}

+ (UIColor *)normalChatBodyBottomViewBg {
    return UIColor.clearColor;
}

+ (UIColor *)normalChatInputViewBg {
    return [UIColor ne_colorWithHexString:@"#EFF1F3"];
}

+ (UIColor *)normalChatInputBg {
    return UIColor.whiteColor;
}

+ (UIColor *)normalChatInputMuteBg {
    return [UIColor ne_colorWithHexString:@"#E3E4E4"];
}

+ (UIColor *)normalChatReplyViewBg {
    return [UIColor ne_colorWithHexString:@"#EFF1F2"];
}

+ (UIColor *)normalChatRecordViewBg {
    return UIColor.ne_backgroundColor;
}

+ (UIColor *)normalChatAddMoreViewBg {
    return UIColor.ne_backgroundColor;
}

+ (UIColor *)normalChatInputViewPlaceholderTextColor {
    UIColor *color = [ChatUIConfig shared].messageProperties.inputPlaceholderTextColor;
    return color ?: UIColor.grayColor;
}

+ (UIColor *)normalSearchMessageCellBg {
    return [UIColor ne_colorWithHexString:@"#F9F9F9"];
}

+ (UIColor *)normalSearchDateButtonBg {
    return [UIColor ne_colorWithHexString:@"#337EFF"];
}

@end
