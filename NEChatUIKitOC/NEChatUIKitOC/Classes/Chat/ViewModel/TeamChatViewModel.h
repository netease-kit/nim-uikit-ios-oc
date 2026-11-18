// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "ChatViewModel.h"
#import "NETeamUserManager.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TeamChatViewModelDelegate <ChatViewModelDelegate>

@optional
- (void)onTeamRemoved:(V2NIMTeam *)team;
- (void)onTeamUpdate:(V2NIMTeam *)team;
- (void)onTeamMemberUpdate:(NSArray<V2NIMTeamMember *> *)teamMembers;

@end

@interface TeamChatViewModel : ChatViewModel <NETeamListener, NETeamChatUserCacheListener, NEIMKitClientListener>

@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, strong, nullable) V2NIMTeamMember *teamMember;

- (void)refreshTeamInfoAndSelfMember:(NSString *)teamId completion:(void (^)(void))completion;

/// 加载群信息
- (void)getTeamInfoWithTeamId:(NSString *)teamId completion:(void (^)(NSError *_Nullable error, V2NIMTeam *_Nullable team))completion;

/// 获取自己的群成员信息
- (void)getTeamMember:(void (^)(void))completion;

/// 群消息发送已读回执
- (void)markReadInTeam:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable error))completion;

/// 获取群消息已读未读回执
- (void)getTeamMessageReceipts:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *reloadIndexs, NSError *_Nullable error))completion;

/// 校验置顶消息权限
- (BOOL)hasTopMessagePremission;

@end

NS_ASSUME_NONNULL_END
