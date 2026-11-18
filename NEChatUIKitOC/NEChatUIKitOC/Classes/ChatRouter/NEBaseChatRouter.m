
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatRouter.h"

#import "ChatViewController.h"

#import <objc/runtime.h>

static void *NEChatConversationPresentationKey = &NEChatConversationPresentationKey;

static NEChatConversationPresentationHandler NEChatConversationFallbackHandler = nil;

/// 关联对象承载者：navigationController 释放时自动失效。
@interface NEChatConversationPresentationBlock : NSObject
@property (nonatomic, copy) NEChatConversationPresentationHandler handler;
@end

@implementation NEChatConversationPresentationBlock
@end
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/NEALog.h>
#import <NIMSDK/NIMSDK.h>

static NSString * const NEBaseChatAddFriendRouter = @"imkit://chat/addFriend";

@implementation ChatRouter

+ (void)setConversationPresentationHandler:(NEChatConversationPresentationHandler)handler
                    forNavigationController:(UINavigationController *)navigationController {
  if (!navigationController) {
    return;
  }
  if (!handler) {
    objc_setAssociatedObject(navigationController, NEChatConversationPresentationKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return;
  }
  NEChatConversationPresentationBlock *block = [[NEChatConversationPresentationBlock alloc] init];
  block.handler = handler;
  objc_setAssociatedObject(navigationController, NEChatConversationPresentationKey, block,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)setConversationFallbackHandler:(NEChatConversationPresentationHandler)handler {
  NEChatConversationFallbackHandler = [handler copy];
}

+ (BOOL)presentConversationIfHandledWithRoute:(NSString *)route
                                   parameters:(NSDictionary<NSString *, id> *)parameters {
  id declined = parameters[@"ne_conversation_presentation_declined"];
  if ([declined isKindOfClass:[NSNumber class]] && [declined boolValue]) {
    return NO;
  }
  if (![NSThread isMainThread]) {
    return NO;
  }
  id nav = parameters[@"nav"];
  if (![nav isKindOfClass:[UINavigationController class]]) {
    return NO;
  }
  NEChatConversationPresentationBlock *block =
      objc_getAssociatedObject(nav, NEChatConversationPresentationKey);
  if (block.handler) {
    return block.handler(route, parameters);
  }
  if (NEChatConversationFallbackHandler) {
    return NEChatConversationFallbackHandler(route, parameters);
  }
  return NO;
}

+ (BOOL)applyPresentationParameters:(NSDictionary<NSString *, id> *)parameters
                   toViewController:(UIViewController *)controller
                             reload:(BOOL)reload {
  if (![controller isKindOfClass:[ChatViewController class]]) {
    return NO;
  }
  ChatViewController *chat = (ChatViewController *)controller;
  id anchor = parameters[@"anchor"];
  V2NIMMessage *message = [anchor isKindOfClass:[V2NIMMessage class]] ? anchor : nil;
  id transferred = parameters[@"onReceiveNewMsgs"];
  NSArray<V2NIMMessage *> *messages =
      [transferred isKindOfClass:[NSArray class]] ? (NSArray<V2NIMMessage *> *)transferred : nil;
  [chat applyHistoryAnchor:message transferredNewMessages:messages];
  if (reload) {
    [chat loadData];
  }
  return YES;
}

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
