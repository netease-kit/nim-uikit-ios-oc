// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageAudioCell : FunChatMessageBaseCell <ChatAudioCellProtocol>

@property (nonatomic, copy, nullable) NSString *messageId;
@property (nonatomic, assign) BOOL isPlaying;

// Left
@property (nonatomic, strong) UIImageView *audioImageViewLeft;
@property (nonatomic, strong) UILabel *timeLabelLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelLeftViewWidthAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelLeftViewHeightAnchor;
@property (nonatomic, strong) UIView *contentLabelLeftView;
@property (nonatomic, strong) UILabel *contentLabelLeft;

// Right
@property (nonatomic, strong) UIImageView *audioImageViewRight;
@property (nonatomic, strong) UILabel *timeLabelRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelRightViewWidthAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelRightViewHeightAnchor;
@property (nonatomic, strong) UIView *contentLabelRightView;
@property (nonatomic, strong) UILabel *contentLabelRight;

- (void)startAnimation:(BOOL)byRight;
- (void)stopAnimation:(BOOL)byRight;

@end

NS_ASSUME_NONNULL_END
