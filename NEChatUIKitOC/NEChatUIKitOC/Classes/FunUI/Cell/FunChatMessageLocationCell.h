// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageLocationCell : FunChatMessageBaseCell

// Left
@property (nonatomic, strong) UILabel *titleLabelLeft;
@property (nonatomic, strong) UILabel *subTitleLabelLeft;
@property (nonatomic, strong) UILabel *emptyLabelLeft;
@property (nonatomic, strong) UIImageView *mapImageViewLeft;
@property (nonatomic, strong) UIView *backgroundViewLeft;
@property (nonatomic, strong) UIImageView *pointImageLeft;

// Right
@property (nonatomic, strong) UILabel *titleLabelRight;
@property (nonatomic, strong) UILabel *subTitleLabelRight;
@property (nonatomic, strong) UILabel *emptyLabelRight;
@property (nonatomic, strong) UIImageView *mapImageViewRight;
@property (nonatomic, strong) UIView *backgroundViewRight;
@property (nonatomic, strong) UIImageView *pointImageRight;

@end

NS_ASSUME_NONNULL_END
