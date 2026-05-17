// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamJoinActionViewController.h"
#import <NEChatKitOC/NECoreIM2Constant.h>
#import "NEBaseAddApplicationViewController.h"
#import "ContactConst.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/NECommonKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>

@interface NEBaseTeamJoinActionViewController ()
@property (nonatomic, strong, readwrite) TeamJoinActionViewModel *viewModel;
@end

@implementation NEBaseTeamJoinActionViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = commonLocalizable(@"team_group");
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.title = commonLocalizable(@"team_group");
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.navigationView removeFromSuperview];
  self.topConstant = 0;

  [self changeLanguage];
  [self setupUI];
  self.viewModel.delegate = self;
  [self loadData];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.viewModel setTeamJoinActionRead];
  [self tableviewReload];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// 返回上一级页面
- (void)backEvent {
  [super backEvent];
  [self.viewModel setTeamJoinActionRead];
}

/// 进入后台，清空未读
- (void)appEnterBackground {
  [super appEnterBackground];
  [self.viewModel setTeamJoinActionRead];
  [self tableviewReload];
}

/// 加载数据
- (void)loadData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadTeamJoinActionList:YES completion:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"ContactKit log: loadTeamJoinActionList error: %@", error);
    } else {
      weakSelf.emptyView.hidden = (weakSelf.viewModel.teamJoinActions.count > 0);
    }
  }];
}

/// 控件初始化
- (void)setupUI {
  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  self.emptyView.message = contactLocalizable(@"no_team_join_action");
  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:100],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = commonLocalizable(@"team_group");
  self.emptyView.message = contactLocalizable(@"no_team_join_action");
}

/// 清空入群申请
- (void)toSetting {
  if (!self.view.isVisibleInWindow) {
    return;
  }

  NSLog(@"ContactKit log: %@", NSStringFromSelector(_cmd));
  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:contactLocalizable(@"clear_all_team_join_action")
             sure:^(__unused UIAlertAction *action) {
    [weakSelf.viewModel clearNotification:^(NSError * _Nullable error) {
      weakSelf.emptyView.hidden = (weakSelf.viewModel.teamJoinActions.count > 0);
      [weakSelf.tableView reloadData];
    }];
  }];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.teamJoinActions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 66;
}

#pragma mark - TeamJoinActionViewModelDelegate

- (void)tableviewReload {
  [self.tableView reloadData];
  self.emptyView.hidden = (self.viewModel.teamJoinActions.count > 0);
}

#pragma mark - SystemNotificationCellDelegate

/// 同意入群申请
- (void)onAcceptWithAction:(NETeamJoinAction *)action {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  V2NIMTeamJoinActionInfo *info = action.nimTeamJoinAction;

  [self.viewModel agreeRequest:info completion:^(NSError * _Nullable error) {
    if (error) {
      NSError *err = error;
      NSLog(@"ContactKit log: agreeRequest error: %@", err);

      NSInteger code = err.code;
      if (code == protocolSendFailed) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
      } else if (code == teamNotExistCode) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"team_not_exist")];
      } else if (code == teamMemberNotExist) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"verification_processed")];
      } else if (code == alreadyInTeamCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"already_in_the_team")];
      } else if (code == invitationExpiredCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"invitation_expired")];
      } else if (code == noPermissionOperationCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"no_permission_tip")];
      } else if (code == teamMemberLimitExceededCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"team_member_limit_exceeded")];
      } else if (code == joinedTeamLimitExceededCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"joined_team_limit_exceeded")];
      } else {
        [weakSelf.view ne_makeToast:commonLocalizable(@"failed_operation")];
        return;
      }

      [weakSelf.viewModel changeTeamJoinActionStatus:info status:V2NIM_TEAM_JOIN_ACTION_STATUS_EXPIRED];
      [weakSelf tableviewReload];
    } else {
      [weakSelf tableviewReload];
    }
  }];
}

/// 拒绝入群申请
- (void)onRefuseWithAction:(NETeamJoinAction *)action {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  V2NIMTeamJoinActionInfo *info = action.nimTeamJoinAction;

  [self.viewModel refuseRequest:info completion:^(NSError * _Nullable error) {
    if (error) {
      NSError *err = error;
      NSLog(@"ContactKit log: refuseRequest error: %@", err);

      NSInteger code = err.code;
      if (code == protocolSendFailed) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
      } else if (code == teamNotExistCode) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"team_not_exist")];
      } else if (code == teamMemberNotExist) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"verification_processed")];
      } else if (code == alreadyInTeamCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"already_in_the_team")];
      } else if (code == invitationExpiredCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"invitation_expired")];
      } else if (code == noPermissionOperationCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"no_permission_tip")];
      } else if (code == teamMemberLimitExceededCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"team_member_limit_exceeded")];
      } else if (code == joinedTeamLimitExceededCode) {
        [weakSelf.view ne_makeToast:contactLocalizable(@"joined_team_limit_exceeded")];
      } else {
        [weakSelf.view ne_makeToast:commonLocalizable(@"failed_operation")];
        return;
      }

      [weakSelf.viewModel changeTeamJoinActionStatus:info status:V2NIM_TEAM_JOIN_ACTION_STATUS_EXPIRED];
      [weakSelf tableviewReload];
    } else {
      [weakSelf tableviewReload];
    }
  }];
}

#pragma mark - Lazy Init

- (TeamJoinActionViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamJoinActionViewModel alloc] init];
  }
  return _viewModel;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;

    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

@end
