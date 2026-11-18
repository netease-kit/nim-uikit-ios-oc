
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^NEChatConversationPresentationHandler)(NSString *route,
                                                      NSDictionary<NSString *, id> *parameters);

@interface ChatRouter : NSObject

+ (void)registerCommon;

/// 可选的呈现边界：未绑定时保持原 Router 行为；绑定后由外部容器决定最终呈现。
+ (void)setConversationPresentationHandler:(nullable NEChatConversationPresentationHandler)handler
                    forNavigationController:(UINavigationController *)navigationController;

+ (void)setConversationFallbackHandler:(nullable NEChatConversationPresentationHandler)handler;

/// 路由闭包入口：已接管返回 YES，调用方直接 return；未绑定时返回 NO。
+ (BOOL)presentConversationIfHandledWithRoute:(NSString *)route
                                   parameters:(NSDictionary<NSString *, id> *)parameters;

/// 在保留的聊天页上复用既有 anchor/恢复语义（不重建页面）。
+ (BOOL)applyPresentationParameters:(NSDictionary<NSString *, id> *)parameters
                   toViewController:(UIViewController *)controller
                             reload:(BOOL)reload;

@end

NS_ASSUME_NONNULL_END
