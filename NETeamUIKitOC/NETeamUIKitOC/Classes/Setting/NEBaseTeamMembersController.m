// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseTeamMembersController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "TeamConstant.h"
#import "NEBaseTeamMemberCell.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatUIKitOC/NEChatUIConstant.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>

static NSString * const NETeamMembersMeSettingRouter = @"imkit://mine/userInfo.page";
static NSString * const NETeamMembersContactUserInfoPageRouter = @"imkit://contact/userInfo.page";

@interface NEBaseTeamMembersController ()
@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) TeamMembersViewModel *viewModel;
@property (nonatomic, copy) NSArray<NSString *> *renderedAccountIds;
@property (nonatomic, copy, nullable) NSString *searchStartAccountId;
@property (nonatomic, assign) CGFloat searchStartRelativeY;
@property (nonatomic, assign) CGFloat searchStartContentOffsetX;
@property (nonatomic, copy) NSString *appliedSearchKeyword;
@end

@implementation NEBaseTeamMembersController

- (instancetype)initWithTeamId:(NSString *)teamId {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _teamId = [teamId copy];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

- (void)setMemberDatas:(NSArray<NETeamMemberInfoModel *> *)memberDatas {
  _memberDatas = memberDatas;
  [self.viewModel setShowDatas:memberDatas];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addObserver];
  self.viewModel.delegate = self;
  self.viewModel.teamId = self.teamId;
  self.navigationView.moreButton.hidden = YES;
  [self.emptyView setEmptyImageName:@"user_empty"];
  self.emptyView.message = NETeamUIKitLocalizable(@"no_result");

  __weak typeof(self) weakSelf = self;
  if (self.teamId.length > 0) {
    [self.viewModel getTeamInfo:self.teamId completion:^(NETeamInfoModel * _Nullable teamInfo, NSError * _Nullable error) {
      weakSelf.ownerId = teamInfo.team.ownerAccountId;
      if (error) {
        [weakSelf showToast:NETeamUIKitErrorToast(error)];
        [weakSelf didNeedRefreshUI];
      } else {
        if (![teamInfo.team ne_isDisscuss]) {
          weakSelf.isSenior = YES;
          weakSelf.title = chatLocalizable(@"group_memmber");
        } else {
          weakSelf.title = NETeamUIKitLocalizable(@"discuss_mebmer");
        }
        [weakSelf didNeedRefreshUI];
      }
    }];
  }
  [self setupUI];
  if (self.teamId.length > 0) {
    [self didNeedRefreshUI];
  }
}

- (void)setupUI {
  self.backView.backgroundColor = UIColor.clearColor;
  self.backView.translatesAutoresizingMaskIntoConstraints = NO;
  self.backView.clipsToBounds = YES;
  self.backView.layer.cornerRadius = 4.0;

  [self.view addSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:8.0 + self.topConstant],
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.backView.heightAnchor constraintEqualToConstant:32.0],
  ]];

  [self.backView addSubview:self.searchIconImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchIconImageView.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.searchIconImageView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
  ]];

  [self.backView addSubview:self.searchTextField];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchTextField.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:36.0],
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.searchTextField.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
    [self.searchTextField.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
  ]];

  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.backView.bottomAnchor constant:10.0],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.contentTableView registerClass:NEBaseTeamMemberCell.class forCellReuseIdentifier:NSStringFromClass(NEBaseTeamMemberCell.class)];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.contentTableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.contentTableView.rightAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.contentTableView.topAnchor constant:50.0],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.contentTableView.bottomAnchor],
  ]];
}

- (void)addObserver {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textChange)
                                               name:UITextFieldTextDidChangeNotification
                                             object:nil];
}

- (BOOL)isOwner:(NSString *)userId {
  if (!self.isSenior) {
    return NO;
  }
  return userId.length > 0 && [userId isEqualToString:self.ownerId];
}

- (UIColor *)memberLoadStatusTintColor {
  return UIColor.ne_defaultPrimaryColor;
}

- (BOOL)isSearching {
  NSString *text = self.searchTextField.text ?: @"";
  return [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length > 0;
}

- (void)textChange {
  NSString *text = self.searchTextField.text ?: @"";
  NSString *previousKeyword = self.appliedSearchKeyword ?: @"";
  NSString *keyword = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  BOOL willSearch = keyword.length > 0;
  if (previousKeyword.length == 0 && willSearch) {
    [self captureSearchStartPosition];
  }
  self.appliedSearchKeyword = keyword;
  [self.viewModel searchData:text];
  if (keyword.length == 0) {
    self.emptyView.hidden = YES;
  }
  [self didNeedRefreshUI];
  if (!willSearch) {
    [self restoreSearchStartPositionIfNeeded];
  } else if (![previousKeyword isEqualToString:keyword]) {
    [self scrollSearchResultsToTop];
  }
}

- (NETeamMemberInfoModel *)getRealModel:(NSInteger)index {
  if ([self isSearching] && self.viewModel.searchDatas.count > index) {
    return self.viewModel.searchDatas[index];
  }
  if (self.viewModel.datas.count > index) {
    return self.viewModel.datas[index];
  }
  return nil;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return [self isSearching] ? self.viewModel.searchDatas.count : self.viewModel.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEBaseTeamMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(NEBaseTeamMemberCell.class)
                                                               forIndexPath:indexPath];
  NETeamMemberInfoModel *model = [self getRealModel:indexPath.row];
  if (model) {
    NSString *keyword = [self.searchTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NETeamMemberSearchResult *result = keyword.length > 0
      ? [self.viewModel searchResultForModel:model]
      : nil;
    [cell configure:model searchResult:result];
    cell.ownerLabel.hidden = ![self isOwner:model.teamMember.accountId ?: model.nimUser.user.accountId];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 62.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  NETeamMemberInfoModel *model = [self getRealModel:indexPath.row];
  NSString *uid = model.teamMember.accountId ?: model.nimUser.user.accountId;
  if (uid.length == 0) {
    return;
  }

  if ([[IMKitClient instance] isMe:uid]) {
    [[Router shared] use:NETeamMembersMeSettingRouter
              parameters:@{@"nav": self.navigationController ?: [NSNull null]}
                 closure:nil];
  } else {
    [[Router shared] use:NETeamMembersContactUserInfoPageRouter
              parameters:@{
                @"nav": self.navigationController ?: [NSNull null],
                @"uid": uid,
              }
                 closure:nil];
  }
}

- (void)didClickRemoveButton:(NETeamMemberInfoModel *)model index:(NSInteger)index {
  (void)index;
  __weak typeof(self) weakSelf = self;
  [self showAlert:NETeamUIKitLocalizable(@"remove_manager_title")
          message:NETeamUIKitLocalizable(@"remove_member_tip")
             sure:^(__unused UIAlertAction *action) {
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
      return;
    }

    NSString *tid = weakSelf.teamId ?: @"";
    NSString *uid = model.teamMember.accountId ?: model.nimUser.user.accountId ?: @"";
    if (tid.length == 0 || uid.length == 0) {
      return;
    }

    [weakSelf.viewModel removeTeamMember:tid uids:@[uid] completion:^(NSError * _Nullable error) {
      if (error) {
        if (error.code == noPermissionCode) {
          [weakSelf.view ne_makeToast:NETeamUIKitLocalizable(@"no_permission_tip")];
        } else {
          [weakSelf.view ne_makeToast:NETeamUIKitLocalizable(@"remove_failed")];
        }
        return;
      }

      NSString *searchText = weakSelf.searchTextField.text ?: @"";
      if (searchText.length > 0) {
        NSIndexSet *indexes = [weakSelf.viewModel.searchDatas indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
          return [obj.teamMember.accountId isEqualToString:uid];
        }];
        [weakSelf.viewModel.searchDatas removeObjectsAtIndexes:indexes];
      }
      [weakSelf.viewModel removeModel:@[uid]];
      [weakSelf didNeedRefreshUI];
    }];
  }];
}

- (void)didClickRemoveButton:(NETeamMemberInfoModel *)model :(NSInteger)index {
  [self didClickRemoveButton:model index:index];
}

- (void)didNeedRefreshUI {
  NSInteger visibleCount = [self isSearching] ? self.viewModel.searchDatas.count : self.viewModel.datas.count;
  self.emptyView.hidden = self.viewModel.isLoadingMembers || self.viewModel.memberLoadError != nil || visibleCount > 0;
  [self updateMemberLoadStatus];
  [self reloadPreservingTopMember];
}

- (NSArray<NETeamMemberInfoModel *> *)displayedMembers {
  return [self isSearching] ? self.viewModel.searchDatas : self.viewModel.datas;
}

- (void)reloadPreservingTopMember {
  NSIndexPath *topIndexPath = [self.contentTableView.indexPathsForVisibleRows sortedArrayUsingSelector:@selector(compare:)].firstObject;
  NSString *anchorAccountId = nil;
  CGFloat relativeY = 0;
  if (topIndexPath && topIndexPath.row < self.renderedAccountIds.count) {
    anchorAccountId = self.renderedAccountIds[topIndexPath.row];
    relativeY = [self.contentTableView rectForRowAtIndexPath:topIndexPath].origin.y - self.contentTableView.contentOffset.y;
  }
  NSMutableArray<NSString *> *nextRenderedAccountIds = [NSMutableArray array];
  for (NETeamMemberInfoModel *model in [self displayedMembers]) {
    [nextRenderedAccountIds addObject:model.teamMember.accountId ?: model.nimUser.user.accountId ?: @""];
  }

  [UIView performWithoutAnimation:^{
    [self.contentTableView reloadData];
    [self.contentTableView layoutIfNeeded];
  }];
  self.renderedAccountIds = [nextRenderedAccountIds copy];

  if (anchorAccountId.length == 0) {
    return;
  }
  __block NSInteger anchorRow = NSNotFound;
  [[self displayedMembers] enumerateObjectsUsingBlock:^(NETeamMemberInfoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
    NSString *accountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
    if ([accountId isEqualToString:anchorAccountId]) {
      anchorRow = (NSInteger)idx;
      *stop = YES;
    }
  }];
  if (anchorRow == NSNotFound) {
    return;
  }
  CGRect rect = [self.contentTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:anchorRow inSection:0]];
  CGFloat minimumY = -self.contentTableView.adjustedContentInset.top;
  CGFloat maximumY = MAX(minimumY,
                         self.contentTableView.contentSize.height - self.contentTableView.bounds.size.height + self.contentTableView.adjustedContentInset.bottom);
  CGFloat targetY = MIN(MAX(CGRectGetMinY(rect) - relativeY, minimumY), maximumY);
  [self.contentTableView setContentOffset:CGPointMake(self.contentTableView.contentOffset.x, targetY) animated:NO];
}

- (void)scrollSearchResultsToTop {
  [self.contentTableView layoutIfNeeded];
  CGPoint contentOffset = self.contentTableView.contentOffset;
  contentOffset.y = -self.contentTableView.adjustedContentInset.top;
  [self.contentTableView setContentOffset:contentOffset animated:NO];
}

- (void)captureSearchStartPosition {
  NSArray<NSIndexPath *> *visible = [self.contentTableView.indexPathsForVisibleRows sortedArrayUsingSelector:@selector(compare:)];
  NSIndexPath *topIndexPath = visible.firstObject;
  if (!topIndexPath || topIndexPath.row >= self.renderedAccountIds.count) {
    return;
  }
  NSString *accountId = self.renderedAccountIds[topIndexPath.row];
  if (accountId.length == 0) {
    return;
  }
  self.searchStartAccountId = accountId;
  self.searchStartRelativeY = [self.contentTableView rectForRowAtIndexPath:topIndexPath].origin.y - self.contentTableView.contentOffset.y;
  self.searchStartContentOffsetX = self.contentTableView.contentOffset.x;
}

- (void)restoreSearchStartPositionIfNeeded {
  NSString *accountId = self.searchStartAccountId;
  self.searchStartAccountId = nil;
  if (accountId.length == 0) {
    return;
  }
  __block NSInteger row = NSNotFound;
  [[self displayedMembers] enumerateObjectsUsingBlock:^(NETeamMemberInfoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
    NSString *modelAccountId = model.teamMember.accountId ?: model.nimUser.user.accountId;
    if ([modelAccountId isEqualToString:accountId]) {
      row = (NSInteger)idx;
      *stop = YES;
    }
  }];
  if (row == NSNotFound) {
    return;
  }
  CGRect rect = [self.contentTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  CGFloat minimumY = -self.contentTableView.adjustedContentInset.top;
  CGFloat maximumY = MAX(minimumY,
                         self.contentTableView.contentSize.height - self.contentTableView.bounds.size.height + self.contentTableView.adjustedContentInset.bottom);
  CGFloat targetY = MIN(MAX(CGRectGetMinY(rect) - self.searchStartRelativeY, minimumY), maximumY);
  [self.contentTableView setContentOffset:CGPointMake(self.searchStartContentOffsetX, targetY) animated:NO];
}

- (void)updateMemberLoadStatus {
  CGFloat width = self.contentTableView.bounds.size.width;
  if (self.viewModel.isLoadingMembers) {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    indicator.color = [self memberLoadStatusTintColor];
    indicator.center = CGPointMake(CGRectGetMidX(footer.bounds), CGRectGetMidY(footer.bounds));
    indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [indicator startAnimating];
    [footer addSubview:indicator];
    self.contentTableView.tableFooterView = footer;
  } else if (self.viewModel.memberLoadError) {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 52)];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = footer.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.tintColor = [self memberLoadStatusTintColor];
    [button setTitleColor:[self memberLoadStatusTintColor] forState:UIControlStateNormal];
    [button setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
    [button setTitle:NETeamUIKitErrorToast(self.viewModel.memberLoadError) forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    button.titleLabel.numberOfLines = 2;
    [button addTarget:self action:@selector(retryMemberLoad) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:button];
    self.contentTableView.tableFooterView = footer;
  } else {
    self.contentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 12)];
  }
}

- (void)retryMemberLoad {
  if (self.teamId.length == 0) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.viewModel getTeamInfo:self.teamId completion:^(__unused NETeamInfoModel * _Nullable model, NSError * _Nullable error) {
    if (error) {
      [weakSelf showToast:NETeamUIKitErrorToast(error)];
    }
    [weakSelf didNeedRefreshUI];
  }];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
  }
  return _backView;
}

- (TeamMembersViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamMembersViewModel alloc] init];
  }
  return _viewModel;
}

- (UITextField *)searchTextField {
  if (!_searchTextField) {
    _searchTextField = [[NESingleLineTextField alloc] init];
    _searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _searchTextField.placeholder = commonLocalizable(@"search");
    _searchTextField.clearButtonMode = UITextFieldViewModeAlways;
    _searchTextField.textColor = UIColor.ne_greyText;
    _searchTextField.font = [UIFont systemFontOfSize:14.0];
    _searchTextField.backgroundColor = UIColor.ne_backcolor;
    UIButton *clearButton = [_searchTextField valueForKey:@"_clearButton"];
    clearButton.accessibilityIdentifier = @"id.clear";
    _searchTextField.accessibilityIdentifier = @"id.search";
  }
  return _searchTextField;
}

- (UITableView *)contentTableView {
  if (!_contentTableView) {
    _contentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentTableView.backgroundColor = UIColor.clearColor;
    _contentTableView.dataSource = self;
    _contentTableView.delegate = self;
    _contentTableView.separatorColor = UIColor.clearColor;
    _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _contentTableView.sectionHeaderHeight = 12.0;
    _contentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 12.0)];
    _contentTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _contentTableView.estimatedRowHeight = 0.0;
    _contentTableView.estimatedSectionHeaderHeight = 0.0;
    _contentTableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _contentTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _contentTableView;
}

- (UIImageView *)searchIconImageView {
  if (!_searchIconImageView) {
    _searchIconImageView = [[UIImageView alloc] init];
    _searchIconImageView.image = [coreLoader() loadImage:@"textField_search_icon"];
    _searchIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchIconImageView;
}

@end
