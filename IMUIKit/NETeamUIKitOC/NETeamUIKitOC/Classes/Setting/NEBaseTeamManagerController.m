// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamManagerController.h"
#import "TeamConstant.h"
#import "SettingCellModel.h"
#import "SettingSectionModel.h"
#import "NEBaseTeamSettingCell.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface NEBaseTeamManagerController ()
@property (nonatomic, strong, readwrite) TeamManagerViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITableView *contentTableView;
@end

@implementation NEBaseTeamManagerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.title = NETeamUIKitLocalizable(@"manage_team");
  self.navigationView.moreButton.hidden = YES;
  self.viewModel.delegate = self;

  NSString *teamId = self.viewModel.teamInfoModel.team.teamId ?: @"";
  if (teamId.length > 0) {
    [self.viewModel getCurrentUserTeamMember:[IMKitClient instance].account
                                      teamId:teamId
                                  completion:^(__unused V2NIMTeamMember * _Nullable member, __unused NSError * _Nullable error) {
    }];
  }

  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.cellClassDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Class  _Nonnull obj, __unused BOOL * _Nonnull stop) {
    [self.contentTableView registerClass:obj forCellReuseIdentifier:key.stringValue];
  }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSString *teamId = self.viewModel.teamInfoModel.team.teamId ?: @"";
  if (teamId.length > 0) {
    __weak typeof(self) weakSelf = self;
    [self.viewModel getTeamWithMembers:teamId completion:^(__unused NSError * _Nullable error) {
      [weakSelf reloadSectionData];
      [weakSelf.contentTableView reloadData];
    }];
  }
}

- (void)reloadSectionData {
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if (self.viewModel.sectionData.count > section) {
    SettingSectionModel *model = self.viewModel.sectionData[section];
    return model.cellModels.count;
  }
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return self.viewModel.sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  NEBaseTeamSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                                                forIndexPath:indexPath];
  if ([cell isKindOfClass:[NEBaseTeamSettingCell class]]) {
    [cell configure:model];
    return cell;
  }
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  if (model.cellClick) {
    model.cellClick();
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  (void)tableView;
  if (self.viewModel.sectionData.count > section) {
    SettingSectionModel *model = self.viewModel.sectionData[section];
    if (model.cellModels.count > 0) {
      return 12.0;
    }
  }
  return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = UIColor.ne_lightBackgroundColor;
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  (void)tableView;
  if (section == self.viewModel.sectionData.count - 1) {
    return 12.0;
  }
  return 0;
}

- (void)updateEditTeamInfoPermissionToEveryone:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel updateTeamInfoPrivilege:self.viewModel.teamInfoModel.team.teamId ?: @""
                                     mode:V2NIM_TEAM_UPDATE_INFO_MODE_ALL
                               completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateTeamInfoPrivilege %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_all");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)updateEditTeamInfoPermissionToManager:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel updateTeamInfoPrivilege:self.viewModel.teamInfoModel.team.teamId ?: @""
                                     mode:V2NIM_TEAM_UPDATE_INFO_MODE_MANAGER
                               completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateTeamInfoPrivilege %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)updateInvitePermissionToManager:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel updateInviteMode:self.viewModel.teamInfoModel.team.teamId ?: @""
                              mode:V2NIM_TEAM_INVITE_MODE_MANAGER
                        completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateInviteMode %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)updateInvitePermissionToEveryone:(SettingCellModel *)model {
  if (self.viewModel.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_NORMAL) {
    [self showToast:commonLocalizable(@"failed_operation")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel updateInviteMode:self.viewModel.teamInfoModel.team.teamId ?: @""
                              mode:V2NIM_TEAM_INVITE_MODE_ALL
                        completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateInviteMode %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_all");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)didUpdateTeamInfoClick:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *allAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_all")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf updateEditTeamInfoPermissionToEveryone:model];
  }];
  [allAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *managerAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_owner_and_manager")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf updateEditTeamInfoPermissionToManager:model];
  }];
  [managerAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  [self showActionSheet:@[ allAction, managerAction, cancelAction ]];
}

- (void)didChangeInviteModeClick:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *allAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_all")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf updateInvitePermissionToEveryone:model];
  }];
  [allAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *managerAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_owner_and_manager")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf updateInvitePermissionToManager:model];
  }];
  [managerAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  [self showActionSheet:@[ allAction, managerAction, cancelAction ]];
}

- (void)didAtPermissionClick:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *allAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_all")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf.viewModel updateTeamAtAllPermission:NO completion:^(NSError * _Nullable error) {
      if (error) {
        if (error.code == protocolSendFailed) {
          [weakSelf showToast:commonLocalizable(@"network_error")];
        } else if (error.code == noPermissionCode) {
          [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
        } else {
          [weakSelf showToast:commonLocalizable(@"failed_operation")];
        }
        return;
      }
      model.subTitle = NETeamUIKitLocalizable(@"team_all");
      [weakSelf.contentTableView reloadData];
    }];
  }];
  [allAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *managerAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_owner_and_manager")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf.viewModel updateTeamAtAllPermission:YES completion:^(NSError * _Nullable error) {
      if (error) {
        if (error.code == protocolSendFailed) {
          [weakSelf showToast:commonLocalizable(@"network_error")];
        } else if (error.code == noPermissionCode) {
          [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
        } else {
          [weakSelf showToast:commonLocalizable(@"failed_operation")];
        }
        return;
      }
      model.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
      [weakSelf.contentTableView reloadData];
    }];
  }];
  [managerAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  [self showActionSheet:@[ allAction, managerAction, cancelAction ]];
}

- (void)didTopMessagePermissionClick:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *allAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_all")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf.viewModel updateTeamTopMessagePermission:NO completion:^(NSError * _Nullable error) {
      if (error) {
        if (error.code == protocolSendFailed) {
          [weakSelf showToast:commonLocalizable(@"network_error")];
        } else if (error.code == noPermissionCode) {
          [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
        } else {
          [weakSelf showToast:commonLocalizable(@"failed_operation")];
        }
        return;
      }
      model.subTitle = NETeamUIKitLocalizable(@"team_all");
      [weakSelf.contentTableView reloadData];
    }];
  }];
  [allAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  UIAlertAction *managerAction = [UIAlertAction actionWithTitle:NETeamUIKitLocalizable(@"team_owner_and_manager")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__unused UIAlertAction * _Nonnull action) {
    V2NIMTeamMemberRole role = weakSelf.viewModel.teamMember.memberRole;
    if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      return;
    }
    [weakSelf.viewModel updateTeamTopMessagePermission:YES completion:^(NSError * _Nullable error) {
      if (error) {
        if (error.code == protocolSendFailed) {
          [weakSelf showToast:commonLocalizable(@"network_error")];
        } else if (error.code == noPermissionCode) {
          [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
        } else {
          [weakSelf showToast:commonLocalizable(@"failed_operation")];
        }
        return;
      }
      model.subTitle = NETeamUIKitLocalizable(@"team_owner_and_manager");
      [weakSelf.contentTableView reloadData];
    }];
  }];
  [managerAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];

  [self showActionSheet:@[ allAction, managerAction, cancelAction ]];
}

- (void)didJoinTeamNeedAgreeClick:(SettingCellModel *)model isOpen:(BOOL)isOpen {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    model.switchOpen = !isOpen;
    [self.contentTableView reloadData];
    return;
  }

  V2NIMTeamMemberRole role = self.viewModel.teamMember.memberRole;
  if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    [self showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel updateTeamAgreeMode:isOpen completion:^(NSError * _Nullable error) {
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      model.switchOpen = !isOpen;
    } else {
      model.switchOpen = isOpen;
    }
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)didJoinTeamNeedVerificationClick:(SettingCellModel *)model isOpen:(BOOL)isOpen {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    model.switchOpen = !isOpen;
    [self.contentTableView reloadData];
    return;
  }

  V2NIMTeamMemberRole role = self.viewModel.teamMember.memberRole;
  if (role != V2NIM_TEAM_MEMBER_ROLE_OWNER && role != V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    [self showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel updateTeamJoinMode:isOpen completion:^(NSError * _Nullable error) {
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      model.switchOpen = !isOpen;
    } else {
      model.switchOpen = isOpen;
    }
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)didManagerClick {
}

- (void)didRefreshData {
  [self reloadSectionData];
  [self.contentTableView reloadData];
}

- (TeamManagerViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamManagerViewModel alloc] init];
  }
  return _viewModel;
}

- (UITableView *)contentTableView {
  if (!_contentTableView) {
    _contentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentTableView.backgroundColor = UIColor.clearColor;
    _contentTableView.dataSource = self;
    _contentTableView.delegate = self;
    _contentTableView.separatorColor = UIColor.clearColor;
    _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _contentTableView.sectionHeaderHeight = 12.0;
    _contentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 12.0)];
    _contentTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _contentTableView.estimatedRowHeight = 0.0;
    _contentTableView.estimatedSectionHeaderHeight = 0.0;
    _contentTableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _contentTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _contentTableView;
}

@end
