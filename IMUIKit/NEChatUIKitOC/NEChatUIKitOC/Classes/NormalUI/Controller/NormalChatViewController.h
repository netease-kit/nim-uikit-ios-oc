// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NormalChatViewController : ChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId;
- (void)getMessageModel:(id<MessageModel>)model;
- (void)checkAndRemoveReplyView;
- (void)checkAndRestoreReplyView;

@end

NS_ASSUME_NONNULL_END
