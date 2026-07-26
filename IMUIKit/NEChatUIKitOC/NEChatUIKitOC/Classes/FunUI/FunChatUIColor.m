// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatUIColor.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatUIConfig.h"

@implementation UIColor (FunChat)

+ (UIColor *)funChatThemeColor {
    return [UIColor ne_funTheme];
}

+ (UIColor *)funChatBackgroundColor {
    return [UIColor ne_colorWithHexString:@"#EDEDED"];
}

+ (UIColor *)funChatLineBorderColor {
    return [UIColor ne_colorWithHexString:@"#E5E5E5"];
}

+ (UIColor *)funChatNavigationBg {
    return [UIColor funChatBackgroundColor];
}

+ (UIColor *)funChatNavigationDivideBg {
    return [[UIColor ne_colorWithHexString:@"#D5D5D5"] colorWithAlphaComponent:0.4];
}

+ (UIColor *)funChatBodyTopViewBg {
    return [UIColor clearColor];
}

+ (UIColor *)funChatBodyViewBg {
    return [UIColor clearColor];
}

+ (UIColor *)funChatNetworkBrokenViewBg {
    return [UIColor ne_colorWithHexString:@"#FCEEEE"];
}

+ (UIColor *)funChatNetworkBrokenTitleColor {
    return [UIColor colorWithWhite:0 alpha:0.5];
}

+ (UIColor *)funChatTableViewBg {
    return [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor ?: [UIColor clearColor];
}

+ (UIColor *)funChatBodyBottomViewBg {
    return [UIColor clearColor];
}

+ (UIColor *)funChatInputViewBg {
    return [UIColor ne_colorWithHexString:@"#F5F5F5"];
}

+ (UIColor *)funChatInputBg {
    return [UIColor whiteColor];
}

+ (UIColor *)funChatInputMuteBg {
    return [UIColor ne_colorWithHexString:@"#E0E0E0"];
}

+ (UIColor *)funChatReplyViewBg {
    return [UIColor ne_colorWithHexString:@"#E1E1E1"];
}

+ (UIColor *)funChatAddMoreViewBg {
    return [UIColor ne_colorWithHexString:@"#F5F5F5"];
}

+ (UIColor *)funChatInputHoldspeakBg {
    return [UIColor ne_colorWithHexString:@"#FFFFFF"];
}

+ (UIColor *)funChatInputHoldspeakTextColor {
    return [UIColor ne_colorWithHexString:@"#222222"];
}

+ (UIColor *)funChatAddMoreActionViewLineColor {
    return [UIColor ne_colorWithHexString:@"#DDDDDD"];
}

+ (UIColor *)funRecordAudioViewBg {
    return [UIColor ne_colorWithHexString:@"#000000"];
}

+ (UIColor *)funRecordAudioTextColor {
    return [UIColor ne_colorWithHexString:@"#AAAAAA"];
}

+ (UIColor *)funRecordAudioProgressNormalColor {
    return [UIColor ne_colorWithHexString:@"#A9EA7A"];
}

+ (UIColor *)funRecordAudioProgressCancelColor {
    return [UIColor ne_colorWithHexString:@"#E75D58"];
}

+ (UIColor *)funRecordAudioLastTimeColor {
    return [[UIColor ne_colorWithHexString:@"#000000"] colorWithAlphaComponent:0.4];
}

+ (UIColor *)funChatInputViewPlaceholderTextColor {
    return [ChatUIConfig shared].messageProperties.inputPlaceholderTextColor ?: [UIColor ne_colorWithHexString:@"#AAAAAA"];
}

+ (UIColor *)funChatMultiForwardContentColor {
    return [UIColor ne_colorWithHexString:@"#BBBBBB"];
}

+ (UIColor *)funChatHistoryCellTitleTextColor {
    return [UIColor ne_colorWithHexString:@"#737373"];
}

+ (UIColor *)funChatQuickHistoryCellTitleTextColor {
    return [UIColor ne_colorWithHexString:@"#596C96"];
}

@end
