// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 中立的会话打开身份：只带上呈现所需的路由参数，不持有 SDK 模型。
@interface NEConversationOpenIntent : NSObject

/// 唯一键，建议 `<route>|<conversationId>|<sessionId>|<topicId>`。
@property (nonatomic, copy, readonly) NSString *key;
/// 原路由标识，原样保留给既有 Router / 工厂使用。
@property (nonatomic, copy, readonly) NSString *route;
/// 原路由参数，原样保留（定位、锚点、恢复动作等都在里面）。
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *parameters;
/// 是否携带定位/恢复动作；为 YES 时即使命中同一会话也要执行呈现动作。
@property (nonatomic, assign, readonly) BOOL requiresPresentationAction;

- (instancetype)initWithKey:(NSString *)key
                      route:(NSString *)route
                 parameters:(NSDictionary<NSString *, id> *)parameters
 requiresPresentationAction:(BOOL)requiresPresentationAction NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@protocol NEConversationPresentationHandler <NSObject>

- (BOOL)openConversation:(NEConversationOpenIntent *)intent;

@end

NS_ASSUME_NONNULL_END
