// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatDeduplicationHelper : NSObject <NEIMKitClientListener>

@property (class, nonatomic, readonly) ChatDeduplicationHelper *instance;

/// Maximum cache count, can be modified externally
@property (nonatomic, assign) NSInteger limit;
/// Blacklist message ID records
@property (nonatomic, strong) NSMutableSet<NSString *> *blackListMessageIds;
/// Audio message path records
@property (nonatomic, strong) NSMutableSet<NSString *> *recordAudioMessagePaths;
/// Sending message ID records
@property (nonatomic, strong) NSMutableSet<NSString *> *sendingMessageIds;
/// Revoke message ID records
@property (nonatomic, strong) NSMutableSet<NSString *> *revokeMessageIds;

- (void)clearCache;

/// Whether a tip for this message has already been sent
- (BOOL)isMessageSended:(NSString *)messageId;

/// Whether a blacklist tip for this message has already been sent
- (BOOL)isBlackTipSended:(NSString *)messageId;

/// Remove blacklist tip dedup id
- (void)removeBlackTipSendedId:(nullable NSString *)messageId;

/// Whether an audio message for this path has already been sent
- (BOOL)isRecordAudioSended:(NSString *)path;

/// Whether this revoke message has already been saved
- (BOOL)isRevokeMessageSaved:(NSString *)messageId;

@end

NS_ASSUME_NONNULL_END
