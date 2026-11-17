// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunP2PChatViewController.h"
#import "TopicChatViewModel.h"

@class NEBaseUserSettingViewController;

NS_ASSUME_NONNULL_BEGIN

@interface FunBotSubSessionChatViewController : FunP2PChatViewController <TopicChatViewModelOutput>

@property(nonatomic, copy, readonly) NSString *botSessionName;
@property(nonatomic, copy) NSString *botConversationDisplayTitle;
@property(nonatomic, strong, readonly) UILabel *botSubSessionGuideLabel;
@property(nonatomic, strong) UIView *botSubSessionGuideView;
@property(nonatomic, strong, readonly, nullable) TopicChatViewModel *topicChatViewModel;

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName
                                  topic:(nullable V2NIMTopic *)topic NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (void)getSessionInfoWithSessionId:(NSString *)sessionId :(void (^)(void))completion;
- (void)loadBaseSessionInfo:(void (^)(void))completion;
- (NEBaseUserSettingViewController *)getUserSettingViewController;
- (void)showBotSubSessionActionSheet;
- (void)showRenameAlert;
- (void)showDeleteAlert;
- (void)sending:(V2NIMMessage *)message :(NSIndexPath *)index;
- (void)sendSuccess:(V2NIMMessage *)message :(NSIndexPath *)index;
- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages :(NSArray<NSIndexPath *> *)indexs;
- (UIView *)createBotSubSessionGuideView;
- (void)setupBotSubSessionGuideView;
- (void)refreshBotSubSessionGuideView;
- (NSString *)botSubSessionDisplayTitle;
- (void)updateBotSubSessionGuideText;
- (NSString *)botSubSessionGuideTitle;
- (void)applyBotSubSessionTitleWithFallback:(nullable NSString *)fallback;
- (NSString *)botSubSessionDisplayTitleWithFallback:(nullable NSString *)fallback;
- (NSString *)normalConversationDisplayTitle:(NSString *)sessionId;
- (NSString *)botConversationTitleFallback;
- (void)configureBotSubSessionNavigation;
- (void)applyFunBotSubSessionBackground;

- (instancetype)initWithConversationId:(NSString *)conversationId NS_UNAVAILABLE;
- (instancetype)initWithConversationId:(NSString *)conversationId
                                 anchor:(nullable V2NIMMessage *)anchor NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
