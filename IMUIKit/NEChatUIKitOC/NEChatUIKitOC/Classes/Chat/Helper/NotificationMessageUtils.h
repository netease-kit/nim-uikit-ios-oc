// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class V2NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NotificationMessageUtils : NSObject

+ (NSString *)textForNotification:(V2NIMMessage *)message;
+ (NSString *)textForNotificationWithMessage:(V2NIMMessage *)message;

/// Whether it's a team notification
+ (BOOL)isDiscussSeniorTeamNoti:(V2NIMMessage *)message;

/// Check if team leave or dismiss
+ (BOOL)isTeamLeave:(V2NIMMessage *)message;
+ (BOOL)isTeamDismiss:(V2NIMMessage *)message;

+ (NSString *)textForTeamNotificationMessage:(V2NIMMessage *)message;

+ (NSString *)fromName:(V2NIMMessage *)message;
+ (NSArray<NSString *> *)toName:(V2NIMMessage *)message;
+ (NSString *)teamName:(V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
