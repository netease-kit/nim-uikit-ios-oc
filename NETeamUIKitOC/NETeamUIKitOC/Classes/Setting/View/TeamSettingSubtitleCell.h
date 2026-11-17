// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface TeamSettingSubtitleCell : NEBaseTeamSettingCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *titleWidthAnchor;
@property (nonatomic, strong) UILabel *subTitleLabel;

- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
