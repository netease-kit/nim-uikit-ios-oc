// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatViewController.h"
#import "TeamChatViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunTeamChatViewController : FunChatViewController <TeamChatViewModelDelegate>

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor;
- (instancetype)initWithSessionId:(NSString *)sessionId;
- (NSMutableAttributedString *)getPlaceHolder:(NSString *)text;
- (void)updateTeamInfo:(V2NIMTeam *)team;
- (void)setMuteWithTeam:(V2NIMTeam *)team;
- (void)popGroupChatVC;
- (void)updateTeamTitle:(NSNotification *)noti;

@end

NS_ASSUME_NONNULL_END
