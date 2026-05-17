// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamSettingSwitchCell : NEBaseTeamSettingCell

@property (nonatomic, strong) UISwitch *tSwitch;

- (void)setupUI;
- (void)switchChange:(UISwitch *)sender;

@end

NS_ASSUME_NONNULL_END
