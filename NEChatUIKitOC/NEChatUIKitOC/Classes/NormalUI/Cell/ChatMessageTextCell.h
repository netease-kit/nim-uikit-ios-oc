// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"
#import "NEChatTextView.h"
#import "MessageTextModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageTextCell : NormalChatMessageBaseCell <UITextViewDelegate>

@property (nonatomic, assign) BOOL isLongPress;
@property (nonatomic, strong) NEChatTextView *contentLabelLeft;
@property (nonatomic, strong) NEChatTextView *contentLabelRight;

- (void)tapFunc;
- (void)selectText;
- (CGSize)getTextSize:(nullable NSAttributedString *)attributedText;

@end

NS_ASSUME_NONNULL_END
