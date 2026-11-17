// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatMessageImageCell.h"
#import <NEBaseUIKitOC/VideoStateView.h>
#import "MessageVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageVideoCell : ChatMessageImageCell

@property (nonatomic, weak, nullable) MessageVideoModel *weakModel;
@property (nonatomic, strong) VideoStateView *stateViewLeft;
@property (nonatomic, strong) UILabel *timeLabelLeft;
@property (nonatomic, strong) UIView *timeViewLeft;
@property (nonatomic, strong) VideoStateView *stateViewRight;
@property (nonatomic, strong) UILabel *timeLabelRight;
@property (nonatomic, strong) UIView *timeViewRight;

@end

NS_ASSUME_NONNULL_END
