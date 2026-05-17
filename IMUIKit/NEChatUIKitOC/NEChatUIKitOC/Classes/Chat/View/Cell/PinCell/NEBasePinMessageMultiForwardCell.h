// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBasePinMessageMultiForwardCell : NEBasePinMessageCell

@property (nonatomic, assign) CGFloat funMargin;
@property (nonatomic, assign) CGFloat titleLabelFontSize;
@property (nonatomic, assign) CGFloat contentLabelFontSize;
@property (nonatomic, strong) UIColor *contentLabelColor;

@property (nonatomic, strong) UIImageView *backViewLeft;
@property (nonatomic, strong) UILabel *titleLabelLeft1;
@property (nonatomic, strong) UILabel *titleLabelLeft2;
@property (nonatomic, strong) UILabel *contentLabelLeft1;
@property (nonatomic, strong) UILabel *contentLabelLeft2;
@property (nonatomic, strong) UILabel *contentLabelLeft3;

@end

NS_ASSUME_NONNULL_END
