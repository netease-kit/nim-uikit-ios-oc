// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/IMKitClient.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NEAtMessageChangeNoti;

@interface AtMessageModel : NSObject
@property(nonatomic, copy, nullable) NSString *messageId;
@property(nonatomic, strong, nullable) NSNumber *messageTime;
@end

@interface AtMEMessageRecord : NSObject
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *atMessages;
@property(nonatomic, strong, nullable) NSNumber *lastTime;
@property(nonatomic, assign) BOOL isRead;
@end

@interface NEAtMessageManager : NSObject <NEChatListener, NEIMKitClientListener>

@property(class, nonatomic, strong, nullable) NEAtMessageManager *instance;

/// Compatibility alias for existing Objective-C callers. Lazily creates the manager.
+ (nullable instancetype)sharedManager;
+ (void)setupInstance;

- (BOOL)isAtCurrentUserConversationId:(NSString *)conversationId;
- (BOOL)isAtCurrentUserWithConversationId:(NSString *)conversationId;
- (BOOL)isAtCurrentUser:(NSString *)conversationId;
- (void)clearAtRecord:(NSString *)conversationId;
- (void)filterAtMessage:(NSArray<V2NIMMessage *> *)messages;
- (void)filterAtMessageWithMessages:(NSArray<V2NIMMessage *> *)messages;
- (void)startFilterRoamingMessagesTask;
- (void)removeRevokeAtMessage:(NSArray<V2NIMMessageRefer *> *)messages;
- (void)removeRevokeAtMessageWithMessages:(NSArray<V2NIMMessageRefer *> *)messages;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
