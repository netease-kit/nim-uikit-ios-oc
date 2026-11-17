// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactViewController.h"
#import <objc/runtime.h>
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NESubscribeManager.h>

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/UITableViewCell+NEAdaptiveSelection.h>
#import "NEBaseContactTableViewCell.h"
#import "ContactSectionView.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import "NEBaseFindFriendViewController.h"
#import <NEChatKit/NEChatKit.h>

static NSString * const NEContactValidationMessageRouterCompat3 = @"imkit://contact/verifyList.page";
static NSString * const NEContactBlackListRouterCompat3 = @"imkit://contact/blackList.page";
static NSString * const NEContactTeamListRouterCompat3 = @"imkit://contact/teamList.page";
static NSString * const NEContactPersonRouterCompat = @"imkit://contact/person.page";
static NSString * const NEContactComputerRouterCompat = @"imkit://contact/computer.page";
static NSString * const NEContactUserInfoPageRouterCompat4 = @"imkit://contact/userInfo.page";
static NSString * const NESearchContactPageRouterCompat = @"imkit://search/search.page";

@interface NEBaseContactViewController () <NENavigationBarHeightProviding>
/// 当前查看好友的选中键（cell 类型|路由|账号），是左侧高亮的唯一权威状态。
@property (nonatomic, copy, nullable) NSString *adaptiveSelectedContactKey;

@property (nonatomic, assign) NSInteger lastTitleIndex;
@property (nonatomic, strong, nullable) NSLayoutConstraint *navigationViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyTopViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyTopViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyBottomViewHeightAnchor;
@property (nonatomic, assign) BOOL networkBroken;

@end

@implementation NEBaseContactViewController

#pragma mark - Init

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nil bundle:nil];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self ne_refreshNavigationBarHeightIfNeeded];
  if (self.navigationController.viewControllers.count > 0) {
    UIViewController *root = self.navigationController.viewControllers[0];
    if ([root isKindOfClass:[NEBaseContactViewController class]]) {
      self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
  }

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    self.navigationController.navigationBarHidden = NO;
  } else {
    self.navigationController.navigationBarHidden = YES;
  }

  [self loadData];
  [self.viewModel getValidationMessage:nil];

  if ([ContactUIConfig shared].customController) {
    [ContactUIConfig shared].customController(self);
  }

  [self subscribeVisibleRows];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self showTitleBar];
  [self commonUI];

  __weak typeof(self) weakSelf = self;
  self.viewModel.delegate = self;
  self.viewModel.refresh = ^{
    [weakSelf didRefreshTable];
  };

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(clearValidationUnreadCount)
                                               name:NENotificationClearValidationMessageUnreadCount
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loadData)
                                               name:NENotificationFriendCacheInit
                                             object:nil];
  [[IMKitClient instance] addLoginListener:self];
}

#pragma mark - clearValidationUnreadCount

- (void)clearValidationUnreadCount {
  self.viewModel.unreadCount = 0;
}

///
- (CGFloat)contactNavigationBarHeight {
  CGFloat height = NEUIKitNavigationAndStatusHeightForView(self.view);
  if (NEAdaptiveDeviceGate.adaptiveHostActive) {
    height += 2.0;
  }
  return height;
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self ne_refreshNavigationBarHeightIfNeeded];
}

#pragma mark - NENavigationBarHeightProviding

- (CGFloat)ne_navigationBarHeight {
  return [self contactNavigationBarHeight];
}

- (void)ne_applyNavigationBarHeight:(CGFloat)height {
  if (!self.navigationViewHeightAnchor || !self.navigationView.superview ||
      self.navigationView.isHidden) {
    return;
  }
  if (fabs(self.navigationViewHeightAnchor.constant - height) < 0.5) {
    return;
  }
  self.navigationViewHeightAnchor.constant = height;
  // 同步内容起点：showTitleBar 内部会用 view 安全区重算 topConstant。
  [self showTitleBar];
  self.bodyTopViewTopAnchor.constant = self.topConstant;
  [self.view setNeedsLayout];
}

#pragma mark - showTitleBar

- (void)showTitleBar {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    self.navigationView.hidden = YES;
    self.topConstant = 0;
    if ([ContactUIConfig shared].showTitleBar) {
      self.navigationController.navigationBarHidden = NO;
    } else {
      self.navigationController.navigationBarHidden = YES;
      self.topConstant += NEUIKitStatusBarHeightForView(self.view);
    }
  } else {
    self.navigationController.navigationBarHidden = YES;
    if ([ContactUIConfig shared].showTitleBar) {
      self.navigationView.hidden = NO;
      self.topConstant = 44.0;
    } else {
      self.navigationView.hidden = YES;
      self.topConstant = 0;
    }
    self.topConstant += NEUIKitStatusBarHeightForView(self.view);
  }
}

#pragma mark - commonUI

- (void)commonUI {
  [self.view addSubview:self.navigationView];
  [self.view addSubview:self.bodyTopView];
  [self.view addSubview:self.bodyView];
  [self.view addSubview:self.bodyBottomView];

  [NSLayoutConstraint activateConstraints:@[
    [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.navigationView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.navigationView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
  self.navigationViewHeightAnchor =
      [self.navigationView.heightAnchor constraintEqualToConstant:[self contactNavigationBarHeight]];
  self.navigationViewHeightAnchor.active = YES;

  self.bodyTopViewTopAnchor =
      [self.bodyTopView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  [NSLayoutConstraint activateConstraints:@[
    self.bodyTopViewTopAnchor,
    [self.bodyTopView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyTopView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
  self.bodyTopViewHeightAnchor = [self.bodyTopView.heightAnchor constraintEqualToConstant:self.bodyTopViewHeight];
  self.bodyTopViewHeightAnchor.active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.bodyView.topAnchor constraintEqualToAnchor:self.bodyTopView.bottomAnchor],
    [self.bodyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bodyView.bottomAnchor constraintEqualToAnchor:self.bodyBottomView.topAnchor],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.bodyBottomView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.bodyBottomView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyBottomView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
  self.bodyBottomViewHeightAnchor = [self.bodyBottomView.heightAnchor constraintEqualToConstant:self.bodyBottomViewHeight];
  self.bodyBottomViewHeightAnchor.active = YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (self.navigationController &&
      [self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] &&
      gestureRecognizer == self.navigationController.interactivePopGestureRecognizer &&
      self.navigationController.visibleViewController == self.navigationController.viewControllers.firstObject) {
    return NO;
  }
  return YES;
}

#pragma mark - loadData

- (void)loadData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadData:nil completion:^(NSError * _Nullable error, NSInteger userSectionCount) {
    if (error == nil) {
      if ([weakSelf.delegate respondsToSelector:@selector(onDataLoaded)]) {
        [weakSelf.delegate onDataLoaded];
      }
      [weakSelf didRefreshTable];
    }
  }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.viewModel.contactSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section >= (NSInteger)self.viewModel.contactSections.count) {
    return 0;
  }
  return self.viewModel.contactSections[section].contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section >= (NSInteger)self.viewModel.contactSections.count) {
    return [[UITableViewCell alloc] init];
  }
  ContactSection *contactSection = self.viewModel.contactSections[indexPath.section];
  if (indexPath.row >= (NSInteger)contactSection.contacts.count) {
    return [[UITableViewCell alloc] init];
  }
  ContactInfo *info = contactSection.contacts[indexPath.row];

  NSString *reusedId = [NSString stringWithFormat:@"%ld", (long)info.contactCellType];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusedId forIndexPath:indexPath];

  // 把模型对应的 key 存到 cell 上，选中高亮恢复时按 cell 自己的 key 判断，
  NSString *adaptiveKey = [self adaptiveKeyForInfo:info];
  objc_setAssociatedObject(cell, (__bridge const void *)@"ne_adaptiveContactKey", adaptiveKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
  // 选中态在渲染时按稳定 key（类型|路由|账号）决定：
  // 验证消息/黑名单/我的群聊等表头行没有 accountId，只有 key 才能点亮。
  BOOL shouldSelect = self.listSelectionBackgroundColor != nil &&
                      self.adaptiveSelectedContactKey.length > 0 &&
                      [adaptiveKey isEqualToString:self.adaptiveSelectedContactKey];

  if ([cell isKindOfClass:[NEBaseContactTableViewCell class]]) {
    NEBaseContactTableViewCell *c = (NEBaseContactTableViewCell *)cell;
    [c setModel:info];

    if ([IMKitConfigCenter shared].enableOnlineStatus) {
      if (indexPath.section != 0) {
        NSString *accountId = info.user.user.accountId;
        if (accountId) {
          NSNumber *onlineValue = self.viewModel.onlineStatusDic[accountId];
          BOOL online = onlineValue ? [onlineValue boolValue] : NO;
          info.isOnline = online;
          [c setOnline:online];
        }
      }
    }

    NSInteger unreadCount = self.viewModel.unreadCount;
    if (indexPath.section == 0 && indexPath.row == 0 && unreadCount > 0) {
      c.redAngleView.hidden = NO;
      c.redAngleView.text = unreadCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)unreadCount];
    } else {
      c.redAngleView.hidden = YES;
    }
  }

  // cell 复用可能带着上一次的选中底色：先还原再记录原始底色，
  // 然后只覆盖底色、不改变 selectionStyle；按下期间不会出现系统高亮。
  [cell ne_applyAdaptiveSelectionColor:nil selected:NO];
  [cell ne_captureAdaptiveSelectionBackground];
  [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor selected:shouldSelect];
  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section >= (NSInteger)self.viewModel.contactSections.count) {
    return nil;
  }

  ContactSectionView *sectionView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([ContactSectionView class])];
  sectionView.titleLabel.text = self.viewModel.contactSections[section].initial;
  return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section >= (NSInteger)self.viewModel.contactSections.count) {
    return 0;
  }

  if (self.viewModel.contactSections[section].initial.length == 0) {
    return 0;
  }
  return UITableViewAutomaticDimension;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  return self.viewModel.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  for (NSInteger i = 0; i < (NSInteger)self.viewModel.contactSections.count; i++) {
    ContactSection *t = self.viewModel.contactSections[i];
    if ([t.initial isEqualToString:title]) {
      self.lastTitleIndex = i;
      return i;
    }
  }
  return self.lastTitleIndex;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 52;
}

#pragma mark - UITableViewDelegate

- (NSString *)adaptiveKeyForInfo:(ContactInfo *)info {
  NSString *accountId = info.user.user.accountId ?: @"";
  return [NSString stringWithFormat:@"%ld|%@|%@", (long)info.contactCellType, info.router ?: @"", accountId];
}

- (void)setListSelectionBackgroundColor:(UIColor *)listSelectionBackgroundColor {
  _listSelectionBackgroundColor = listSelectionBackgroundColor;
  [self refreshAdaptiveSelectionTint];
}

- (BOOL)isCellSelectedInAdaptiveList:(UITableViewCell *)cell {
  if (!self.listSelectionBackgroundColor || self.adaptiveSelectedContactKey.length == 0) {
    return NO;
  }
  NSString *key = objc_getAssociatedObject(cell, (__bridge const void *)@"ne_adaptiveContactKey");
  return [key isKindOfClass:[NSString class]] &&
         [key isEqualToString:self.adaptiveSelectedContactKey];
}

/// 唯一权威状态是 adaptiveSelectedContactKey：每次按它重算所有可见 cell 的底色，
/// 不依赖 UITableView 的选中集合（程序化 selectRow 不会取消其它行）。
- (void)refreshAdaptiveSelectionTint {
  if (!self.isViewLoaded) {
    return;
  }
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor
                                selected:[self isCellSelectedInAdaptiveList:cell]];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  if (indexPath.section >= (NSInteger)self.viewModel.contactSections.count) {
    return;
  }
  ContactSection *contactSection = self.viewModel.contactSections[indexPath.section];
  if (indexPath.row >= (NSInteger)contactSection.contacts.count) {
    return;
  }
  ContactInfo *info = contactSection.contacts[indexPath.row];
  self.adaptiveSelectedContactKey = [self adaptiveKeyForInfo:info];
  [self refreshAdaptiveSelectionTint];

  if (info.contactCellType == ContactCellTypeContactOthers) {
    if ([ContactUIConfig shared].headerItemClick) {
      [ContactUIConfig shared].headerItemClick(self, info, indexPath);
      return;
    }

    if ([info.router isEqualToString:NEContactValidationMessageRouterCompat3]) {
      [[Router shared] use:NEContactValidationMessageRouterCompat3
                parameters:@{@"nav": self.navigationController ?: [NSNull null], @"animated": @NO}
                   closure:nil];
    } else if ([info.router isEqualToString:NEContactBlackListRouterCompat3]) {
      [[Router shared] use:NEContactBlackListRouterCompat3
                parameters:@{@"nav": self.navigationController ?: [NSNull null], @"animated": @NO}
                   closure:nil];
    } else if ([info.router isEqualToString:NEContactTeamListRouterCompat3]) {
      [[Router shared] use:NEContactTeamListRouterCompat3
                parameters:@{@"nav": self.navigationController ?: [NSNull null], @"animated": @NO}
                   closure:nil];
    } else if ([info.router isEqualToString:NEContactPersonRouterCompat]) {
      // break
    } else if ([info.router isEqualToString:NEContactComputerRouterCompat]) {
      // break
    } else {
      if (info.router.length > 0) {
        [[Router shared] use:info.router
                  parameters:@{@"nav": self.navigationController ?: [NSNull null], @"animated": @NO}
                     closure:nil];
      }
    }
  } else {
    if ([ContactUIConfig shared].friendItemClick) {
      [ContactUIConfig shared].friendItemClick(self, info, indexPath);
      return;
    }

    [[Router shared] use:NEContactUserInfoPageRouterCompat4
              parameters:@{@"nav": self.navigationController ?: [NSNull null],
                           @"user": info.user ?: [NSNull null],
                           @"animated": @NO}
                 closure:nil];
  }
}

#pragma mark - subscribeVisibleRows

- (void)subscribeVisibleRows {
  if (![IMKitConfigCenter shared].enableOnlineStatus) {
    return;
  }

  if (![[NESubscribeManager shared] outOfLimit]) {
    return;
  }

  NSArray<NSIndexPath *> *indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows;
  if (indexPathsForVisibleRows) {
    NSMutableArray<NSString *> *accountIds = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPathsForVisibleRows) {
      if (indexPath.section != 0) {
        ContactInfo *info = self.viewModel.contactSections[indexPath.section].contacts[indexPath.row];
        NSString *accountId = info.user.user.accountId;
        if (accountId) {
          if (![[NESubscribeManager shared] hasSubscribe:accountId]) {
            [accountIds addObject:accountId];
          }
        }
      }
    }

    if (accountIds.count > 0) {
      [[NESubscribeManager shared] subscribeUsersOnlineState:accountIds completion:^(NSError * _Nullable error) {
      }];
    }
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [self subscribeVisibleRows];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self subscribeVisibleRows];
}

#pragma mark - didRefreshTable

- (void)didRefreshTable {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
    self.emptyView.hidden = (self.viewModel.contactSections.count > 1);
    // 每次数据刷新都会重建 cell，重载后按唯一选中 key 重新贴一次底色。
    [self refreshAdaptiveSelectionTint];
  });
}

- (void)reloadTableView {
  [self didRefreshTable];
}

#pragma mark - Extension Methods

- (void)initSystemNav {
  self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (NEBaseFindFriendViewController *)getFindFriendViewController {
  return [[NEBaseFindFriendViewController alloc] init];
}

- (void)goToFindFriend {
  NEBaseFindFriendViewController *findFriendController = [self getFindFriendViewController];
  [self.navigationController pushViewController:findFriendController animated:NO];
}

- (void)searchContact {
  [[Router shared] use:NESearchContactPageRouterCompat
            parameters:@{@"nav": self.navigationController ?: [NSNull null],
                         @"animated": @NO}
               closure:nil];
}

#pragma mark - TabNavigationViewDelegate

- (void)searchAction {
  if ([ContactUIConfig shared].titleBarRight2Click) {
    [ContactUIConfig shared].titleBarRight2Click(self);
    return;
  }
  [self searchContact];
}

- (void)didClickAddBtn {
  if ([ContactUIConfig shared].titleBarRightClick) {
    [ContactUIConfig shared].titleBarRightClick(self);
    return;
  }
  [self goToFindFriend];
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
  if (status == V2NIM_CONNECT_STATUS_WAITING) {
    self.networkBroken = YES;
  }

  if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.networkBroken) {
    self.networkBroken = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakSelf.viewModel.onlineStatusDic removeAllObjects];
      [weakSelf.viewModel subscribeOnlineStatus];
      [weakSelf subscribeVisibleRows];
    });
  }
}

#pragma mark - Property Setters

- (void)setBodyTopViewHeight:(CGFloat)bodyTopViewHeight {
  _bodyTopViewHeight = bodyTopViewHeight;
  self.bodyTopViewHeightAnchor.constant = bodyTopViewHeight;
  self.bodyTopView.hidden = (bodyTopViewHeight <= 0);
}

- (void)setBodyBottomViewHeight:(CGFloat)bodyBottomViewHeight {
  _bodyBottomViewHeight = bodyBottomViewHeight;
  self.bodyBottomViewHeightAnchor.constant = bodyBottomViewHeight;
  self.bodyBottomView.hidden = (bodyBottomViewHeight <= 0);
}

#pragma mark - Lazy Init

- (NSMutableDictionary<NSNumber *, Class> *)cellRegisterDic {
  if (!_cellRegisterDic) {
    _cellRegisterDic = [NSMutableDictionary dictionary];
  }
  return _cellRegisterDic;
}

- (TabNavigationView *)navigationView {
  if (!_navigationView) {
    _navigationView = [[TabNavigationView alloc] initWithFrame:CGRectZero];
    _navigationView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationView.delegate = self;

    if ([ContactUIConfig shared].titleBarRightRes) {
      [_navigationView.addBtn setImage:[ContactUIConfig shared].titleBarRightRes forState:UIControlStateNormal];
    }
    if ([ContactUIConfig shared].titleBarRight2Res) {
      [_navigationView.searchBtn setImage:[ContactUIConfig shared].titleBarRight2Res forState:UIControlStateNormal];
    }
  }
  return _navigationView;
}

- (UIView *)bodyTopView {
  if (!_bodyTopView) {
    _bodyTopView = [[UIView alloc] init];
    _bodyTopView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyTopView.backgroundColor = [UIColor clearColor];
  }
  return _bodyTopView;
}

- (UIView *)bodyView {
  if (!_bodyView) {
    _bodyView = [[UIView alloc] init];
    _bodyView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyView.backgroundColor = [UIColor clearColor];
    [_bodyView addSubview:self.contentView];

    [NSLayoutConstraint activateConstraints:@[
      [self.contentView.topAnchor constraintEqualToAnchor:_bodyView.topAnchor],
      [self.contentView.leftAnchor constraintEqualToAnchor:_bodyView.leftAnchor],
      [self.contentView.rightAnchor constraintEqualToAnchor:_bodyView.rightAnchor],
      [self.contentView.bottomAnchor constraintEqualToAnchor:_bodyView.bottomAnchor],
    ]];
  }
  return _bodyView;
}

- (UIView *)contentView {
  if (!_contentView) {
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.backgroundColor = [UIColor clearColor];
    [_contentView addSubview:self.tableView];
    [_contentView addSubview:self.emptyView];

    [NSLayoutConstraint activateConstraints:@[
      [self.tableView.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
      [self.tableView.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
      [self.tableView.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
      [self.tableView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.emptyView.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
      [self.emptyView.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
      [self.emptyView.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:[UIScreen mainScreen].bounds.size.width / 2],
      [self.emptyView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
    ]];
  }
  return _contentView;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.sectionFooterHeight = 0;
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

- (NEEmptyDataView *)emptyView {
  if (!_emptyView) {
    _emptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                    content:contactLocalizable(@"no_friend")
                                                      frame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyView.userInteractionEnabled = NO;
    _emptyView.backgroundColor = [UIColor clearColor];
    _emptyView.hidden = NO;
  }
  return _emptyView;
}

- (UIView *)bodyBottomView {
  if (!_bodyBottomView) {
    _bodyBottomView = [[UIView alloc] init];
    _bodyBottomView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyBottomView.backgroundColor = [UIColor clearColor];
  }
  return _bodyBottomView;
}

@end
