// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageTextCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageRichTextCell : FunChatMessageTextCell

@property (nonatomic, strong) NEChatTextView *titleLabelLeft;
@property (nonatomic, strong) NEChatTextView *titleLabelRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelLeftHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelRightHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelLeftBottomAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelRightBottomAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelLeftHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelRightHeightAnchor;

@end

NS_ASSUME_NONNULL_END
