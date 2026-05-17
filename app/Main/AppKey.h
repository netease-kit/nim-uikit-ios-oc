// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Swift AppKey.swift / Constant.swift

/// AppKey.swift 中的 Demo 账号占位配置
FOUNDATION_EXPORT NSString *const NEAppKey;
FOUNDATION_EXPORT NSString *const NEAPNSCername;
FOUNDATION_EXPORT NSString *const NEPKCerName;
FOUNDATION_EXPORT NSString *const NEAppAccount;
FOUNDATION_EXPORT NSString *const NEAppToken;

/// 通知名
FOUNDATION_EXPORT NSString *const NENotificationLogout;
FOUNDATION_EXPORT NSString *const NENotificationChangeLanguage;
FOUNDATION_EXPORT NSString *const NENotificationChangeUI;

/// 本地化字符串快捷方法
FOUNDATION_EXPORT NSString *NELocalizedString(NSString *key);

/// 本地化辅助宏
#define NELocalizable(key) NELocalizedString(key)

NS_ASSUME_NONNULL_END
