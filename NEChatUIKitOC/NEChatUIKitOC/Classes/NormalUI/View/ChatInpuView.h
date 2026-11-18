// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatRecordView.h"
#import "NEBaseChatInputView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatInputView : NEBaseChatInputView <UITextViewDelegate, ChatRecordViewDelegate>

@property (nonatomic, strong, nullable) NSLayoutConstraint *backViewHeightConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *toolsBarTopMargin;

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType;
- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType
                         showAIChatButton:(BOOL)showAIChatButton;
- (instancetype)init:(V2NIMConversationType)conversationType
     showAIChatButton:(BOOL)showAIChatButton;
- (CGFloat)getTextviewRightConstraint;

@end

NS_ASSUME_NONNULL_END
