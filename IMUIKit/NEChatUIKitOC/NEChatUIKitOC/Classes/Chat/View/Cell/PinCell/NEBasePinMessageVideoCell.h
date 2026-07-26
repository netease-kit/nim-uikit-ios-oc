// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageImageCell.h"

#import <NECommonUIKitOC/VideoStateView.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBasePinMessageVideoCell : NEBasePinMessageImageCell

@property (nonatomic, strong) VideoStateView *stateView;
@property (nonatomic, strong) UILabel *videoTimeLabel;
@property (nonatomic, strong) UIView *timeView;

@end

NS_ASSUME_NONNULL_END
