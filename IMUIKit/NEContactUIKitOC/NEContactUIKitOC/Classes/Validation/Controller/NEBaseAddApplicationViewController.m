// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAddApplicationViewController.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NIMSDK/NIMSDK.h>
#import "ContactConst.h"
#import "NEBaseSystemNotificationCell.h"
#import <NECommonUIKitOC/UIView+YXToast.h>

@interface NEBaseAddApplicationViewController ()
@property (nonatomic, strong, readwrite) AddApplicationViewModel *viewModel;
@end

@implementation NEBaseAddApplicationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = contactLocalizable(@"contact_friend");
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.title = contactLocalizable(@"contact_friend");
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

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.viewModel setAddApplicationRead:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// 返回上一级页面
- (void)backEvent {
  [super backEvent];
  [self.viewModel setAddApplicationRead:nil];
}

/// 进入后台，清空未读
- (void)appEnterBackground {
  [super appEnterBackground];
  __weak typeof(self) weakSelf = self;
  [self.viewModel setAddApplicationRead:^(BOOL success, NSError *_Nullable error) {
    if (success) {
      [weakSelf tableviewReload];
    }
  }];
}

/// 加载数据
- (void)loadData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadApplicationList:YES completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@ %@ loadApplicationList CALLBACK error: %@",
            ModuleName, NSStringFromClass([NEBaseAddApplicationViewController class]),
            error.localizedDescription);
    } else {
      weakSelf.emptyView.hidden = (weakSelf.viewModel.friendAddApplications.count > 0);
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

  self.emptyView.message = contactLocalizable(@"no_add_application");
  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:100],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"contact_friend");
  self.emptyView.message = contactLocalizable(@"no_add_application");
}

/// 清空好友申请
- (void)toSetting {
  if (!self.view.isVisibleInWindow) {
    return;
  }

  NSLog(@"%@ %@ toSetting", ModuleName, NSStringFromClass([self class]));

  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:contactLocalizable(@"clear_all_add_application")
             sure:^(__unused UIAlertAction *action) {
    [weakSelf.viewModel clearNotification:^(NSError *_Nullable error) {
      weakSelf.emptyView.hidden = (weakSelf.viewModel.friendAddApplications.count > 0);
      [weakSelf.tableView reloadData];
    }];
  }];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.friendAddApplications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 60;
}

#pragma mark - AddApplicationViewModelDelegate

- (void)tableviewReload {
  [self.tableView reloadData];
  self.emptyView.hidden = (self.viewModel.friendAddApplications.count > 0);
}

#pragma mark - SystemNotificationCellDelegate

/// 同意好友申请
- (void)onAcceptWithApplication:(NEAddApplication *)application {
  __weak typeof(self) weakSelf = self;
  V2NIMFriendAddApplication *info = application.v2Notification;

  [self.viewModel agreeRequest:info completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@ %@ CALLBACK agreeRequest failed, error = %@",
            ModuleName, NSStringFromClass([NEBaseAddApplicationViewController class]),
            error.localizedDescription);

      if (error.code == protocolSendFailed) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
      } else if (error.code == friendAlreadyExist) {
        [weakSelf.viewModel changeApplicationStatus:info
                                             status:V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED];
        [weakSelf.view ne_makeToast:contactLocalizable(@"verification_processed")];
        [weakSelf tableviewReload];
      } else {
        [weakSelf.view ne_makeToast:commonLocalizable(@"failed_operation")];
      }
    } else {
      [weakSelf tableviewReload];
    }
  }];
}

/// 拒绝好友申请
- (void)onRefuseWithApplication:(NEAddApplication *)application {
  __weak typeof(self) weakSelf = self;
  V2NIMFriendAddApplication *info = application.v2Notification;

  [self.viewModel refuseRequest:info completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@ %@ CALLBACK refuseRequest failed, error = %@",
            ModuleName, NSStringFromClass([NEBaseAddApplicationViewController class]),
            error.localizedDescription);

      if (error.code == protocolSendFailed) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
      } else if (error.code == friendAlreadyExist) {
        [weakSelf.viewModel changeApplicationStatus:info
                                             status:V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED];
        [weakSelf.view ne_makeToast:contactLocalizable(@"verification_processed")];
        [weakSelf tableviewReload];
      } else {
        [weakSelf.view ne_makeToast:commonLocalizable(@"failed_operation")];
      }
    } else {
      [weakSelf tableviewReload];
    }
  }];
}

#pragma mark - Lazy Init

- (AddApplicationViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[AddApplicationViewModel alloc] init];
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
