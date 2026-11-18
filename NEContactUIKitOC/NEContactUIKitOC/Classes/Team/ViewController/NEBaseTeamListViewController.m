// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamListViewController.h"
#import <NEChatKit/NETeam.h>
#import <NIMSDK/NIMSDK.h>
#import "ContactConst.h"
#import "ContactUIConfig.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NEChatKit.h>



static NSString * const NEContactTeamDataRouterCompat = @"imkit://contact/team/data";
static NSString * const NEContactPushTeamChatVCRouterCompat = @"imkit://chat/teamChat.page";

@implementation NEBaseTeamListViewController

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

  [self commonUI];
  [self loadData];
  __weak typeof(self) weakSelf = self;
  self.viewModel.refresh = ^{
    weakSelf.emptyView.hidden = (weakSelf.viewModel.teamList.count > 0);
    [weakSelf.tableView reloadData];
  };
  self.navigationView.moreButton.hidden = YES;
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
  self.navigationView.moreButton.hidden = YES;
}

- (void)commonUI {
  [self changeLanguage];
  [self initNav];

  [self.view addSubview:self.tableView];
  self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.tableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  self.emptyView.message = contactLocalizable(@"team_empty");
  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"my_teams");
  self.emptyView.message = contactLocalizable(@"team_empty");
}

- (void)loadData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel getTeamList:^(NSArray<NETeam *> * _Nullable teams, NSError * _Nullable error) {
    if (error) {
      NSLog(@"getTeamList error: %@", error);
    } else {
      [weakSelf.tableView reloadData];
      weakSelf.emptyView.hidden = (teams.count > 0);
    }
  }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.teamList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NETeam *model = self.viewModel.teamList[indexPath.row];
  if (self.isClickCallBack == YES) {
    [[Router shared] use:NEContactTeamDataRouterCompat
              parameters:@{@"team": model.v2Team ?: [NSNull null]}
                 closure:nil];
    [self.navigationController popViewControllerAnimated:YES];
    return;
  }
  if (model.teamId) {
    NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:model.teamId];
    [[Router shared] use:NEContactPushTeamChatVCRouterCompat
              parameters:@{@"nav": self.navigationController ?: [NSNull null], @"conversationId": conversationId ?: [NSNull null]}
                 closure:nil];
  }
}

#pragma mark - Lazy Init

- (TeamListViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamListViewModel alloc] init];
  }
  return _viewModel;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
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
