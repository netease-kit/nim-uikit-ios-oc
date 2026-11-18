// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamMemberCell.h"
#import "FunTeamUIColor.h"
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation FunTeamMemberCell

- (void)setupUI {
  [self.contentView addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21.0],
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headerView.widthAnchor constraintEqualToConstant:40.0],
    [self.headerView.heightAnchor constraintEqualToConstant:40.0],
  ]];
  self.headerView.layer.cornerRadius = 4.0;

  [self.contentView addSubview:self.ownerLabel];
  self.ownerWidth = [self.ownerLabel.widthAnchor constraintEqualToConstant:48.0];
  self.ownerRightVisibleConstant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -76.0 : -56.0;
  self.ownerRightHiddenConstant = -16.0;
  self.ownerRightMargin = [self.ownerLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:self.ownerRightVisibleConstant];
  [NSLayoutConstraint activateConstraints:@[
    self.ownerRightMargin,
    [self.ownerLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.ownerLabel.heightAnchor constraintEqualToConstant:25.0],
    self.ownerWidth,
  ]];

  [self.contentView addSubview:self.nameStackView];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameStackView.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:14.0],
    [self.nameStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.nameStackView.rightAnchor constraintEqualToAnchor:self.ownerLabel.leftAnchor constant:-14.0],
  ]];
  [self setOwnerStyle];

  [self.contentView addSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:1.0],
  ]];

  [self.contentView addSubview:self.removeLabel];
  self.removeLabel.textColor = UIColor.funTeamRemoveLabelColor;
  [NSLayoutConstraint activateConstraints:@[
    [self.removeLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.removeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
  ]];

  [self setupRemoveButton];
}

- (void)setOwnerStyle {
  self.ownerLabel.textColor = UIColor.funTeamThemeColor;
  self.ownerLabel.backgroundColor = [UIColor.funTeamThemeColor colorWithAlphaComponent:0.1];
  self.ownerLabel.layer.borderColor = UIColor.funTeamThemeColor.CGColor;
  self.ownerWidth.constant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 80.0 : 48.0;
}

- (void)setManagerStyle {
  self.ownerLabel.textColor = UIColor.funTeamMangerLabelTextColor;
  self.ownerLabel.backgroundColor = [UIColor.funTeamManagerLabelBorderColor colorWithAlphaComponent:0.1];
  self.ownerLabel.layer.borderColor = UIColor.funTeamManagerLabelBorderColor.CGColor;
  self.ownerWidth.constant = 60.0;
}

- (UIView *)dividerLine {
  if (!_dividerLine) {
    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = UIColor.funTeamMemberDividerLine;
  }
  return _dividerLine;
}

@end
