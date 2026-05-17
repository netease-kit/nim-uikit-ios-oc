// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatMessageTextCell.h"
#import "MessageRichTextModel.h"
#import "NEChatTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageRichTextCell : ChatMessageTextCell

@property (nonatomic, strong) NEChatTextView *titleLabelLeft;
@property (nonatomic, strong) NEChatTextView *titleLabelRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelLeftHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelRightHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelLeftHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelRightHeightAnchor;

@end

NS_ASSUME_NONNULL_END
