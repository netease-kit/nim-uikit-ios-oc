// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseChatMessageCell.h"
#import "MessageContentModel.h"
#import "MessageTextModel.h"
#import "ChatCellConstantValue.h"
#import "NEEmotionTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface NormalChatMessageBaseCell : NEBaseChatMessageCell

@property (nonatomic, assign) CGFloat replyViewHeight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *replyViewLeftHeightAnchor;
@property (nonatomic, strong) UIView *replyViewLeft;
@property (nonatomic, strong) UILabel *replyLabelLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *replyViewRightHeightAnchor;
@property (nonatomic, strong) UIView *replyViewRight;
@property (nonatomic, strong) UILabel *replyLabelRight;

- (void)commonUI;
- (void)commonUILeft;
- (void)commonUIRight;

@end

NS_ASSUME_NONNULL_END
