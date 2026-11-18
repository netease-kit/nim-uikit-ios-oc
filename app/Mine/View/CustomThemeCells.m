// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomThemeCells.h"
#import "NEStyleManager.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation CustomTeamSettingSubtitleCell

- (void)setupUI {
  if ([NEStyleManager.instance isNormalStyle]) {
    [super setupUI];
    return;
  }

  UIView *whiteBgView = [[UIView alloc] init];
  whiteBgView.backgroundColor = UIColor.whiteColor;
  whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subTitleLabel];
  [self.contentView addSubview:self.arrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
  self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
  self.titleWidthAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.arrowView.widthAnchor constraintEqualToConstant:7.0],
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor constant:10.0],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-10.0],
    [self.subTitleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
  self.dividerLineLeftMargin.constant = 20.0;
  self.dividerLineRightMargin.constant = 0.0;
}

@end

@implementation CustomTeamSettingHeaderCell

- (void)setupUI {
  if ([NEStyleManager.instance isNormalStyle]) {
    [super setupUI];
    return;
  }

  UIView *whiteBgView = [[UIView alloc] init];
  whiteBgView.backgroundColor = UIColor.whiteColor;
  whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-68.0],
  ]];

  [self.contentView addSubview:self.arrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
  ]];

  [self.contentView addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.arrowView.centerYAnchor],
    [self.headerView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-48.0],
    [self.headerView.widthAnchor constraintEqualToConstant:42.0],
    [self.headerView.heightAnchor constraintEqualToConstant:42.0],
  ]];
  self.headerView.layer.cornerRadius = 4.0;
  self.dividerLineLeftMargin.constant = 20.0;
  self.dividerLineRightMargin.constant = 0.0;
}

@end

@implementation CustomTeamSettingRightCustomCell

- (void)setupUI {
  if ([NEStyleManager.instance isNormalStyle]) {
    [super setupUI];
    return;
  }

  UIView *whiteBgView = [[UIView alloc] init];
  whiteBgView.backgroundColor = UIColor.whiteColor;
  whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subTitleLabel];
  [self.contentView addSubview:self.arrowView];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
  self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
  self.titleWidthAnchor.active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.arrowView.widthAnchor constraintEqualToConstant:7.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.subTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor constant:10.0],
    [self.subTitleLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-10.0],
    [self.subTitleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];

  [self.contentView addSubview:self.customRightView];
  [NSLayoutConstraint activateConstraints:@[
    [self.customRightView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.customRightView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.customRightView.widthAnchor constraintEqualToConstant:15.0],
    [self.customRightView.heightAnchor constraintEqualToConstant:15.0],
  ]];
  [self.customRightView addTarget:self action:@selector(customRightViewClick) forControlEvents:UIControlEventTouchUpInside];

  self.dividerLineLeftMargin.constant = 20.0;
  self.dividerLineRightMargin.constant = 0.0;
}

@end

@implementation CustomTeamSettingSwitchCell

- (void)setupUI {
  self.titleLabel.numberOfLines = 0;
  if ([NEStyleManager.instance isNormalStyle]) {
    [super setupUI];
    return;
  }

  UIView *whiteBgView = [[UIView alloc] init];
  whiteBgView.backgroundColor = UIColor.whiteColor;
  whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-68.0],
  ]];

  [self.contentView addSubview:self.tSwitch];
  [NSLayoutConstraint activateConstraints:@[
    [self.tSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.tSwitch.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
  ]];

  [self.tSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventTouchUpInside];
  self.dividerLineLeftMargin.constant = 20.0;
  self.dividerLineRightMargin.constant = 0.0;
  self.tSwitch.onTintColor = [UIColor ne_funTheme];
}

@end

@implementation CustomTeamArrowSettingCell

- (void)setupUI {
  if ([NEStyleManager.instance isNormalStyle]) {
    [super setupUI];
    return;
  }

  UIView *whiteBgView = [[UIView alloc] init];
  whiteBgView.backgroundColor = UIColor.whiteColor;
  whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-68.0],
  ]];

  [self.contentView addSubview:self.arrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
  ]];

  self.dividerLineLeftMargin.constant = 20.0;
  self.dividerLineRightMargin.constant = 0.0;
}

@end
