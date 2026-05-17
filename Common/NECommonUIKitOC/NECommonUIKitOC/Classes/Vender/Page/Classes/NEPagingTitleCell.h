// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingCell.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingTitleCellViewModel;

@interface NEPagingTitleCell : NEPagingCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)configure;
- (void)configureTitleLabel;
- (void)configureAccessibility;

@end

NS_ASSUME_NONNULL_END
