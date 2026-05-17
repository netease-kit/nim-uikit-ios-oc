// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/ChatRepo.h>
#import <NEChatKitOC/IMKitClient.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NEAtMessageChangeNoti;

@interface NEAtMessageManager : NSObject <NEChatListener, NEIMKitClientListener>

+ (instancetype)sharedManager;
+ (void)setupInstance;

- (BOOL)isAtCurrentUserConversationId:(NSString *)conversationId;
- (void)clearAtRecord:(NSString *)conversationId;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
