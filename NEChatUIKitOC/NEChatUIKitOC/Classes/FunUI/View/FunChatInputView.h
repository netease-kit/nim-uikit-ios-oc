// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatInputView.h"

NS_ASSUME_NONNULL_BEGIN

static NSInteger const addMoreBtnTag = 8;
static NSInteger const addEmojBtnTag = 6;
static NSInteger const showPhotoTag = 2;

@protocol FunChatInputViewDelegate <NSObject>
- (void)recordModeChangeDidClick;
- (void)didHideRecordMode;
- (void)didHideReplyMode;
- (void)didShowReplyMode;
@end

@interface FunChatInputView : NEBaseChatInputView <UITextViewDelegate>

@property (nonatomic, weak, nullable) id<FunChatInputViewDelegate> funDelegate;

@property (nonatomic, strong, nullable) NSLayoutConstraint *replyViewTopConstraint;
@property (nonatomic, assign) CGFloat defaultReplyTopSpace;
@property (nonatomic, assign) CGFloat multipleReplyTopSpace;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backViewHeightConstaint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *textViewTop;

@property (nonatomic, strong) UIView *replyBackView;
@property (nonatomic, strong) UILabel *replyLabel;
@property (nonatomic, strong) UIButton *clearBtn;
@property (nonatomic, strong) UIButton *changeRecordModeBtn;
@property (nonatomic, strong) UIButton *showMoreActionBtn;
@property (nonatomic, strong) UIButton *showEmojBtn;
@property (nonatomic, strong) UIView *holdToSpeakView;

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType;
- (CGFloat)getTextviewRightConstraint;
- (void)changeToRecordMode:(UIButton *)button;
- (void)clearReplyMode;
- (void)showRecordMode;
- (void)hideRecordMode;
- (void)showReplyMode;
- (void)hideReplyMode;
- (BOOL)isRecordMode;
- (void)moreBtnClick;
- (void)emojBtnClick;
- (void)setRecordNormalStyle;
- (void)resotreMutipleModeFromRecordMode;

@end

NS_ASSUME_NONNULL_END
