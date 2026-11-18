// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamMembersController.h"
#import "FunTeamMemberCell.h"
#import "FunTeamUIColor.h"
#import "TeamConstant.h"
#import <NEChatKit/IMKitClient.h>

@interface FunTeamMembersController ()
@property (nonatomic, strong) UIView *searchGrayBackView;
@end

@implementation FunTeamMembersController

- (UIColor *)memberLoadStatusTintColor {
  return UIColor.funTeamThemeColor;
}

- (void)viewDidLoad {
  [self.contentTableView registerClass:FunTeamMemberCell.class forCellReuseIdentifier:NSStringFromClass(FunTeamMemberCell.class)];
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;
  [self.view insertSubview:self.searchGrayBackView belowSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchGrayBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.searchGrayBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.searchGrayBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.searchGrayBackView.bottomAnchor constraintEqualToAnchor:self.contentTableView.topAnchor],
  ]];
  self.backView.backgroundColor = UIColor.whiteColor;
  self.searchTextField.backgroundColor = UIColor.whiteColor;
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunTeamMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(FunTeamMemberCell.class)
                                                            forIndexPath:indexPath];
  NETeamMemberInfoModel *model = [self getRealModel:indexPath.row];
  if (model) {
    NSString *keyword = [self.searchTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL isShowRemove = NO;
    NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
    if ([self isOwner:accountId]) {
      cell.ownerLabel.hidden = NO;
      cell.ownerLabel.text = NETeamUIKitLocalizable(@"team_owner");
      [cell setOwnerStyle];
    } else if (model.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      cell.ownerLabel.hidden = NO;
      cell.ownerLabel.text = NETeamUIKitLocalizable(@"team_manager");
      [cell setManagerStyle];
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
    NETeamMemberSearchResult *result = keyword.length > 0
      ? [self.viewModel searchResultForModel:model]
      : nil;
    [cell configure:model searchResult:result];
    [cell setRemoveControlsVisible:isShowRemove];
  }

  cell.dividerLine.hidden = [self isLastRow:indexPath.row];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 64.0;
}

- (BOOL)isLastRow:(NSInteger)index {
  NSString *text = [self.searchTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (text.length > 0) {
    return self.viewModel.searchDatas.count - 1 == index;
  }
  return self.viewModel.datas.count - 1 == index;
}

- (UIView *)searchGrayBackView {
  if (!_searchGrayBackView) {
    _searchGrayBackView = [[UIView alloc] init];
    _searchGrayBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _searchGrayBackView.backgroundColor = UIColor.funTeamBackgroundColor;
  }
  return _searchGrayBackView;
}

@end
