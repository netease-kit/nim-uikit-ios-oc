// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationOpenIntent.h"

NS_ASSUME_NONNULL_BEGIN

/// 只拥有右列的导航状态；会话页的创建与业务初始化仍由接入方的工厂负责。
///
/// - 同一会话重复打开为 no-op；带定位动作时在保留的聊天根上执行一次；
/// - A→B 只替换详情页，栈深不增长；
/// - 有占位根时把会话页压在占位之上，返回按页面自身语义回到占位。
@interface NEConversationNavigationCoordinator : NSObject

@property (nonatomic, strong, readonly) UINavigationController *navigationController;
/// 右列当前打开的会话身份；回到占位或 reset 后为 nil。
@property (nonatomic, strong, readonly, nullable) NEConversationOpenIntent *activeIntent;

@property (nonatomic, copy, readonly, nullable) NSString *openingKey;
/// 右列当前是否停留在占位页（没有打开任何页面）。
@property (nonatomic, assign, readonly, getter=isShowingPlaceholder) BOOL showingPlaceholder;
/// 当前占位页；切换分区时由宿主替换为分区专属占位。
@property (nonatomic, strong, readonly, nullable) UIViewController *currentPlaceholder;

@property (nonatomic, copy, nullable) UIViewController *_Nullable (^controllerFactory)(
    NEConversationOpenIntent *intent);
/// 在保留的聊天根上执行原定位/恢复语义；返回 NO 表示动作未完成。
@property (nonatomic, copy, nullable) BOOL (^presentationAction)(NEConversationOpenIntent *intent,
                                                                 UIViewController *root);

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 切换分区时展示该分区的占位页，并清空当前会话状态。
- (void)showPlaceholder:(UIViewController *)placeholder;

/// 回到初始占位并清空会话状态。
- (void)reset;

/// 用户手动返回/系统 pop 回占位后，同步清空 activeIntent；返回是否有状态被清理。
- (BOOL)syncActiveIntentWithNavigationStack;

- (BOOL)open:(NEConversationOpenIntent *)intent;

@end

NS_ASSUME_NONNULL_END
