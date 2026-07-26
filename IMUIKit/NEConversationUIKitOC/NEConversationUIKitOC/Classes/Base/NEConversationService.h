// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/ChatKitClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEConversationService : NSObject <ChatServiceDelegate>

+ (instancetype)shared;

- (void)setupInit:(NSDictionary<NSString *, id> * _Nullable)params;
- (void)registerRouter:(NSDictionary<NSString *, id> * _Nullable)param;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
