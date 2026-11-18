// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TeamSettingViewController : NEBaseTeamSettingViewController

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *cornerView;
@property (nonatomic, strong) UIImageView *memberArrowImageView;
@property (nonatomic, strong) UIButton *memberListButton;

@end

NS_ASSUME_NONNULL_END
