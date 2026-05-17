// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/NECommonLoader.h>

NS_ASSUME_NONNULL_BEGIN

/// 全局 CommonUIKit 资源加载器
FOUNDATION_EXPORT NECommonLoader *coreLoader(void);

/// 本地化字符串快捷方法
FOUNDATION_EXPORT NSString *commonLocalizable(NSString *key);

/// 全局常量 key
FOUNDATION_EXPORT NSString *const useSystemNav;

NS_ASSUME_NONNULL_END
