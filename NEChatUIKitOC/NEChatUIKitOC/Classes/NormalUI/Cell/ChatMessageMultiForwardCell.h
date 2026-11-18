// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageMultiForwardCell : NormalChatMessageBaseCell

@property (nonatomic, strong) UIImageView *backViewLeft;
@property (nonatomic, strong) UILabel *titleLabelLeft1;
@property (nonatomic, strong) UILabel *titleLabelLeft2;
@property (nonatomic, strong) UILabel *contentLabelLeft1;
@property (nonatomic, strong) UILabel *contentLabelLeft2;
@property (nonatomic, strong) UILabel *contentLabelLeft3;
@property (nonatomic, strong) UIView *dividerLineLeft;
@property (nonatomic, strong) UILabel *contentHistoryLeft;
@property (nonatomic, strong) UIImageView *backViewRight;
@property (nonatomic, strong) UILabel *titleLabelRight1;
@property (nonatomic, strong) UILabel *titleLabelRight2;
@property (nonatomic, strong) UILabel *contentLabelRight1;
@property (nonatomic, strong) UILabel *contentLabelRight2;
@property (nonatomic, strong) UILabel *contentLabelRight3;
@property (nonatomic, strong) UIView *dividerLineRight;
@property (nonatomic, strong) UILabel *contentHistoryRight;

@end

NS_ASSUME_NONNULL_END
