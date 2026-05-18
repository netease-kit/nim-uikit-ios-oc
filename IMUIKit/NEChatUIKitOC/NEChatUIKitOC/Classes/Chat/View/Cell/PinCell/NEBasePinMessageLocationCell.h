// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBasePinMessageLocationCell : NEBasePinMessageCell

@property (nonatomic, strong) UIImageView *mapImageView;
@property (nonatomic, strong, nullable) UIView *mapView;

@end

NS_ASSUME_NONNULL_END
