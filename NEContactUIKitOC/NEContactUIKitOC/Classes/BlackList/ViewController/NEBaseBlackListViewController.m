// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseBlackListViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "ContactConst.h"
#import "ContactUIConfig.h"
#import "NEBaseContactSelectedViewController.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NEConfigManager.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>

#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NEChatKit.h>


@implementation NEBaseBlackListViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.tableViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    self.navigationController.navigationBarHidden = NO;
  } else {
    self.navigationController.navigationBarHidden = YES;
  }

  self.viewModel.delegate = self;
  [self commonUI];
  [self loadData];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
}

- (void)initNav {
  UIImage *image = [[CommonUIConfig shared].backArrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:image
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(backEvent)];
  backItem.accessibilityIdentifier = @"id.backArrow";
  self.navigationItem.leftBarButtonItem = backItem;

  UIImage *addImage = [ne_contactImageNamed(@"add_black") imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithImage:addImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(toSetting)];
  addItem.accessibilityIdentifier = @"id.threePoint";
  self.navigationItem.rightBarButtonItem = addItem;

  [self.navigationView setMoreButtonImage:ne_contactImageNamed(@"add_black")];
}

/// UI 初始化
- (void)commonUI {
  [self changeLanguage];
  [self initNav];

  [self.view addSubview:self.tableView];
  self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEUIKitAdaptiveNavigationAndStatusHeight()];
  self.tableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  [self.emptyView setText:contactLocalizable(@"no_blacklist")];
  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"blacklist");
  self.contentLabel.text = contactLocalizable(@"black_tip");
  [self.tableView reloadData];
}

- (void)loadData {
  [self.viewModel getBlackList];
  [self.tableView reloadData];
  [self updateEmptyState];
}

- (void)updateEmptyState {
  self.emptyView.hidden = self.viewModel.blockList.count > 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.blockList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] init];
}

- (NEBaseContactSelectedViewController *)getContactSelectVC {
  return [[NEBaseContactSelectedViewController alloc] init];
}

- (void)toSetting {
  NEBaseContactSelectedViewController *contactSelectVC = [self getContactSelectVC];
  [self.navigationController pushViewController:contactSelectVC animated:YES];
  __weak typeof(self) weakSelf = self;
  contactSelectVC.callBack = ^(NSArray<ContactInfo *> *selectMemberarray) {
    NSMutableArray<NEUserWithFriend *> *users = [NSMutableArray array];
    for (ContactInfo *memberInfo in selectMemberarray) {
      if (memberInfo.user) {
        [users addObject:memberInfo.user];
      }
    }
    [weakSelf addBlackUsersWithUsers:users];
  };
}

- (void)addBlackUsersWithUsers:(NSArray<NEUserWithFriend *> *)users {
  __weak typeof(self) weakSelf = self;
  [self.viewModel addBlackList:users completion:^(NSError * _Nullable error) {
    if (error) {
      [weakSelf.view ne_makeToast:error.localizedDescription];
    }
  }];
}

#pragma mark - BlackListCellDelegate

- (void)removeUserWithAccount:(NSString *)account index:(NSInteger)index {
  __weak typeof(self) weakSelf = self;
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  if (!account) {
    return;
  }

  [self.viewModel removeFromBlackList:account completion:^(NSError * _Nullable error) {
    if (error) {
      [weakSelf.view ne_makeToast:error.localizedDescription];
    }
  }];
}

#pragma mark - BlackListViewModelDelegate

/// 重新加载表格
- (void)tableViewReload {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
    [self updateEmptyState];
  });
}

#pragma mark - Lazy Init

- (BlackListViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[BlackListViewModel alloc] init];
  }
  return _viewModel;
}

- (UIView *)headView {
  if (!_headView) {
    BOOL adaptive = NEAdaptiveDeviceGate.adaptiveHostActive;
    CGFloat width = adaptive ? 0 : [UIScreen mainScreen].bounds.size.width;
    _headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    if (adaptive) {
      _headView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [_headView addSubview:self.contentLabel];
    if (adaptive) {
      [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leadingAnchor constraintEqualToAnchor:_headView.leadingAnchor constant:20],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:_headView.trailingAnchor],
        [self.contentLabel.topAnchor constraintEqualToAnchor:_headView.topAnchor],
        [self.contentLabel.bottomAnchor constraintEqualToAnchor:_headView.bottomAnchor],
      ]];
    }
  }
  return _headView;
}

- (UILabel *)contentLabel {
  if (!_contentLabel) {
    BOOL adaptive = NEAdaptiveDeviceGate.adaptiveHostActive;
    _contentLabel = [[UILabel alloc] initWithFrame:adaptive
                                                    ? CGRectZero
                                                    : CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 20, 40)];
    if (adaptive) {
      _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    _contentLabel.text = contactLocalizable(@"black_tip");
    _contentLabel.textColor = [UIColor ne_emptyTitleColor];
    _contentLabel.font = [UIFont systemFontOfSize:14];
    _contentLabel.accessibilityIdentifier = @"id.tips";
  }
  return _contentLabel;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableHeaderView = self.headView;
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
