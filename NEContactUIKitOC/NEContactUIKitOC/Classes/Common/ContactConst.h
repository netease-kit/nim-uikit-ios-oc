// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 路由 URL 常量（声明在 NEChatKit/NERouterUrl.h，这里 re-export）
#import <NEChatKit/NERouterUrl.h>

// Router 类（声明在 NEChatKit/Router.h）
#import <NEChatKit/Router.h>

@class ContactInfo;
@class NEContactBaseViewController;

NS_ASSUME_NONNULL_BEGIN

/// 通讯录 cell 类型
typedef NS_ENUM(NSInteger, ContactCellType) {
  ContactCellTypeContactOthers = 1, // blacklist groups computer and so on
  ContactCellTypeContactPerson = 2, // contact person
  ContactCellTypeContactCustom = 50, // custom type start with 50
};

/// 通讯录选择完成回调
typedef void (^ContactsSelectCompletion)(NSArray<ContactInfo *> *selectedContacts);

/// 模块名
FOUNDATION_EXPORT NSString *const ModuleName;

/// 切换语言通知名（对应 Swift 版 NENotificationName.changeLanguage）
FOUNDATION_EXPORT NSNotificationName const NENotificationNameChangeLanguage;

/// localizable 函数
FOUNDATION_EXPORT NSString *contactLocalizable(NSString *key);

/// 加载图片
FOUNDATION_EXPORT UIImage *_Nullable ne_contactImageNamed(NSString *_Nullable name);

/// 将 AI 机器人操作的 NSError 转换为用户友好的提示文案
FOUNDATION_EXPORT NSString *robotErrorMessage(NSError *error);

NS_ASSUME_NONNULL_END
