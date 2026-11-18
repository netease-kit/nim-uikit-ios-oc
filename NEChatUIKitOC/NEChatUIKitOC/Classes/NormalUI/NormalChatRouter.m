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

static BOOL NEChatRouterBoolValue(id value, BOOL defaultValue) {
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

static NSArray<V2NIMMessage *> *NEChatRouterMessagesValue(id value) {
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


static NSString *NENormalBotSessionName(NSDictionary *param, NSString *sessionId) {
    id value = param[@"sessionName"];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return [[NEAIUserManager shared] getShowName:sessionId] ?: sessionId;
}

@implementation NormalChatRouter

+ (void)register {
    [ChatRouter registerCommon];



    // pin
    [[Router shared] register:PushPinMessageVCRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        PinMessageViewController *pin = [[PinMessageViewController alloc] initWithConversationId:conversationId];
        [nav pushViewController:pin animated:animated];
    }];

    // p2p
    [[Router shared] register:PushP2pChatVCRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NEChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);
        P2PChatViewController *p2pChatVC = [[P2PChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSArray *viewControllers = nav.viewControllers ?: @[];
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
                    NSMutableArray *vcs = [viewControllers mutableCopy] ?: [NSMutableArray array];
                    p2pChatVC.hidesBottomBarWhenPushed = vc.hidesBottomBarWhenPushed || i > 0;
                    vcs[i] = p2pChatVC;
                    nav.viewControllers = vcs;
                    [nav popToViewController:p2pChatVC animated:animated];
                }
                return;
            }
        }

        [p2pChatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];

        __block NSInteger count = nav.viewControllers.count;
        [nav pushViewController:p2pChatVC animated:animated];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BOOL removeUserVC = NEChatRouterBoolValue(param[@"removeUserVC"], NO);
            if (removeUserVC) {
                NSMutableArray *vcs = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                while (count > 1 && count <= (NSInteger)vcs.count && [vcs.lastObject isKindOfClass:[ChatViewController class]]) {
                    [vcs removeObjectAtIndex:count - 1];
                    count--;
                }
                nav.viewControllers = vcs;
            }
        });
    }];

    // group
    [[Router shared] register:PushTeamChatVCRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NEChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);
        TeamChatViewController *groupVC = [[TeamChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSArray *viewControllers = nav.viewControllers ?: @[];
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
                    NSMutableArray *vcs = [viewControllers mutableCopy] ?: [NSMutableArray array];
                    vcs[i] = groupVC;
                    nav.viewControllers = vcs;
                    [nav popToViewController:groupVC animated:animated];
                }
                return;
            }
        }

        [groupVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
        NSInteger count = nav.viewControllers.count;
        [nav pushViewController:groupVC animated:animated];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BOOL removeTeamVC = NEChatRouterBoolValue(param[@"removeTeamVC"], NO);
            if (removeTeamVC) {
                NSMutableArray *vcs = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                if (count > 1 && count <= (NSInteger)vcs.count && [vcs.lastObject isKindOfClass:[ChatViewController class]]) {
                    [vcs removeObjectAtIndex:count - 1];
                    nav.viewControllers = vcs;
                }
            }
        });
    }];

    [[Router shared] register:SearchMessageRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length > 0 && nav) {
            HistoryMessageController *searchMsgCtrl = [[HistoryMessageController alloc] initWithConversationId:conversationId];
            [nav pushViewController:searchMsgCtrl animated:animated];
        }
    }];
}

@end
