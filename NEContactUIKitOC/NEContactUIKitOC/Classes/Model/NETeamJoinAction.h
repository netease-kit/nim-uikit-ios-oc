// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

/// 入群申请已读时间戳
FOUNDATION_EXPORT NSTimeInterval neTeamJoinActionReadTime;

/// 入群申请分页查询数量
FOUNDATION_EXPORT NSInteger neTeamJoinActionPageLimit;

@interface NETeamJoinAction : NSObject

/// 申请入群的相关信息
@property (nonatomic, strong) V2NIMTeamJoinActionInfo *nimTeamJoinAction;

/// 用于显示的用户 Id
@property (nonatomic, copy) NSString *displayUserId;

/// 用于显示的用户信息（包含好友信息）
@property (nonatomic, strong, nullable) NEUserWithFriend *displayUserWithFriend;

/// 用于显示的群信息
@property (nonatomic, strong, nullable) V2NIMTeam *displayTeam;

/// 未读数
@property (nonatomic, assign) NSInteger unreadCount;

/// 消息处理状态
@property (nonatomic, assign) V2NIMTeamJoinActionStatus handleStatus;

/// 操作描述
@property (nonatomic, copy) NSString *detail;

- (instancetype)initWithActionInfo:(V2NIMTeamJoinActionInfo *)info;
- (instancetype)init:(V2NIMTeamJoinActionInfo *)info;

/// 是否是同一申请
- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti
     compareStatus:(BOOL)compareStatus;
- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti :(BOOL)compareStatus;

/// 是否是同一申请（默认 compareStatus = YES）
- (BOOL)isEqualTo:(V2NIMTeamJoinActionInfo *)noti;

@end

NS_ASSUME_NONNULL_END
