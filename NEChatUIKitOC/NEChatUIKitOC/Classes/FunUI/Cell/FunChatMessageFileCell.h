// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageBaseCell.h"
#import <NEBaseUIKitOC/FileStateView.h>

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageFileCell : FunChatMessageBaseCell

// Left
@property (nonatomic, strong) UIImageView *imgViewLeft;
@property (nonatomic, strong) FileStateView *stateViewLeft;
@property (nonatomic, strong) UILabel *titleLabelLeft;
@property (nonatomic, strong) UILabel *sizeLabelLeft;
@property (nonatomic, strong) UIView *labelViewLeft;

// Right
@property (nonatomic, strong) UIImageView *imgViewRight;
@property (nonatomic, strong) FileStateView *stateViewRight;
@property (nonatomic, strong) UILabel *titleLabelRight;
@property (nonatomic, strong) UILabel *sizeLabelRight;
@property (nonatomic, strong) UIView *labelViewRight;

@end

NS_ASSUME_NONNULL_END
