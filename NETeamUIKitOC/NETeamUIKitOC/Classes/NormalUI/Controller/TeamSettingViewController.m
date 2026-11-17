// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingViewController.h"
#import "TeamInfoViewController.h"
#import "TeamManagerController.h"
#import "TeamMembersController.h"
#import "TeamNameViewController.h"
#import "TeamArrowSettingCell.h"
#import "TeamSettingSwitchCell.h"
#import "TeamSettingSelectCell.h"
#import "TeamUserCell.h"
#import "TeamConstant.h"
#import "TeamDetailHeaderView.h"
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatUIKitOC/NEChatUIConstant.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@interface TeamSettingViewController ()
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *dividerLineView;
@end

@implementation TeamSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.className = @"TeamSettingViewController";
    self.cellClassDic[@(SettingCellTypeSettingArrowCell)] = TeamArrowSettingCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSwitchCell)] = TeamSettingSwitchCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSelectCell)] = TeamSettingSelectCell.class;
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
  [self.teamHeaderView setCornerRadius:21.0];
  [self.addButton setImage:[NETeamUIKitLoader() loadImage:@"setting_add"] forState:UIControlStateNormal];
  self.addButtonWidth = [self.addButton.widthAnchor constraintEqualToConstant:36.0];
  self.addButtonWidth.active = YES;
  self.addButtonLeftMargin = [self.addButton.leftAnchor constraintEqualToAnchor:self.cornerView.leftAnchor constant:16.0];
  self.addButtonLeftMargin.active = YES;
}

- (UIView *)getHeaderView {
  [self.backView addSubview:self.cornerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.cornerView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:20.0],
    [self.cornerView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-20.0],
    [self.cornerView.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
    [self.cornerView.heightAnchor constraintEqualToConstant:160.0],
  ]];

  UIView *teamHeaderBackView = [[UIView alloc] init];
  teamHeaderBackView.translatesAutoresizingMaskIntoConstraints = NO;
  teamHeaderBackView.backgroundColor = UIColor.clearColor;
  [self.cornerView addSubview:teamHeaderBackView];
  [NSLayoutConstraint activateConstraints:@[
    [teamHeaderBackView.leftAnchor constraintEqualToAnchor:self.cornerView.leftAnchor],
    [teamHeaderBackView.topAnchor constraintEqualToAnchor:self.cornerView.topAnchor],
    [teamHeaderBackView.heightAnchor constraintEqualToConstant:68.0],
    [teamHeaderBackView.rightAnchor constraintEqualToAnchor:self.cornerView.rightAnchor],
  ]];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toInfoView)];
  [teamHeaderBackView addGestureRecognizer:tap];

  [teamHeaderBackView addSubview:self.teamHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.teamHeaderView.leftAnchor constraintEqualToAnchor:teamHeaderBackView.leftAnchor constant:16.0],
    [self.teamHeaderView.topAnchor constraintEqualToAnchor:teamHeaderBackView.topAnchor constant:6.0],
    [self.teamHeaderView.rightAnchor constraintEqualToAnchor:teamHeaderBackView.rightAnchor constant:-34.0],
    [self.teamHeaderView.heightAnchor constraintEqualToConstant:62.0],
  ]];
  [self setTeamHeaderInfo];

  [teamHeaderBackView addSubview:self.arrowImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowImageView.centerYAnchor constraintEqualToAnchor:self.teamHeaderView.centerYAnchor],
    [self.arrowImageView.rightAnchor constraintEqualToAnchor:teamHeaderBackView.rightAnchor constant:-16.0],
  ]];

  [self.cornerView addSubview:self.dividerLineView];
  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLineView.heightAnchor constraintEqualToConstant:1.0],
    [self.dividerLineView.rightAnchor constraintEqualToAnchor:self.cornerView.rightAnchor],
    [self.dividerLineView.leftAnchor constraintEqualToAnchor:self.cornerView.leftAnchor constant:16.0],
    [self.dividerLineView.topAnchor constraintEqualToAnchor:self.teamHeaderView.bottomAnchor constant:6.0],
  ]];

  [self.cornerView addSubview:self.memberLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberLabel.leftAnchor constraintEqualToAnchor:self.dividerLineView.leftAnchor],
    [self.memberLabel.topAnchor constraintEqualToAnchor:self.dividerLineView.bottomAnchor constant:12.0],
  ]];
  self.memberLabel.text = self.teamSettingType == TeamSettingTypeSenior ? chatLocalizable(@"group_memmber") : NETeamUIKitLocalizable(@"discuss_mebmer");

  [self.cornerView addSubview:self.memberArrowImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberArrowImageView.rightAnchor constraintEqualToAnchor:self.arrowImageView.rightAnchor],
    [self.memberArrowImageView.centerYAnchor constraintEqualToAnchor:self.memberLabel.centerYAnchor],
  ]];

  [self.cornerView addSubview:self.memberListButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberListButton.leftAnchor constraintEqualToAnchor:self.memberLabel.leftAnchor],
    [self.memberListButton.rightAnchor constraintEqualToAnchor:self.memberArrowImageView.rightAnchor],
    [self.memberListButton.centerYAnchor constraintEqualToAnchor:self.memberLabel.centerYAnchor],
    [self.memberListButton.heightAnchor constraintEqualToConstant:40.0],
  ]];
  [self.memberListButton addTarget:self action:@selector(toMemberList) forControlEvents:UIControlEventTouchUpInside];

  [self.cornerView addSubview:self.memberCountLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberCountLabel.rightAnchor constraintEqualToAnchor:self.memberArrowImageView.leftAnchor constant:-2.0],
    [self.memberCountLabel.centerYAnchor constraintEqualToAnchor:self.memberArrowImageView.centerYAnchor],
  ]];
  self.memberCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewModel.teamInfoModel.team.memberCount];

  [self.cornerView addSubview:self.addButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.addButton.topAnchor constraintEqualToAnchor:self.memberLabel.bottomAnchor constant:12.0],
  ]];
  [self.addButton addTarget:self action:@selector(addUser) forControlEvents:UIControlEventTouchUpInside];

  V2NIMTeamMember *memberInTeam = self.viewModel.memberInTeam;
  if (![self.viewModel isNormalTeam] &&
      ![self.viewModel isOwner] &&
      self.viewModel.teamInfoModel.team.inviteMode == V2NIM_TEAM_INVITE_MODE_MANAGER &&
      memberInTeam &&
      memberInTeam.memberRole != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    self.addButtonWidth.constant = 0.0;
    self.addButton.hidden = YES;
  }

  [self setupUserInfoCollection:self.cornerView];
  return self.backView;
}

- (void)checkoutAddShowOrHide {
  if (![self.viewModel isNormalTeam] &&
      ![self.viewModel isOwner] &&
      self.viewModel.teamInfoModel.team.inviteMode == V2NIM_TEAM_INVITE_MODE_MANAGER) {
    if (self.viewModel.memberInTeam.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      self.addButton.hidden = NO;
      self.addButtonWidth.constant = 36.0;
      self.addButtonLeftMargin.constant = 16.0;
      [self checkMemberCountLimit];
    } else {
      self.addButton.hidden = YES;
      self.addButtonWidth.constant = 0.0;
      self.addButtonLeftMargin.constant = 0.0;
    }
    return;
  }
  [self checkMemberCountLimit];
}

- (UIView *)getFooterView {
  NSString *title = [self getBottomText];
  if (title.length == 0) {
    return nil;
  }
  UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64.0)];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [footerView addSubview:button];
  button.backgroundColor = UIColor.whiteColor;
  button.clipsToBounds = YES;
  button.layer.cornerRadius = 8.0;
  [button setTitleColor:[NEConstant hexRGB:0xE6605C] forState:UIControlStateNormal];
  button.titleLabel.font = [NEConstant defaultTextFont:16.0];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:@selector(removeTeamForMyself) forControlEvents:UIControlEventTouchUpInside];
  [NSLayoutConstraint activateConstraints:@[
    [button.leftAnchor constraintEqualToAnchor:footerView.leftAnchor constant:20.0],
    [button.rightAnchor constraintEqualToAnchor:footerView.rightAnchor constant:-20.0],
    [button.topAnchor constraintEqualToAnchor:footerView.topAnchor constant:12.0],
    [button.heightAnchor constraintEqualToConstant:40.0],
  ]];
  return footerView;
}

- (void)setupUserInfoCollection:(UIView *)cornerView {
  [cornerView addSubview:self.userinfoCollectionView];
  [NSLayoutConstraint activateConstraints:@[
    [self.userinfoCollectionView.leftAnchor constraintEqualToAnchor:self.addButton.rightAnchor constant:15.0],
    [self.userinfoCollectionView.centerYAnchor constraintEqualToAnchor:self.addButton.centerYAnchor],
    [self.userinfoCollectionView.rightAnchor constraintEqualToAnchor:cornerView.rightAnchor constant:-15.0],
    [self.userinfoCollectionView.heightAnchor constraintEqualToConstant:32.0],
  ]];
  [self.userinfoCollectionView registerClass:TeamUserCell.class forCellWithReuseIdentifier:NSStringFromClass(TeamUserCell.class)];
}

- (void)toInfoView {
  TeamInfoViewController *info = [[TeamInfoViewController alloc] initWithTeam:self.viewModel.teamInfoModel.team];
  [self.navigationController pushViewController:info animated:YES];
}

- (void)didClickChangeNick {
  TeamNameViewController *nick = [[TeamNameViewController alloc] init];
  nick.type = ChangeTypeNickName;
  nick.team = self.viewModel.teamInfoModel.team;
  nick.teamMember = self.viewModel.memberInTeam;
  [self.navigationController pushViewController:nick animated:YES];
}

- (void)didClickTeamManage {
  TeamManagerController *manageTeam = [[TeamManagerController alloc] init];
  manageTeam.viewModel.teamInfoModel = self.viewModel.teamInfoModel;
  [self.navigationController pushViewController:manageTeam animated:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TeamUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(TeamUserCell.class)
                                                                 forIndexPath:indexPath];
  if (self.viewModel.teamInfoModel.users.count > indexPath.row) {
    NETeamMemberInfoModel *user = self.viewModel.teamInfoModel.users[indexPath.row];
    NSString *userId = user.nimUser.user.accountId;
    if (userId.length > 0) {
      NEUserWithFriend *nimUser = [[NEFriendUserCache shared] getFriendInfo:userId];
      if (nimUser) {
        user.nimUser = nimUser;
      }
    }
    cell.user = user;
  }
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)collectionViewLayout;
  (void)indexPath;
  return CGSizeMake(47.0, 32.0);
}

- (void)toMemberList {
  TeamMembersController *memberController = [[TeamMembersController alloc] initWithTeamId:self.viewModel.teamInfoModel.team.teamId];
  [self.navigationController pushViewController:memberController animated:YES];
}

- (void)checkMemberCountLimit {
  if (self.viewModel.teamInfoModel.team.memberLimit == self.viewModel.teamInfoModel.team.memberCount) {
    self.addButton.hidden = YES;
    self.addButtonWidth.constant = 0.0;
    self.addButtonLeftMargin.constant = 0.0;
  } else {
    self.addButton.hidden = NO;
    self.addButtonWidth.constant = 36.0;
    self.addButtonLeftMargin.constant = 16.0;
  }
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 172.0)];
  }
  return _backView;
}

- (UIView *)cornerView {
  if (!_cornerView) {
    _cornerView = [[UIView alloc] init];
    _cornerView.translatesAutoresizingMaskIntoConstraints = NO;
    _cornerView.backgroundColor = UIColor.whiteColor;
    _cornerView.clipsToBounds = YES;
    _cornerView.layer.cornerRadius = 8.0;
  }
  return _cornerView;
}

- (UIImageView *)arrowImageView {
  if (!_arrowImageView) {
    _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _arrowImageView;
}

- (UIView *)dividerLineView {
  if (!_dividerLineView) {
    _dividerLineView = [[UIView alloc] init];
    _dividerLineView.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLineView.backgroundColor = [NEConstant hexRGB:0xF5F8FC];
  }
  return _dividerLineView;
}

- (UIImageView *)memberArrowImageView {
  if (!_memberArrowImageView) {
    _memberArrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _memberArrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _memberArrowImageView;
}

- (UIButton *)memberListButton {
  if (!_memberListButton) {
    _memberListButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _memberListButton.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _memberListButton;
}

@end
