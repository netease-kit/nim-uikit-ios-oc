// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatViewController.h"
#import "FunChatInputView.h"
#import "FunRecordAudioView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FunChatInputViewDelegate;
@protocol FunChatRecordViewDelegate;

/// FunChatViewController Fun风格聊天视图控制器
@interface FunChatViewController : ChatViewController <FunChatInputViewDelegate, FunChatRecordViewDelegate>

@property (nonatomic, weak, nullable) FunRecordAudioView *recordView;

- (void)recordModeChangeDidClick;
- (void)didHideRecordMode;
- (void)didHideReplyMode;
- (void)didShowReplyMode;
- (void)holdToSpeak:(UILongPressGestureRecognizer *)gesture;
- (void)showRecordView;
- (void)removeRecordView;
- (void)didEndRecord:(FunRecordAudioView *)view;
- (nullable FunChatInputView *)getFunInputView;

@end

NS_ASSUME_NONNULL_END
