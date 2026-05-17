// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamDetailViewController.h"
#import "TeamConstant.h"
#import "TeamCenterTextCell.h"
#import "TeamDetailHeaderView.h"
#import "TeamTextWithDetailCell.h"
#import "TeamDetailItem.h"
#import "TeamDetailViewModel.h"
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/NERouterUrl.h>
#import <NEChatKitOC/Router.h>
#import <NEChatKitOC/NIMExtension.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/NECoreIM2Constant.h>

@interface NEBaseTeamDetailViewController ()
@property (nonatomic, strong) NSMutableArray<NSArray<TeamDetailItem *> *> *data;
@property (nonatomic, strong, readwrite) TeamDetailViewModel *viewModel;
@property (nonatomic, strong, readwrite) TeamDetailHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation NEBaseTeamDetailViewController

- (instancetype)initWithNimTeam:(V2NIMTeam *)nimTeam {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _team = nimTeam;
    _className = @"TeamDetailViewController";
    _data = [NSMutableArray array];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _className = @"TeamDetailViewController";
    _data = [NSMutableArray array];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self commonUI];
  [self loadData];
}

- (void)commonUI {
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.moreButton.hidden = YES;

  UIView *headerBackView = [[UIView alloc] init];
  headerBackView.translatesAutoresizingMaskIntoConstraints = NO;
  headerBackView.backgroundColor = UIColor.whiteColor;
  [headerBackView addSubview:self.headerView];
  self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.leftAnchor constraintEqualToAnchor:headerBackView.leftAnchor constant:20.0],
    [self.headerView.topAnchor constraintEqualToAnchor:headerBackView.topAnchor],
    [self.headerView.heightAnchor constraintEqualToConstant:113.0],
    [self.headerView.rightAnchor constraintEqualToAnchor:headerBackView.rightAnchor constant:-20.0],
  ]];

  [self.view addSubview:headerBackView];
  [NSLayoutConstraint activateConstraints:@[
    [headerBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [headerBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [headerBackView.heightAnchor constraintEqualToConstant:113.0],
    [headerBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];

  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:headerBackView.bottomAnchor],
  ]];

  [self.tableView registerClass:[TeamTextWithDetailCell class] forCellReuseIdentifier:NSStringFromClass([TeamTextWithDetailCell class])];
  [self.tableView registerClass:[TeamCenterTextCell class] forCellReuseIdentifier:NSStringFromClass([TeamCenterTextCell class])];
}

- (void)loadData {
  if (!self.team) {
    return;
  }

  BOOL showOwner = ![self.team ne_isDisscuss];
  [self.headerView setData:self.team showOwner:showOwner];

  [self.data removeAllObjects];
  TeamDetailItem *introItem = [[TeamDetailItem alloc] initWithTitle:NETeamUIKitLocalizable(@"team_intr")
                                                        detailTitle:self.team.intro
                                                              value:NO
                                                          textColor:UIColor.darkTextColor
                                                          cellClass:[TeamTextWithDetailCell class]];
  [self.data addObject:@[ introItem ]];

  NSString *actionTitle = self.team.isValidTeam ? commonLocalizable(@"chat") : commonLocalizable(@"join_team");
  TeamDetailItem *actionItem = [[TeamDetailItem alloc] initWithTitle:actionTitle
                                                         detailTitle:@""
                                                               value:NO
                                                           textColor:[UIColor ne_colorWithHexString:@"#337EFF"]
                                                           cellClass:[TeamCenterTextCell class]];
  [self.data addObject:@[ actionItem ]];

  [self.tableView.tableHeaderView layoutIfNeeded];
  [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamDetailItem *item = self.data[indexPath.section][indexPath.row];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(item.cellClass) forIndexPath:indexPath];
  if ([cell isKindOfClass:[TeamTextWithDetailCell class]]) {
    TeamTextWithDetailCell *detailCell = (TeamTextWithDetailCell *)cell;
    [detailCell setModel:item];
    if ([item.title isEqualToString:NETeamUIKitLocalizable(@"team_intr")]) {
      detailCell.detailTitleLabel.numberOfLines = 0;
    }
    return detailCell;
  }
  if ([cell isKindOfClass:[TeamCenterTextCell class]]) {
    [(TeamCenterTextCell *)cell setModel:item];
    return cell;
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = UIColor.clearColor;
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 0.1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  UIView *footerView = [[UIView alloc] init];
  footerView.backgroundColor = UIColor.clearColor;
  return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamDetailItem *item = self.data[indexPath.section][indexPath.row];
  if ([item.title isEqualToString:commonLocalizable(@"chat")]) {
    [self toChat];
  }
  if ([item.title isEqualToString:commonLocalizable(@"join_team")]) {
    [self joinTeam];
  }
}

- (void)toChat {
  NSString *teamId = self.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
  if (conversationId.length == 0) {
    return;
  }

  [[Router shared] use:PushTeamChatVCRouter
            parameters:@{
              @"nav" : self.navigationController ?: [NSNull null],
              @"conversationId" : conversationId,
              @"removeTeamVC" : @YES
            }
               closure:nil];
}

- (void)joinTeam {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSString *teamId = self.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel applyJoinTeam:teamId completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [NEALog infoLog:strongSelf.className desc:[NSString stringWithFormat:@"CALLBACK addFriend %@", error.localizedDescription ?: @"no error"]];
    if (error) {
      [NEALog errorLog:@"TeamDetailViewController" desc:[NSString stringWithFormat:@"applyJoinTeam failed :%@", error]];
      NSInteger errorCode = error.code;
      if (errorCode == protocolSendFailed) {
        [strongSelf showToast:commonLocalizable(@"network_error")];
      } else if (errorCode == teamNotExistCode) {
        [strongSelf showToast:commonLocalizable(@"team_not_exist")];
      } else if (errorCode == alreadyInTeamCode) {
        [strongSelf toChat];
      } else if (errorCode == teamMemberLimitExceededCode) {
        [strongSelf showToast:NETeamUIKitLocalizable(@"team_member_limit_exceeded")];
      } else if (errorCode == joinedTeamLimitExceededCode) {
        [strongSelf showToast:NETeamUIKitLocalizable(@"joined_team_limit_exceeded")];
      } else {
        [strongSelf showToast:NETeamUIKitErrorToast(error)];
      }
      return;
    }

    if (team.isValidTeam) {
      [strongSelf toChat];
      return;
    }
    [strongSelf showToast:NETeamUIKitLocalizable(@"send_team_join_apply")];
  }];
}

- (TeamDetailViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamDetailViewModel alloc] init];
  }
  return _viewModel;
}

- (TeamDetailHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[TeamDetailHeaderView alloc] initWithFrame:CGRectZero];
  }
  return _headerView;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.estimatedRowHeight = 66.0;
    _tableView.estimatedSectionHeaderHeight = 0.0;
    _tableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

@end
