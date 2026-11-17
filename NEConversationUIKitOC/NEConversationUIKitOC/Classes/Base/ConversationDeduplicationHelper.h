// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConversationDeduplicationHelper : NSObject <NEIMKitClientListener>

@property (class, nonatomic, readonly) ConversationDeduplicationHelper *instance;
@property (nonatomic, assign) NSInteger limit;
@property (nonatomic, strong) NSMutableSet<NSString *> *revokeMessageIds;

- (void)clearCache;
- (BOOL)isRevokeMessageSaved:(NSString *)messageId;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
