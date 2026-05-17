// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamManagerListController.h"
#import "TeamMemberSelectController.h"
#import "TeamArrowSettingCell.h"
#import "TeamManagerMemberCell.h"
#import "TeamConstant.h"
#import <NEChatKitOC/IMKitConfigCenter.h>

@implementation TeamManagerListController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.cellClassDic[@0] = TeamArrowSettingCell.class;
    self.cellClassDic[@1] = TeamManagerMemberCell.class;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = UIColor.whiteColor;

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-100.0],
    [self.emptyView.widthAnchor constraintEqualToConstant:122.0],
    [self.emptyView.heightAnchor constraintEqualToConstant:91.0],
  ]];
  [self sortAndReloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    TeamArrowSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"0" forIndexPath:indexPath];
    cell.titleLabel.text = NETeamUIKitLocalizable(@"add_manager");
    return cell;
  }

  TeamManagerMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"1" forIndexPath:indexPath];
  cell.delegate = self;
  cell.index = indexPath.row;
  [cell configure:self.viewmodel.managers[indexPath.row]];
  if (self.viewmodel.currentMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    cell.removeButton.hidden = YES;
    cell.removeLabel.hidden = YES;
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  if (indexPath.section == 0) {
    return 46.0;
  }
  if (indexPath.section == 1) {
    return 52.0;
  }
  return 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    TeamMemberSelectController *selectController = [[TeamMemberSelectController alloc] init];
    selectController.teamId = self.teamId;
    selectController.title = NETeamUIKitLocalizable(@"team_member_select");
    NSInteger maxCount = [IMKitConfigCenter shared].teamManagerMaxCount;
    selectController.selectCountLimit = maxCount == -1 ? NSIntegerMax : maxCount;
    __weak typeof(self) weakSelf = self;
    selectController.selectMemberBlock = ^(NSArray<NETeamMemberInfoModel *> *members) {
      [weakSelf.navigationController popViewControllerAnimated:YES];
      [weakSelf didAddManagers:members];
    };
    [self.navigationController pushViewController:selectController animated:YES];
    return;
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)sortAndReloadData {
  [super sortAndReloadData];
  self.emptyView.hidden = self.viewmodel.managers.count > 0;
}

@end
