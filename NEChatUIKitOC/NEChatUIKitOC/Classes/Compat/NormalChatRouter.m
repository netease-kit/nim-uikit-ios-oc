// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalChatRouter.h"
#import "PinMessageViewController.h"
#import "P2PChatViewController.h"
#import "TeamChatViewController.h"
#import "HistoryMessageController.h"
#import "ChatViewController.h"
#import "NEBaseChatRouter.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>

static NSString * const NEChatCompatPushPinMessageVCRouter = @"imkit://chat/pinMessage.page";
static NSString * const NEChatCompatPushP2pChatVCRouter = @"imkit://chat/p2pChat.page";
static NSString * const NEChatCompatPushTeamChatVCRouter = @"imkit://chat/teamChat.page";
static NSString * const NEChatCompatSearchMessageRouter = @"imkit://chat/searchMessage.page";

static BOOL NECompatChatRouterBoolValue(id value, BOOL defaultValue) {
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

static NSArray<V2NIMMessage *> *NECompatChatRouterMessagesValue(id value) {
    if (![value isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray<V2NIMMessage *> *messages = [NSMutableArray array];
    for (id obj in (NSArray *)value) {
        if ([obj isKindOfClass:[V2NIMMessage class]]) {
            [messages addObject:obj];
        }
    }
    return messages.count > 0 ? [messages copy] : nil;
}

@implementation NormalChatRouter

+ (void)register {
    [ChatRouter registerCommon];



    [Router.shared register:NEChatCompatPushPinMessageVCRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NECompatChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;

        PinMessageViewController *pin = [[PinMessageViewController alloc] initWithConversationId:conversationId];
        [nav pushViewController:pin animated:animated];
    }];

    [Router.shared register:NEChatCompatPushP2pChatVCRouter closure:^(NSDictionary *param) {
        if ([ChatRouter presentConversationIfHandledWithRoute:NEChatCompatPushP2pChatVCRouter parameters:param]) return;
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NECompatChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;

        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NECompatChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);
        P2PChatViewController *p2pChatVC = [[P2PChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSMutableArray<UIViewController *> *viewControllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
        for (NSInteger i = 0; i < viewControllers.count; i++) {
            UIViewController *vc = viewControllers[i];
            if ([vc isKindOfClass:[ChatViewController class]]) {
                if ([vc isKindOfClass:[P2PChatViewController class]]) {
                    ChatViewController *chatVC = (ChatViewController *)vc;
                    [chatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    [chatVC loadData];
                    [nav popToViewController:vc animated:animated];
                } else {
                    [p2pChatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    viewControllers[i] = p2pChatVC;
                    nav.viewControllers = viewControllers;
                    [nav popToViewController:p2pChatVC animated:animated];
                }
                return;
            }
        }

        [p2pChatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];

        NSInteger count = nav.viewControllers.count;
        [nav pushViewController:p2pChatVC animated:animated];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (NECompatChatRouterBoolValue(param[@"removeUserVC"], NO)) {
                NSInteger currentCount = count;
                NSMutableArray *controllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                while (currentCount > 1 && currentCount <= (NSInteger)controllers.count && [controllers.lastObject isKindOfClass:[ChatViewController class]]) {
                    [controllers removeObjectAtIndex:currentCount - 1];
                    currentCount--;
                }
                nav.viewControllers = controllers;
            }
        });
    }];

    [Router.shared register:NEChatCompatPushTeamChatVCRouter closure:^(NSDictionary *param) {
        if ([ChatRouter presentConversationIfHandledWithRoute:NEChatCompatPushTeamChatVCRouter parameters:param]) return;
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NECompatChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;

        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NECompatChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);
        TeamChatViewController *groupVC = [[TeamChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSMutableArray<UIViewController *> *viewControllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
        for (NSInteger i = 0; i < viewControllers.count; i++) {
            UIViewController *vc = viewControllers[i];
            if ([vc isKindOfClass:[ChatViewController class]]) {
                if ([vc isKindOfClass:[TeamChatViewController class]]) {
                    ChatViewController *chatVC = (ChatViewController *)vc;
                    [chatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    [chatVC loadData];
                    [nav popToViewController:vc animated:animated];
                } else {
                    [groupVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    viewControllers[i] = groupVC;
                    nav.viewControllers = viewControllers;
                    [nav popToViewController:groupVC animated:animated];
                }
                return;
            }
        }

        [groupVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
        NSInteger count = nav.viewControllers.count;
        [nav pushViewController:groupVC animated:animated];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (NECompatChatRouterBoolValue(param[@"removeTeamVC"], NO)) {
                NSMutableArray *controllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                if (count > 1 && count <= (NSInteger)controllers.count && [controllers.lastObject isKindOfClass:[ChatViewController class]]) {
                    [controllers removeObjectAtIndex:count - 1];
                    nav.viewControllers = controllers;
                }
            }
        });
    }];

    [Router.shared register:NEChatCompatSearchMessageRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NECompatChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;

        HistoryMessageController *searchMsgCtrl = [[HistoryMessageController alloc] initWithConversationId:conversationId];
        [nav pushViewController:searchMsgCtrl animated:animated];
    }];
}

@end
