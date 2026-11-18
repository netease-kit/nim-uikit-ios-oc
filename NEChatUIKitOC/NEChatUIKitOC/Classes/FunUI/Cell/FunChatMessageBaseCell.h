// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageBaseCell : NEBaseChatMessageCell

@property (nonatomic, assign) CGFloat funMargin;
@property (nonatomic, assign) CGFloat replyHeight;

// Left reply views
@property (nonatomic, strong) UILabel *replyLabelLeft;
@property (nonatomic, strong) UIView *replyTextViewLeft;
@property (nonatomic, strong) UIView *replyViewLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *replyViewLeftHeightAnchor;
@property (nonatomic, assign) CGFloat replyViewLeftHeight;

// Right reply views
@property (nonatomic, strong) UILabel *replyLabelRight;
@property (nonatomic, strong) UIView *replyTextViewRight;
@property (nonatomic, strong) UIView *replyViewRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *replyViewRightHeightAnchor;

- (void)commonUI;
- (void)commonUILeft;
- (void)commonUIRight;
- (void)addReplyGesture;
- (void)tapReplyView:(UITapGestureRecognizer *)tap;

@end

NS_ASSUME_NONNULL_END
