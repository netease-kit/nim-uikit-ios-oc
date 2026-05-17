// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

@interface NEAddApplication : NSObject

/// 申请添加好友的相关信息
@property (nonatomic, strong) V2NIMFriendAddApplication *v2Notification;

/// 用于显示的用户 Id
@property (nonatomic, copy, nullable) NSString *displayUserId;

/// 用于显示的用户信息（包含好友信息）
@property (nonatomic, strong, nullable) NEUserWithFriend *displayUserWithFriend;

/// 未读数
@property (nonatomic, assign) NSInteger unreadCount;

/// 消息处理状态
@property (nonatomic, assign) V2NIMFriendAddApplicationStatus handleStatus;

/// 操作描述
@property (nonatomic, copy) NSString *detail;

- (instancetype)initWithApplication:(V2NIMFriendAddApplication *)info;

/// 是否是同一申请
- (BOOL)isEqualTo:(V2NIMFriendAddApplication *)noti
     compareStatus:(BOOL)compareStatus;

/// 是否是同一申请（默认 compareStatus = YES）
- (BOOL)isEqualTo:(V2NIMFriendAddApplication *)noti;

@end

NS_ASSUME_NONNULL_END
