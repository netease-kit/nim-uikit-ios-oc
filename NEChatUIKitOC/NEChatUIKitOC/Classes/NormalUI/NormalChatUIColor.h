// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatUIConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (NormalChat)

/// 导航栏（包含状态栏）背景色
@property (class, nonatomic, readonly) UIColor *normalChatNavigationBg;
/// 导航栏分割线背景色
@property (class, nonatomic, readonly) UIColor *normalChatNavigationDivideBg;
/// 聊天页面顶部扩展视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatBodyTopViewBg;
/// 聊天页面内容视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatBodyViewBg;
/// 聊天页面断网视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatNetworkBrokenViewBg;
/// 断网文案颜色
@property (class, nonatomic, readonly) UIColor *normalChatNetworkBrokenTitleColor;
/// 聊天页面消息列表背景色
@property (class, nonatomic, readonly) UIColor *normalChatTableViewBg;
/// 聊天页面底部扩展视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatBodyBottomViewBg;
/// 聊天页面输入区域背景色
@property (class, nonatomic, readonly) UIColor *normalChatInputViewBg;
/// 输入框背景色(非禁言)
@property (class, nonatomic, readonly) UIColor *normalChatInputBg;
/// 输入框背景色(禁言)
@property (class, nonatomic, readonly) UIColor *normalChatInputMuteBg;
/// 回复视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatReplyViewBg;
/// 录音视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatRecordViewBg;
/// 更多功能视图背景色
@property (class, nonatomic, readonly) UIColor *normalChatAddMoreViewBg;
/// 输入框占位文案颜色
@property (class, nonatomic, readonly) UIColor *normalChatInputViewPlaceholderTextColor;
/// 搜索聊天记录选项背景色
@property (class, nonatomic, readonly) UIColor *normalSearchMessageCellBg;
@property (class, nonatomic, readonly) UIColor *normalSearchDateButtonBg;
/// 消息译文区域分割线颜色，与 SwiftUI Normal token 一致。
@property (class, nonatomic, readonly) UIColor *normalChatTranslationDividerColor;
/// 消息译文标签颜色，与 SwiftUI Normal token 一致。
@property (class, nonatomic, readonly) UIColor *normalChatTranslationTagColor;

@end

NS_ASSUME_NONNULL_END
