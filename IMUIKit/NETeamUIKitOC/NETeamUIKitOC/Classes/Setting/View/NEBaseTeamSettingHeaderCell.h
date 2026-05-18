// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingCell.h"

@class NEUserHeaderView;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamSettingHeaderCell : NEBaseTeamSettingCell

@property (nonatomic, strong) NEUserHeaderView *headerView;

- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
