
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatRouter.h"
#import <NEChatKitOC/Router.h>
#import <NEChatKitOC/NERouterUrl.h>
#import <NEChatKitOC/ChatRepo.h>
#import <NEChatKitOC/NEALog.h>
#import <NIMSDK/NIMSDK.h>

@implementation ChatRouter

+ (void)registerCommon {
  // sendMessage
  [Router.shared register:ChatAddFriendRouter closure:^(NSDictionary<NSString *, id> *params) {
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
