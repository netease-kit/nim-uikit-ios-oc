// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamSettingViewController.h"
#import "FunTeamInfoViewController.h"
#import "FunTeamManagerController.h"
#import "FunTeamMembersController.h"
#import "FunTeamNameViewController.h"
#import "TeamConstant.h"
#import "SettingSectionModel.h"
#import "FunTeamArrowSettingCell.h"
#import "FunTeamSettingSelectCell.h"
#import "FunTeamSettingSwitchCell.h"
#import "FunTeamUserCell.h"
#import "FunTeamUIColor.h"
#import "TeamDetailHeaderView.h"
#import <NEChatUIKitOC/NEChatUIConstant.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@interface FunTeamSettingViewController ()
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *cornerView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *dividerLineView;
@property (nonatomic, strong) UIImageView *memberArrowImageView;
@property (nonatomic, strong) UIButton *memberListButton;
@end

@implementation FunTeamSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.className = @"FunTeamSettingViewController";
    self.cellClassDic[@(SettingCellTypeSettingArrowCell)] = FunTeamArrowSettingCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSwitchCell)] = FunTeamSettingSwitchCell.class;
    self.cellClassDic[@(SettingCellTypeSettingSelectCell)] = FunTeamSettingSelectCell.class;
  }
  return self;
}

- (void)reloadSectionData {
  for (SettingSectionModel *sectionModel in self.viewModel.sectionData) {
    for (SettingCellModel *cellModel in sectionModel.cellModels) {
      cellModel.cornerType = CornerTypeNone;
      if (cellModel.type == SettingCellTypeSettingSelectCell) {
        cellModel.rowHeight = 78.0;
      } else if (cellModel.type == SettingCellTypeSettingArrowCell || cellModel.type == SettingCellTypeSettingSwitchCell) {
        cellModel.rowHeight = 56.0;
      }
    }
  }
}

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;
  [self.teamHeaderView setCornerRadius:4.0];
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.titleBarBottomLine.hidden = NO;

  [self.addButton setImage:[NETeamUIKitLoader() loadImage:@"fun_setting_add"] forState:UIControlStateNormal];
  self.addButtonWidth = [self.addButton.widthAnchor constraintEqualToConstant:36.0];
  self.addButtonWidth.active = YES;
  self.addButtonLeftMargin = [self.addButton.leftAnchor constraintEqualToAnchor:self.cornerView.leftAnchor constant:16.0];
  self.addButtonLeftMargin.active = YES;
}

- (UIView *)getHeaderView {
  [self.backView addSubview:self.cornerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.cornerView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor],
    [self.cornerView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor],
    [self.cornerView.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
    [self.cornerView.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
  ]];

  UIView *teamHeaderBackView = [[UIView alloc] init];
  teamHeaderBackView.translatesAutoresizingMaskIntoConstraints = NO;
  teamHeaderBackView.backgroundColor = UIColor.clearColor;
  [self.cornerView addSubview:teamHeaderBackView];
  [NSLayoutConstraint activateConstraints:@[
    [teamHeaderBackView.leftAnchor constraintEqualToAnchor:self.cornerView.leftAnchor],
    [teamHeaderBackView.topAnchor constraintEqualToAnchor:self.cornerView.topAnchor],
    [teamHeaderBackView.heightAnchor constraintEqualToConstant:76.0],
    [teamHeaderBackView.rightAnchor constraintEqualToAnchor:self.cornerView.rightAnchor],
  ]];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toInfoView)];
  [teamHeaderBackView addGestureRecognizer:tap];

  [teamHeaderBackView addSubview:self.teamHeaderView];
  [self.teamHeaderView resetAvatarWH:50.0];
  [NSLayoutConstraint activateConstraints:@[
    [self.teamHeaderView.leftAnchor constraintEqualToAnchor:teamHeaderBackView.leftAnchor constant:16.0],
    [self.teamHeaderView.topAnchor constraintEqualToAnchor:teamHeaderBackView.topAnchor constant:6.0],
    [self.teamHeaderView.rightAnchor constraintEqualToAnchor:teamHeaderBackView.rightAnchor constant:-50.0],
    [self.teamHeaderView.heightAnchor constraintEqualToConstant:70.0],
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
    [self.dividerLineView.leftAnchor constraintEqualToAnchor:self.teamHeaderView.leftAnchor],
    [self.dividerLineView.topAnchor constraintEqualToAnchor:self.teamHeaderView.bottomAnchor constant:6.0],
  ]];

  [self.cornerView addSubview:self.memberLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberLabel.leftAnchor constraintEqualToAnchor:self.dividerLineView.leftAnchor],
    [self.memberLabel.topAnchor constraintEqualToAnchor:self.dividerLineView.bottomAnchor constant:16.0],
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
    [self.memberListButton.heightAnchor constraintEqualToConstant:50.0],
  ]];
  [self.memberListButton addTarget:self action:@selector(toMemberList) forControlEvents:UIControlEventTouchUpInside];

  [self.cornerView addSubview:self.memberCountLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.memberCountLabel.rightAnchor constraintEqualToAnchor:self.memberArrowImageView.leftAnchor constant:-8.0],
    [self.memberCountLabel.centerYAnchor constraintEqualToAnchor:self.memberArrowImageView.centerYAnchor],
  ]];
  self.memberCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.viewModel.teamInfoModel.team.memberCount];

  [self.cornerView addSubview:self.addButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.addButton.topAnchor constraintEqualToAnchor:self.memberListButton.bottomAnchor],
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
  [button setTitleColor:[NEConstant hexRGB:0xE6605C] forState:UIControlStateNormal];
  button.titleLabel.font = [NEConstant defaultTextFont:16.0];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:@selector(removeTeamForMyself) forControlEvents:UIControlEventTouchUpInside];
  [NSLayoutConstraint activateConstraints:@[
    [button.leftAnchor constraintEqualToAnchor:footerView.leftAnchor],
    [button.rightAnchor constraintEqualToAnchor:footerView.rightAnchor],
    [button.topAnchor constraintEqualToAnchor:footerView.topAnchor constant:12.0],
    [button.heightAnchor constraintEqualToConstant:56.0],
  ]];
  return footerView;
}

- (void)setupUserInfoCollection:(UIView *)cornerView {
  [cornerView addSubview:self.userinfoCollectionView];
  [NSLayoutConstraint activateConstraints:@[
    [self.userinfoCollectionView.leftAnchor constraintEqualToAnchor:self.addButton.rightAnchor constant:16.0],
    [self.userinfoCollectionView.centerYAnchor constraintEqualToAnchor:self.addButton.centerYAnchor],
    [self.userinfoCollectionView.rightAnchor constraintEqualToAnchor:cornerView.rightAnchor constant:-16.0],
    [self.userinfoCollectionView.heightAnchor constraintEqualToConstant:36.0],
  ]];
  [self.userinfoCollectionView registerClass:FunTeamUserCell.class forCellWithReuseIdentifier:NSStringFromClass(FunTeamUserCell.class)];
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

- (void)toInfoView {
  FunTeamInfoViewController *info = [[FunTeamInfoViewController alloc] initWithTeam:self.viewModel.teamInfoModel.team];
  [self.navigationController pushViewController:info animated:YES];
}

- (void)didClickChangeNick {
  FunTeamNameViewController *nick = [[FunTeamNameViewController alloc] init];
  nick.type = ChangeTypeNickName;
  nick.team = self.viewModel.teamInfoModel.team;
  nick.teamMember = self.viewModel.memberInTeam;
  [self.navigationController pushViewController:nick animated:YES];
}

- (void)didClickTeamManage {
  FunTeamManagerController *manageTeam = [[FunTeamManagerController alloc] init];
  manageTeam.viewModel.teamInfoModel = self.viewModel.teamInfoModel;
  [self.navigationController pushViewController:manageTeam animated:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  FunTeamUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(FunTeamUserCell.class)
                                                                    forIndexPath:indexPath];
  if (self.viewModel.teamInfoModel.users.count > indexPath.row) {
    cell.user = self.viewModel.teamInfoModel.users[indexPath.row];
  }
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)collectionViewLayout;
  return indexPath.row == 0 ? CGSizeMake(36.0, 36.0) : CGSizeMake(52.0, 36.0);
}

- (void)toMemberList {
  FunTeamMembersController *memberController = [[FunTeamMembersController alloc] initWithTeamId:self.viewModel.teamInfoModel.team.teamId];
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
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NEConstant.screenWidth, 188.0)];
  }
  return _backView;
}

- (UIView *)cornerView {
  if (!_cornerView) {
    _cornerView = [[UIView alloc] init];
    _cornerView.translatesAutoresizingMaskIntoConstraints = NO;
    _cornerView.backgroundColor = UIColor.whiteColor;
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
