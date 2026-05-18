// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseCollectionMessageLocationCell : NEBaseCollectionMessageCell

@property (nonatomic, strong) UILabel *locationTitleLabel;
@property (nonatomic, strong) UILabel *locationSubTitleLabel;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIImageView *mapImageView;
@property (nonatomic, strong, nullable) UIView *mapView;

@end

NS_ASSUME_NONNULL_END
