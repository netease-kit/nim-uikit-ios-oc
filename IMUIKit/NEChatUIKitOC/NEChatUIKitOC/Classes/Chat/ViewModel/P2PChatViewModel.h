// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "ChatViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface P2PChatViewModel : ChatViewModel

@property (nonatomic, assign) BOOL online;

/// 单人会话消息发送已读回执
- (void)markReadInP2P:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable error))completion;

/// 获取 P2P 消息已读未读回执
- (void)getP2PMessageReceipt:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *reloadIndexs, NSError *_Nullable error))completion;

/// 发送正在输入中状态
- (void)sendInputTypingState;

/// 发送结束输入中状态
- (void)sendInputTypingEndState;

/// 发送输入状态
- (void)setTypingCustom:(NSInteger)typing;

/// 订阅在线状态
- (void)subscribeOnlineStatus;

/// 取消订阅
- (void)unsubscribeOnlineStatus;

@end

NS_ASSUME_NONNULL_END
