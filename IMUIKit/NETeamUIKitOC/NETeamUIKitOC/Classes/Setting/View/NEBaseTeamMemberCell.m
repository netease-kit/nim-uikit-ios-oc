// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberCell.h"
#import "TeamConstant.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/TeamMemberInfoModel.h>

@interface NEBaseTeamMemberCell ()
@property (nonatomic, strong, readwrite) NEUserHeaderView *headerView;
@property (nonatomic, strong, readwrite) UILabel *ownerLabel;
@property (nonatomic, strong, readwrite) UILabel *nameLabel;
@property (nonatomic, strong, readwrite) UILabel *removeLabel;
@property (nonatomic, strong, readwrite) UIButton *removeButton;
@end

@implementation NEBaseTeamMemberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.backgroundColor = UIColor.clearColor;
  self.contentView.backgroundColor = UIColor.clearColor;

  [self.contentView addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21.0],
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headerView.widthAnchor constraintEqualToConstant:42.0],
    [self.headerView.heightAnchor constraintEqualToConstant:42.0],
  ]];

  CGFloat rightMargin = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -170.0 : -116.0;
  self.nameLabelRightMargin = [self.nameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:rightMargin];
  [self.contentView addSubview:self.nameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:14.0],
    [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    self.nameLabelRightMargin,
  ]];

  self.ownerWidth = [self.ownerLabel.widthAnchor constraintEqualToConstant:48.0];
  [self.contentView addSubview:self.ownerLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.ownerLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:([NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? -90.0 : -70.0)],
    [self.ownerLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.ownerLabel.heightAnchor constraintEqualToConstant:22.0],
    self.ownerWidth,
  ]];
}

- (void)configure:(NETeamMemberInfoModel *)model {
  NEUserWithFriend *cachedUser = nil;
  NSString *userId = model.nimUser.user.accountId ?: @"";
  if (userId.length > 0) {
    cachedUser = [[NEFriendUserCache shared] getFriendInfo:userId];
  }
  if (cachedUser) {
    model.nimUser = cachedUser;
  }
  self.currentModel = model;

  NSString *url = model.nimUser.user.avatar;
  NSString *shortName = [model getShortName:[model showNickInTeam] ?: @"" length:2];
  NSString *accountId = model.nimUser.user.accountId ?: @"";
  [self.headerView configHeadData:url name:shortName uid:accountId];
  self.nameLabel.text = [model atNameInTeam];
}

- (void)setupRemoveButton {
  [self.contentView addSubview:self.removeButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.removeButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.removeButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.removeButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.removeButton.widthAnchor constraintEqualToConstant:100.0],
  ]];
  [self.removeButton addTarget:self action:@selector(didClickRemove) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didClickRemove {
  if ([self.delegate respondsToSelector:@selector(didClickRemoveButton:index:)]) {
    [self.delegate didClickRemoveButton:self.currentModel index:self.index];
  }
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _headerView.titleLabel.textColor = UIColor.whiteColor;
    _headerView.layer.cornerRadius = 21.0;
    _headerView.clipsToBounds = YES;
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _headerView;
}

- (UILabel *)ownerLabel {
  if (!_ownerLabel) {
    _ownerLabel = [[UILabel alloc] init];
    _ownerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _ownerLabel.font = [NEConstant defaultTextFont:12.0];
    _ownerLabel.textColor = [NEConstant hexRGB:0x337EFF];
    _ownerLabel.backgroundColor = [NEConstant hexRGB:0xE0ECFF];
    _ownerLabel.layer.borderColor = [NEConstant hexRGB:0xB9D3FF].CGColor;
    _ownerLabel.clipsToBounds = YES;
    _ownerLabel.layer.cornerRadius = 4.0;
    _ownerLabel.layer.borderWidth = 1.0;
    _ownerLabel.text = NETeamUIKitLocalizable(@"team_owner");
    _ownerLabel.textAlignment = NSTextAlignmentCenter;
    _ownerLabel.accessibilityIdentifier = @"id.identify";
  }
  return _ownerLabel;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [NEConstant defaultTextFont:16.0];
    _nameLabel.textColor = UIColor.ne_darkText;
    _nameLabel.accessibilityIdentifier = @"id.userName";
  }
  return _nameLabel;
}

- (UILabel *)removeLabel {
  if (!_removeLabel) {
    _removeLabel = [[UILabel alloc] init];
    _removeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _removeLabel.text = NETeamUIKitLocalizable(@"team_member_remove");
    _removeLabel.font = [UIFont systemFontOfSize:14.0];
    _removeLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _removeLabel;
}

- (UIButton *)removeButton {
  if (!_removeButton) {
    _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _removeButton.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _removeButton;
}

@end
