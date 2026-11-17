// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageImageCell.h"
#import <NEBaseUIKitOC/VideoStateView.h>

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageVideoCell : FunChatMessageImageCell

// Left
@property (nonatomic, strong) VideoStateView *stateViewLeft;
@property (nonatomic, strong) UILabel *timeLabelLeft;
@property (nonatomic, strong) UIView *timeViewLeft;

// Right
@property (nonatomic, strong) VideoStateView *stateViewRight;
@property (nonatomic, strong) UILabel *timeLabelRight;
@property (nonatomic, strong) UIView *timeViewRight;

@end

NS_ASSUME_NONNULL_END
