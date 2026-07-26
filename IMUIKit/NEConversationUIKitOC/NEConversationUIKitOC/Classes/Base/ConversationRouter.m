// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationRouter.h"
#import "NEAtMessageManager.h"
#import "ConversationSearchController.h"
#import "FunConversationSearchController.h"
#import "NEConversationViewController.h"
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>

static NSString * const NEConversationSearchContactPageRouter = @"imkit://search/search.page";
static NSString * const NEConversationPageRouter = @"imkit://conversation/conversation.page";

@implementation ConversationRouter

+ (void)register {
  [self registerCommon];

  [[Router shared] register:NEConversationSearchContactPageRouter closure:^(NSDictionary<NSString *,id> * _Nonnull param) {
    UINavigationController *nav = param[@"nav"];
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    ConversationSearchController *searchCtrl = [[ConversationSearchController alloc] init];
    [nav pushViewController:searchCtrl animated:animated];
  }];

  [[Router shared] register:NEConversationPageRouter closure:^(NSDictionary<NSString *,id> * _Nonnull param) {
    UINavigationController *nav = param[@"nav"];
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    NEConversationViewController *conversation = [NEConversationViewController cloudController];
    [nav pushViewController:conversation animated:animated];
  }];
}

+ (void)registerFun {
  [self registerCommon];

  [[Router shared] register:NEConversationSearchContactPageRouter closure:^(NSDictionary<NSString *,id> * _Nonnull param) {
    UINavigationController *nav = param[@"nav"];
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    FunConversationSearchController *searchCtrl = [[FunConversationSearchController alloc] init];
    [nav pushViewController:searchCtrl animated:animated];
  }];

  [[Router shared] register:NEConversationPageRouter closure:^(NSDictionary<NSString *,id> * _Nonnull param) {
    UINavigationController *nav = param[@"nav"];
    BOOL animated = [param[@"animated"] isKindOfClass:[NSNumber class]] ? [param[@"animated"] boolValue] : YES;
    NEConversationViewController *conversation = [NEConversationViewController cloudController];
    [nav pushViewController:conversation animated:animated];
  }];
}

+ (void)registerCommon {
  [[Router shared] register:@"ClearAtMessageRemind" closure:^(NSDictionary<NSString *,id> * _Nonnull param) {
    NSString *conversationId = [param[@"sessionId"] isKindOfClass:[NSString class]] ? param[@"sessionId"] : @"";
    if (conversationId.length > 0) {
      [[NEAtMessageManager sharedManager] clearAtRecord:conversationId];
    }
  }];
}

@end
