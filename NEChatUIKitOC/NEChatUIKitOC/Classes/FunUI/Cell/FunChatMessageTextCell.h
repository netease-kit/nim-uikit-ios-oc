// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageBaseCell.h"
#import "NEChatTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageTextCell : FunChatMessageBaseCell <UITextViewDelegate>

@property (nonatomic, strong) NEChatTextView *contentLabelLeft;
@property (nonatomic, strong) NEChatTextView *contentLabelRight;
@property (nonatomic, assign) BOOL isLongPress;

- (void)tapFunc;
- (void)selectText;

@end

NS_ASSUME_NONNULL_END
