// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberSelectCell.h"
#import "NESelectTeamMember.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEChatKit/NEUserWithFriend.h>
#import <NIMSDK/V2NIMUserServiceProtocol.h>

@implementation NEBaseTeamMemberSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self.contentView addSubview:self.headerView];
  [self.contentView addSubview:self.nameLabel];
  [self.contentView addSubview:self.checkImageView];
}

- (void)configureMember:(NESelectTeamMember *)model {
  self.currentModel = model;
  self.checkImageView.highlighted = model.isSelected;

  NSString *url = model.member.nimUser.user.avatar;
  NSString *name = [model.member getShortName:[model.member showNickInTeam] ?: @"" length:2] ?: @"";
  NSString *accountId = model.member.nimUser.user.accountId ?: @"";
  [self.headerView configHeadData:url name:name uid:accountId];
  self.nameLabel.text = [model.member atNameInTeam];
}

- (UIImageView *)checkImageView {
  if (!_checkImageView) {
    _checkImageView = [[UIImageView alloc] init];
    _checkImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    _checkImageView.image = [coreLoader() loadImage:@"unselect"];
  }
  return _checkImageView;
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _headerView.titleLabel.textColor = UIColor.whiteColor;
    _headerView.clipsToBounds = YES;
    _headerView.accessibilityIdentifier = @"id.avatar";
  }
  return _headerView;
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

@end
