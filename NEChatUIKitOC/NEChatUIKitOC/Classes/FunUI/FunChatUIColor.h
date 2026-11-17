// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// FunChat 主题颜色扩展
@interface UIColor (FunChat)

// 主题色
@property (class, nonatomic, readonly) UIColor *funChatThemeColor;
@property (class, nonatomic, readonly) UIColor *funChatBackgroundColor;
@property (class, nonatomic, readonly) UIColor *funChatLineBorderColor;

// 导航栏相关
@property (class, nonatomic, readonly) UIColor *funChatNavigationBg;
@property (class, nonatomic, readonly) UIColor *funChatNavigationDivideBg;

// 聊天视图相关
@property (class, nonatomic, readonly) UIColor *funChatBodyTopViewBg;
@property (class, nonatomic, readonly) UIColor *funChatBodyViewBg;
@property (class, nonatomic, readonly) UIColor *funChatNetworkBrokenViewBg;
@property (class, nonatomic, readonly) UIColor *funChatNetworkBrokenTitleColor;
@property (class, nonatomic, readonly) UIColor *funChatTableViewBg;
@property (class, nonatomic, readonly) UIColor *funChatBodyBottomViewBg;
@property (class, nonatomic, readonly) UIColor *funChatInputViewBg;
@property (class, nonatomic, readonly) UIColor *funChatInputBg;
@property (class, nonatomic, readonly) UIColor *funChatInputMuteBg;
@property (class, nonatomic, readonly) UIColor *funChatReplyViewBg;
@property (class, nonatomic, readonly) UIColor *funChatAddMoreViewBg;
@property (class, nonatomic, readonly) UIColor *funChatInputHoldspeakBg;
@property (class, nonatomic, readonly) UIColor *funChatInputHoldspeakTextColor;
@property (class, nonatomic, readonly) UIColor *funChatAddMoreActionViewLineColor;

// 录音视图相关
@property (class, nonatomic, readonly) UIColor *funRecordAudioViewBg;
@property (class, nonatomic, readonly) UIColor *funRecordAudioTextColor;
@property (class, nonatomic, readonly) UIColor *funRecordAudioProgressNormalColor;
@property (class, nonatomic, readonly) UIColor *funRecordAudioProgressCancelColor;
@property (class, nonatomic, readonly) UIColor *funRecordAudioLastTimeColor;

// 输入框占位颜色
@property (class, nonatomic, readonly) UIColor *funChatInputViewPlaceholderTextColor;

// 其他
@property (class, nonatomic, readonly) UIColor *funChatMultiForwardContentColor;
@property (class, nonatomic, readonly) UIColor *funChatHistoryCellTitleTextColor;
@property (class, nonatomic, readonly) UIColor *funChatQuickHistoryCellTitleTextColor;

@end

NS_ASSUME_NONNULL_END
