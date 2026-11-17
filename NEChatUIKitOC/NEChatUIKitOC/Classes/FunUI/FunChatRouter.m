// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatRouter.h"
#import "NEBaseChatRouter.h"
#import <NEChatKit/Router.h>

#import "FunPinMessageViewController.h"
#import "FunP2PChatViewController.h"
#import "FunTeamChatViewController.h"
#import "FunHistoryMessageController.h"
#import "ChatViewController.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatKit.h>

static NSString * const NEFunPushPinMessageVCRouter = @"imkit://chat/pinMessage.page";
static NSString * const NEFunPushP2pChatVCRouter = @"imkit://chat/p2pChat.page";
static NSString * const NEFunPushTeamChatVCRouter = @"imkit://chat/teamChat.page";
static NSString * const NEFunSearchMessageRouter = @"imkit://chat/searchMessage.page";

static NSString *NEFunBotSessionName(NSDictionary *param, NSString *sessionId) {
    id value = param[@"sessionName"];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return [[NEAIUserManager shared] getShowName:sessionId] ?: sessionId;
}

static BOOL NEFunChatRouterBoolValue(id value, BOOL defaultValue) {
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

static NSArray<V2NIMMessage *> *NEFunChatRouterMessagesValue(id value) {
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

@implementation ChatRouter (Fun)

+ (void)registerFun {
    [self registerCommon];



    // pin
    [Router.shared register:NEFunPushPinMessageVCRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEFunChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        FunPinMessageViewController *pin = [[FunPinMessageViewController alloc] initWithConversationId:conversationId];
        [nav pushViewController:pin animated:animated];
    }];

    // p2p
    [Router.shared register:NEFunPushP2pChatVCRouter closure:^(NSDictionary *param) {
        if ([ChatRouter presentConversationIfHandledWithRoute:NEFunPushP2pChatVCRouter parameters:param]) return;
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEFunChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NEFunChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);

        FunP2PChatViewController *p2pChatVC = [[FunP2PChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSMutableArray *vcs = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
        for (NSInteger i = 0; i < vcs.count; i++) {
            UIViewController *vc = vcs[i];
            if ([vc isKindOfClass:[ChatViewController class]]) {
                if ([vc isKindOfClass:[FunP2PChatViewController class]]) {
                    ChatViewController *chatVC = (ChatViewController *)vc;
                    [chatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    [chatVC loadData];
                    [nav popToViewController:vc animated:animated];
                } else {
                    [p2pChatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    p2pChatVC.hidesBottomBarWhenPushed = vc.hidesBottomBarWhenPushed || i > 0;
                    vcs[i] = p2pChatVC;
                    nav.viewControllers = vcs;
                    [nav popToViewController:p2pChatVC animated:animated];
                }
                return;
            }
        }

        [p2pChatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];

        NSInteger count = nav.viewControllers.count;
        [nav pushViewController:p2pChatVC animated:animated];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (NEFunChatRouterBoolValue(param[@"removeUserVC"], NO)) {
                NSInteger c = count;
                NSMutableArray *viewControllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                while (c > 1 && c <= (NSInteger)viewControllers.count && [viewControllers.lastObject isKindOfClass:[ChatViewController class]]) {
                    [viewControllers removeObjectAtIndex:c - 1];
                    c--;
                }
                nav.viewControllers = viewControllers;
            }
        });
    }];

    // group
    [Router.shared register:NEFunPushTeamChatVCRouter closure:^(NSDictionary *param) {
        if ([ChatRouter presentConversationIfHandledWithRoute:NEFunPushTeamChatVCRouter parameters:param]) return;
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEFunChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length <= 0 || !nav) return;
        V2NIMMessage *anchor = [param[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? param[@"anchor"] : nil;
        NSArray<V2NIMMessage *> *onReceiveNewMsgs = NEFunChatRouterMessagesValue(param[@"onReceiveNewMsgs"]);

        FunTeamChatViewController *groupVC = [[FunTeamChatViewController alloc] initWithConversationId:conversationId anchor:anchor];

        NSMutableArray *vcs = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
        for (NSInteger i = 0; i < vcs.count; i++) {
            UIViewController *vc = vcs[i];
            if ([vc isKindOfClass:[ChatViewController class]]) {
                if ([vc isKindOfClass:[FunTeamChatViewController class]]) {
                    ChatViewController *chatVC = (ChatViewController *)vc;
                    [chatVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
                    [chatVC loadData];
                    [nav popToViewController:vc animated:animated];
                } else {
                    [groupVC applyHistoryAnchor:anchor transferredNewMessages:onReceiveNewMsgs];
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
            if (NEFunChatRouterBoolValue(param[@"removeTeamVC"], NO)) {
                NSMutableArray *viewControllers = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
                if (count > 1 && count <= (NSInteger)viewControllers.count && [viewControllers.lastObject isKindOfClass:[ChatViewController class]]) {
                    [viewControllers removeObjectAtIndex:count - 1];
                    nav.viewControllers = viewControllers;
                }
            }
        });
    }];

    // search
    [Router.shared register:NEFunSearchMessageRouter closure:^(NSDictionary *param) {
        UINavigationController *nav = [param[@"nav"] isKindOfClass:[UINavigationController class]] ? param[@"nav"] : nil;
        BOOL animated = NEFunChatRouterBoolValue(param[@"animated"], YES);
        NSString *conversationId = [param[@"conversationId"] isKindOfClass:[NSString class]] ? param[@"conversationId"] : nil;
        if (conversationId.length > 0 && nav) {
            FunHistoryMessageController *searchMsgCtrl = [[FunHistoryMessageController alloc] initWithConversationId:conversationId];
            [nav pushViewController:searchMsgCtrl animated:animated];
        }
    }];
}

@end
