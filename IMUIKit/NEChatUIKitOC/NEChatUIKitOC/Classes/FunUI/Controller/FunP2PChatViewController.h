// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatViewController.h"
#import <NEChatKit/ContactRepo.h>
#import "NEP2PChatUserCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunP2PChatViewController : FunChatViewController <NEContactListener, NEP2PChatUserCacheListener>
- (instancetype)initWithConversationId:(NSString *)conversationId;
- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor;
@end

NS_ASSUME_NONNULL_END
