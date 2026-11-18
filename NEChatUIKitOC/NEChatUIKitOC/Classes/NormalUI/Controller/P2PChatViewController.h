// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatViewController.h"
#import "P2PChatViewModel.h"
#import <NEChatKit/ContactRepo.h>
#import "NEP2PChatUserCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface P2PChatViewController : NormalChatViewController <NEContactListener, NEP2PChatUserCacheListener>

- (instancetype)initWithConversationId:(NSString *)conversationId;
- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor;
- (NSMutableAttributedString *)getPlaceHolder:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
