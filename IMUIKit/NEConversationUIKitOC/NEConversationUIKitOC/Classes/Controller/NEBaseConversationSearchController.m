// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseConversationSearchController.h"
#import "ConversationSearchViewModel.h"
#import "NEBaseConversationSearchCell.h"
#import <NEChatKit/ConversationSearchListModel.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/FunSearchView.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NEChatKit/NEChatKitOC.h>

static NECommonLoader *NEConversationSearchLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:NSClassFromString(@"NEConversationLoader") ?: [NSObject class]];
  });
  return loader;
}

static NSString *NEConversationSearchLocalizable(NSString *key) {
  return [NEConversationSearchLoader() localizable:key];
}

NSString *NEConversationSearchLocalizedString(NSString *key) {
  return NEConversationSearchLocalizable(key);
}

@implementation NEBaseConversationSearchController

static NSString * const NEConversationSearchPushP2pChatVCRouter = @"imkit://chat/p2pChat.page";
static NSString * const NEConversationSearchPushTeamChatVCRouter = @"imkit://chat/teamChat.page";

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _viewModel = [[ConversationSearchViewModel alloc] init];
    _searchStr = @"";
    _headTitleArr = [[NSMutableArray alloc] initWithObjects:NEConversationSearchLocalizable(@"friend"), nil];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self initialConfig];
  [self setupSubviews];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.searchTextField becomeFirstResponder];
  });
}

- (void)initialConfig {
  self.title = NEConversationSearchLocalizable(@"search");
  [self.headTitleArr addObjectsFromArray:@[
    NEConversationSearchLocalizable(@"discussion_group"),
    NEConversationSearchLocalizable(@"senior_group")
  ]];
}

- (void)setupSubviews {
  [self.view addSubview:self.tableView];
  [self.view addSubview:self.searchTextField];
  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.emptyView.widthAnchor constraintEqualToConstant:200.0],
    [self.emptyView.heightAnchor constraintEqualToConstant:200.0],
  ]];
}

- (void)searchTextFieldChange:(SearchTextField *)textfield {
  NSString *searchText = textfield.text ?: @"";
  if (searchText.length == 0) {
    self.emptyView.hidden = YES;
    [self.viewModel.friendDatas removeAllObjects];
    [self.viewModel.discussionDatas removeAllObjects];
    [self.viewModel.seniorDatas removeAllObjects];
    [self.tableView reloadData];
    return;
  }

  UITextRange *textRange = textfield.markedTextRange;
  if (textRange == nil || textRange.empty) {
    __weak typeof(self) weakSelf = self;
    self.searchStr = searchText;
    [self.viewModel doSearch:searchText completion:^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) {
        return;
      }
      BOOL isEmpty = self.viewModel.friendDatas.count == 0 &&
                     self.viewModel.discussionDatas.count == 0 &&
                     self.viewModel.seniorDatas.count == 0;
      self.emptyView.hidden = !isEmpty;
      [self.tableView reloadData];
    }];
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.headTitleArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return self.viewModel.friendDatas.count;
  } else if (section == 1) {
    return self.viewModel.discussionDatas.count;
  } else if (section == 2) {
    return self.viewModel.seniorDatas.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEBaseConversationSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseConversationSearchCell class])
                                                                       forIndexPath:indexPath];
  if (indexPath.section == 0) {
    cell.searchModel = self.viewModel.friendDatas[indexPath.row];
  } else if (indexPath.section == 1) {
    cell.searchModel = self.viewModel.discussionDatas[indexPath.row];
  } else {
    cell.searchModel = self.viewModel.seniorDatas[indexPath.row];
  }
  cell.searchText = self.searchStr;
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  __weak typeof(self) weakSelf = self;
  if (indexPath.section == 0) {
    ConversationSearchListModel *searchModel = self.viewModel.friendDatas[indexPath.row];
    NSString *userId = searchModel.userInfo.user.accountId ?: @"";
    if (userId.length > 0 && self.navigationController != nil) {
      NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:userId];
      [[Router shared] use:NEConversationSearchPushP2pChatVCRouter
                parameters:@{ @"nav" : self.navigationController,
                              @"conversationId" : conversationId }
                   closure:nil];
    }
    return;
  }

  ConversationSearchListModel *searchModel = indexPath.section == 1 ? self.viewModel.discussionDatas[indexPath.row] : self.viewModel.seniorDatas[indexPath.row];
  NSString *teamId = searchModel.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  [[TeamRepo shared] getTeamInfo:teamId teamType:searchModel.team.teamType completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    if (error != nil) {
      if (error.code == protocolSendFailed) {
        [self showToast:commonLocalizable(@"network_error")];
      } else {
        [self ne_showSingleAlert:commonLocalizable(@"tip")
                         message:NEConversationSearchLocalizable(@"leave_team_desc")
                         handler:nil];
      }
      return;
    }
    if (team == nil || team.isValidTeam == NO) {
      [self ne_showSingleAlert:commonLocalizable(@"tip")
                       message:NEConversationSearchLocalizable(@"leave_team_desc")
                       handler:nil];
      return;
    }
    if (self.navigationController != nil) {
      NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
      [[Router shared] use:NEConversationSearchPushTeamChatVCRouter
                parameters:@{ @"nav" : self.navigationController,
                              @"conversationId" : conversationId }
                   closure:nil];
    }
  }];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  SearchSessionBaseView *sectionView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SearchSessionBaseView class])];
  [sectionView setUpTitle:self.headTitleArr[section]];
  UIView *backgroundView = [[UIView alloc] init];
  backgroundView.backgroundColor = UIColor.whiteColor;
  sectionView.backgroundView = backgroundView;
  return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0 && self.viewModel.friendDatas.count > 0) {
    return 30.0;
  }
  if (section == 1 && self.viewModel.discussionDatas.count > 0) {
    return 30.0;
  }
  if (section == 2 && self.viewModel.seniorDatas.count > 0) {
    return 30.0;
  }
  return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 0.0;
}

#pragma mark - Getters

- (UITableView *)tableView {
  if (_tableView == nil) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 60.0;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.sectionHeaderHeight = 30.0;
    _tableView.sectionFooterHeight = 0.0;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.estimatedRowHeight = 0.0;
    _tableView.estimatedSectionHeaderHeight = 0.0;
    _tableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

- (SearchTextField *)searchTextField {
  if (_searchTextField == nil) {
    _searchTextField = [[SearchTextField alloc] init];
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
    _searchTextField.contentMode = UIViewContentModeCenter;
    _searchTextField.leftView = leftImageView;
    _searchTextField.leftViewMode = UITextFieldViewModeAlways;
    _searchTextField.placeholder = commonLocalizable(@"search");
    _searchTextField.font = [UIFont systemFontOfSize:14.0];
    _searchTextField.textColor = UIColor.ne_greyText;
    _searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _searchTextField.layer.cornerRadius = 8.0;
    _searchTextField.backgroundColor = UIColor.ne_lightBackgroundColor;
    _searchTextField.clearButtonMode = UITextFieldViewModeAlways;
    _searchTextField.returnKeyType = UIReturnKeySearch;
    [_searchTextField addTarget:self action:@selector(searchTextFieldChange:) forControlEvents:UIControlEventEditingChanged];
    UIButton *clearButton = [_searchTextField valueForKey:@"_clearButton"];
    clearButton.accessibilityIdentifier = @"id.clear";
    _searchTextField.accessibilityIdentifier = @"id.search";
  }
  return _searchTextField;
}

- (NEEmptyDataView *)emptyView {
  if (_emptyView == nil) {
    _emptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                    content:NEConversationSearchLocalizable(@"user_not_exist")
                                                      frame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyView.userInteractionEnabled = NO;
    _emptyView.hidden = YES;
    _emptyView.backgroundColor = UIColor.clearColor;
  }
  return _emptyView;
}

@end
