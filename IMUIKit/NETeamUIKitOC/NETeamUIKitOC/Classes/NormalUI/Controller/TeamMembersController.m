// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMembersController.h"
#import "TeamMemberCell.h"
#import "TeamConstant.h"
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/IMKitClient.h>

@implementation TeamMembersController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.backView.backgroundColor = UIColor.ne_backcolor;
  [self.contentTableView registerClass:TeamMemberCell.class forCellReuseIdentifier:NSStringFromClass(TeamMemberCell.class)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TeamMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(TeamMemberCell.class)
                                                         forIndexPath:indexPath];
  NETeamMemberInfoModel *model = [self getRealModel:indexPath.row];
  if (model) {
    BOOL isShowRemove = NO;
    NSString *accountId = model.nimUser.user.accountId;
    if ([self isOwner:accountId]) {
      cell.ownerLabel.hidden = NO;
      cell.ownerLabel.text = NETeamUIKitLocalizable(@"team_owner");
      cell.ownerWidth.constant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 86.0 : 40.0;
    } else if (model.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      cell.ownerLabel.hidden = NO;
      cell.ownerLabel.text = NETeamUIKitLocalizable(@"team_manager");
      cell.ownerWidth.constant = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 58.0 : 52.0;
      if ([self isOwner:[IMKitClient.instance account]]) {
        isShowRemove = YES;
      }
    } else {
      if ([self isOwner:[IMKitClient.instance account]] || self.viewModel.currentMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
        isShowRemove = YES;
      }
      cell.ownerLabel.hidden = YES;
    }

    cell.index = indexPath.row;
    cell.delegate = self;
    [cell configure:model];
    cell.removeButton.hidden = !isShowRemove;
    cell.removeLabel.hidden = !isShowRemove;
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 64.0;
}

@end
