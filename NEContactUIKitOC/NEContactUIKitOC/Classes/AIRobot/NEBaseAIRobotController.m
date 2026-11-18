// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotController.h"
#import "AIRobotViewModel.h"
#import "ContactConst.h"
#import "NEAIRobotModel.h"
#import "NEBaseAIRobotListCell.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

static NSString * const NEAIRobotCreateRouterCompat2 = @"imkit://contact/createAIRobot.page";
static NSString * const NEAIRobotDetailRouterCompat2 = @"imkit://contact/aiRobotDetail.page";

@implementation NEBaseAIRobotController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.robotTableViewTopAnchor.constant = self.topConstant;
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel getRobots:^(NSError * _Nullable error) {
    [weakSelf refreshTableView];
  }];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self setupRobotListUI];

  UIImage *addImage = [ne_contactImageNamed(@"add_black") imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithImage:addImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(didTapCreateRobot)];
    self.navigationItem.rightBarButtonItem = addItem;
  } else {
    self.navigationView.moreButton.hidden = NO;
    [self.navigationView setMoreButtonImage:addImage];
    [self.navigationView addMoreButtonTarget:self selector:@selector(didTapCreateRobot)];
  }
}

- (Class)robotCellClass {
  return [NEBaseAIRobotListCell class];
}

- (CGFloat)robotCellHeight {
  return 60.0;
}

- (void)didTapCreateRobot {
  if (self.viewModel.datas.count >= [AIRobotViewModel maxRobotCount]) {
    [self.view ne_makeToast:contactLocalizable(@"ai_robot_exceed_limit")];
    return;
  }

  [[Router shared] use:NEAIRobotCreateRouterCompat2
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"animated": @YES,
              @"defaultName": @"Bot_Claw",
            }
               closure:nil];
}

- (void)setupRobotListUI {
  [self changeLanguage];

  [self.view addSubview:self.robotTableView];
  self.robotTableViewTopAnchor = [self.robotTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.robotTableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.robotTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.robotTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.robotTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.robotTableView registerClass:[self robotCellClass]
              forCellReuseIdentifier:NSStringFromClass([self robotCellClass])];

  [self.view addSubview:self.robotEmptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.robotEmptyView.leftAnchor constraintEqualToAnchor:self.robotTableView.leftAnchor],
    [self.robotEmptyView.rightAnchor constraintEqualToAnchor:self.robotTableView.rightAnchor],
    [self.robotEmptyView.topAnchor constraintEqualToAnchor:self.robotTableView.topAnchor constant:50.0],
    [self.robotEmptyView.bottomAnchor constraintEqualToAnchor:self.robotTableView.bottomAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"my_ai_robot");
  self.robotEmptyView.message = contactLocalizable(@"no_ai_robot");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEBaseAIRobotListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self robotCellClass])
                                                                forIndexPath:indexPath];
  if (indexPath.row >= 0 && indexPath.row < self.viewModel.datas.count) {
    [cell configure:self.viewModel.datas[indexPath.row]];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self robotCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.row < 0 || indexPath.row >= self.viewModel.datas.count) {
    return;
  }

  V2NIMUserAIBot *bot = self.viewModel.datas[indexPath.row].bot;
  if (!bot) {
    return;
  }

  [[Router shared] use:NEAIRobotDetailRouterCompat2
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"bot": bot,
              @"animated": @YES,
            }
               closure:nil];
}

- (BOOL)isLastRobot:(NSInteger)index {
  return self.viewModel.datas.count - 1 == index;
}

- (void)refreshTableView {
  [self.robotTableView reloadData];
  self.robotEmptyView.hidden = self.viewModel.datas.count > 0;
}

#pragma mark - Lazy Init

- (AIRobotViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[AIRobotViewModel alloc] init];
  }
  return _viewModel;
}

- (UITableView *)robotTableView {
  if (!_robotTableView) {
    _robotTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _robotTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _robotTableView.backgroundColor = [UIColor clearColor];
    _robotTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _robotTableView.sectionHeaderHeight = 12.0;
    _robotTableView.dataSource = self;
    _robotTableView.delegate = self;
    _robotTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 12.0)];
    _robotTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _robotTableView.estimatedRowHeight = 0;
    _robotTableView.estimatedSectionHeaderHeight = 0;
    _robotTableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
      _robotTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _robotTableView;
}

- (NEEmptyDataView *)robotEmptyView {
  if (!_robotEmptyView) {
    _robotEmptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                         content:contactLocalizable(@"no_ai_robot")
                                                           frame:CGRectZero];
    _robotEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _robotEmptyView.hidden = YES;
  }
  return _robotEmptyView;
}

@end
