
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatRouter.h"
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/NEALog.h>
#import <NIMSDK/NIMSDK.h>

static NSString * const NEBaseChatAddFriendRouter = @"imkit://chat/addFriend";

@implementation ChatRouter

+ (void)registerCommon {
  // sendMessage
  [Router.shared register:NEBaseChatAddFriendRouter closure:^(NSDictionary<NSString *, id> *params) {
    NSString *text = params[@"text"];
    NSString *cid = params[@"conversationId"];
    if ([text isKindOfClass:[NSString class]] && [cid isKindOfClass:[NSString class]]) {
      V2NIMMessage *helloMessage = [V2NIMMessageCreator createTextMessage:text];
      [ChatRepo.shared sendMessage:helloMessage
                    conversationId:cid
                            params:nil
                        completion:^(V2NIMSendMessageResult *_Nullable result,
                                     NSError *_Nullable error,
                                     NSUInteger progress) {
        [NEALog errorLog:@"ChatAddFriendRouter"
                    desc:[NSString stringWithFormat:@"send hello message error:%@",
                          error.localizedDescription ?: @"nil"]];
      }];
    }
  }];
}

@end
