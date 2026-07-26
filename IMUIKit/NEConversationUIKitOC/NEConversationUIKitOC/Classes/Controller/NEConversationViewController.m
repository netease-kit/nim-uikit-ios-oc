// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationViewController.h"
#import "NEBaseScanQRViewController.h"
#import "NEConversationPopListView.h"
#import "ConversationViewModel.h"
#import "NEConversationListModel.h"
#import "NEConversationListCell.h"
#import "ConversationUIConfig.h"
#import <NEChatKit/NEChatKitOC.h>
@import NECommonUIKitOC;
#import <NECommonUIKitOC/FunSearchView.h>
#import <NEChatKit/NEAIUserModel.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NECoreIM2Constant.h>

#import <NEChatKit/NEConstant.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/NESubscribeManager.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NIMSDK/V2NIMConversationEnum.h>
#import <MJRefresh/MJRefresh.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <objc/message.h>

static NSString * const kCellReuseId = @"NEConversationListCell";
static NSString * const kStickTopCellReuseId = @"NEConversationStickTopCell";
static NSString * const NEConversationContactUserSelectRouter = @"imkit://contact/selector.page";
static NSString * const NEConversationContactFusionSelectRouter = @"imkit://contact/fusionselector.page";
static NSString * const NEConversationContactSelectedUsersRouter = @"imkit://contact.selectUser.page";
static NSString * const NEConversationTeamCreateDiscussRouter = @"imkit://team.create.discuss";
static NSString * const NEConversationTeamCreateSeniorRouter = @"imkit://team.create.senior";
static NSString * const NEConversationTeamCreateDiscussResultRouter = @"imkit://team.create.discuss.result";
static NSString * const NEConversationTeamCreateSeniorResultRouter = @"imkit://team.create.senior.result";

static BOOL NEConversationIsNormalStyle(void);

@interface NEConversationStickTopCell : UICollectionViewCell
- (void)configure:(nullable NEAIUserModel *)model;
@end

@interface NEConversationStickTopCell ()
@property (nonatomic, strong) NEUserHeaderView *headImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@end

@implementation NEConversationStickTopCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self.contentView addSubview:self.headImageView];
    [self.contentView addSubview:self.nameLabel];
    BOOL isNormalStyle = NEConversationIsNormalStyle();
    CGFloat imageSize = isNormalStyle ? 42.0 : 48.0;
    self.headImageView.layer.cornerRadius = isNormalStyle ? 21.0 : 4.0;
    [NSLayoutConstraint activateConstraints:@[
      [self.headImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
      [self.headImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0],
      [self.headImageView.widthAnchor constraintEqualToConstant:imageSize],
      [self.headImageView.heightAnchor constraintEqualToConstant:imageSize],
      [self.nameLabel.topAnchor constraintEqualToAnchor:self.headImageView.bottomAnchor constant:6.0],
      [self.nameLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
      [self.nameLabel.widthAnchor constraintEqualToConstant:66.0],
    ]];
  }
  return self;
}

- (void)configure:(NEAIUserModel *)model {
  V2NIMAIUser *user = model.aiUser;
  if (user == nil) {
    self.nameLabel.text = nil;
    return;
  }

  NSString *displayName = user.name.length > 0 ? user.name : (user.accountId ?: @"");
  NSString *shortName = displayName.length > 2 ? [displayName substringFromIndex:displayName.length - 2] : displayName;
  NSString *accountId = user.accountId ?: @"";
  [self.headImageView configHeadData:user.avatar name:shortName uid:accountId];
  self.nameLabel.text = displayName;
}

- (NEUserHeaderView *)headImageView {
  if (!_headImageView) {
    _headImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _headImageView.clipsToBounds = YES;
    _headImageView.titleLabel.textColor = UIColor.whiteColor;
    _headImageView.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
  }
  return _headImageView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    _nameLabel.textColor = [UIColor ne_greyText];
  }
  return _nameLabel;
}

@end

/// 导航栏高度（状态栏 + 44pt，对齐 Swift NEConstant.navigationAndStatusHeight）
static CGFloat NENavigationAndStatusHeight(void) {
  return NEConstant.navigationAndStatusHeight;
}

static NECommonLoader *NEConversationLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:NSClassFromString(@"NEConversationViewController") ?: [NSObject class]];
  });
  return loader;
}

static NSString *NEConversationLocalizable(NSString *key) {
  return [NEConversationLoader() localizable:key];
}

static BOOL NEConversationIsNormalStyle(void) {
  Class styleManagerClass = NSClassFromString(@"NEStyleManager");
  SEL instanceSelector = NSSelectorFromString(@"instance");
  SEL isNormalStyleSelector = NSSelectorFromString(@"isNormalStyle");
  if (styleManagerClass &&
      [styleManagerClass respondsToSelector:instanceSelector]) {
    id manager = ((id (*)(id, SEL))objc_msgSend)(styleManagerClass, instanceSelector);
    if (manager && [manager respondsToSelector:isNormalStyleSelector]) {
      return ((BOOL (*)(id, SEL))objc_msgSend)(manager, isNormalStyleSelector);
    }
  }
  return YES;
}

static CGFloat NEConversationBrokenNetworkHeight(void) {
  return NEConversationIsNormalStyle() ? 36.0 : 48.0;
}

@interface NEConversationViewController () <ConversationViewModelDelegate, TabNavigationViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NEIMKitClientListener>
@property (nonatomic, strong) NSLayoutConstraint *bodyTopViewHeightAnchor;
@property (nonatomic, strong) NSLayoutConstraint *contentViewTopAnchor;
@property (nonatomic, strong) NSLayoutConstraint *brokenNetworkViewHeightAnchor;
@property (nonatomic, assign) BOOL networkBroken;
// 容器视图（对齐 Swift bodyTopView/bodyView）
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UICollectionView *stickTopCollectionView;
@property (nonatomic, strong) UIView *pinUserDividerLine;
@property (nonatomic, strong) NEConversationBasePopListView *popListView;
@property (nonatomic, strong) FunSearchView *searchView;
@end

@implementation NEConversationViewController

static NSString * const NEConversationContactAddFriendRouter = @"imkit://contact/addFriend.page";
static NSString * const NEConversationTeamJoinTeamRouter = @"imkit://team/joinTeam.page";
static NSString * const NEConversationContactAIRobotBindRouter = @"imkit://contact/aiRobotBind.page";
static NSString * const NEConversationSearchContactPageRouter = @"imkit://search/search.page";
static NSString * const NEConversationPushTeamChatVCRouter = @"imkit://chat/teamChat.page";
static NSString * const NEConversationPushP2pChatVCRouter = @"imkit://chat/p2pChat.page";

#pragma mark - 初始化

- (instancetype)initWithDataSourceType:(NEConversationDataSourceType)type {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _dataSourceType = type;
    _cellRowHeight = 62.0;
    _isRequestedData = NO;
    _networkBroken = NO;
    _bodyTopViewHeight = 0.0;

    if (type == NEConversationDataSourceTypeCloud) {
      _viewModel = [ConversationViewModel cloudViewModel];
    } else {
      _viewModel = [ConversationViewModel localViewModel];
    }
  }
  return self;
}

+ (instancetype)cloudController {
  return [[NEConversationViewController alloc] initWithDataSourceType:NEConversationDataSourceTypeCloud];
}

+ (instancetype)localController {
  return [[NEConversationViewController alloc] initWithDataSourceType:NEConversationDataSourceTypeLocal];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[IMKitClient instance] removeLoginListener:self];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = NEConversationIsNormalStyle() ? UIColor.whiteColor : [NEConstant hexRGB:0xEDEDED];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationChangeLanguage
                                             object:nil];
  [self setupSubviews];
  [self initialConfig];
  [[IMKitClient instance] addLoginListener:self];
  [self requestData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // 隐藏系统导航栏，使用自定义 TabNavigationView
  [self.navigationController setNavigationBarHidden:YES animated:NO];

  if (self.isRequestedData) {
    [self refreshAIUserDisplayState];
    [self reloadTableView];
  }

  __weak typeof(self) weakSelf = self;
  [NEChatDetectNetworkTool.shareInstance netWorkReachability:^(NEReachabilityStatus status) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    BOOL notReachable = (status == NEReachabilityStatusNotReachable);
    self.brokenNetworkView.hidden = !notReachable;
    self.contentViewTopAnchor.constant = notReachable ? NEConversationBrokenNetworkHeight() : 0.0;
  }];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.navigationController setNavigationBarHidden:NO animated:NO];
}

#pragma mark - Setup

- (void)setupSubviews {
  CGFloat navH = NENavigationAndStatusHeight();

  // ── navigationView（自定义标题栏）
  [self.view addSubview:self.navigationView];
  [NSLayoutConstraint activateConstraints:@[
    [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.navigationView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.navigationView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.navigationView.heightAnchor constraintEqualToConstant:navH],
  ]];

  // ── bodyTopView（顶部自定义区域）
  self.bodyTopView = [[UIView alloc] init];
  self.bodyTopView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bodyTopView.backgroundColor = [UIColor clearColor];
  self.bodyTopView.hidden = YES;
  [self.view addSubview:self.bodyTopView];
  [NSLayoutConstraint activateConstraints:@[
    [self.bodyTopView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    [self.bodyTopView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyTopView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
  self.bodyTopViewHeightAnchor = [self.bodyTopView.heightAnchor constraintEqualToConstant:self.bodyTopViewHeight];
  self.bodyTopViewHeightAnchor.active = YES;

  // ── bodyView（导航栏以下区域）
  self.bodyView = [[UIView alloc] init];
  self.bodyView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bodyView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.bodyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.bodyView.topAnchor constraintEqualToAnchor:self.bodyTopView.bottomAnchor],
    [self.bodyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bodyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  // ── brokenNetworkView（网络断开提示，覆盖在 bodyView 顶部）
  [self.bodyView addSubview:self.brokenNetworkView];
  self.brokenNetworkViewHeightAnchor = [self.brokenNetworkView.heightAnchor constraintEqualToConstant:NEConversationBrokenNetworkHeight()];
  [NSLayoutConstraint activateConstraints:@[
    [self.brokenNetworkView.topAnchor constraintEqualToAnchor:self.bodyView.topAnchor],
    [self.brokenNetworkView.leftAnchor constraintEqualToAnchor:self.bodyView.leftAnchor],
    [self.brokenNetworkView.rightAnchor constraintEqualToAnchor:self.bodyView.rightAnchor],
  ]];
  self.brokenNetworkViewHeightAnchor.active = YES;

  // ── contentView（tableView 容器）
  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentView.backgroundColor = [UIColor clearColor];
  [self.bodyView addSubview:self.contentView];
  self.contentViewTopAnchor = [self.contentView.topAnchor constraintEqualToAnchor:self.bodyView.topAnchor];
  self.contentViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.contentView.leftAnchor constraintEqualToAnchor:self.bodyView.leftAnchor],
    [self.contentView.rightAnchor constraintEqualToAnchor:self.bodyView.rightAnchor],
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.bodyView.bottomAnchor],
  ]];

  // ── tableView
  [self.contentView addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  // ── emptyView（叠在 tableView 上方）
  [self.contentView addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:100],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
  ]];

  // 注册 Cell
  [self.tableView registerClass:[NEConversationListCell class] forCellReuseIdentifier:kCellReuseId];
  [self.stickTopCollectionView registerClass:[NEConversationStickTopCell class] forCellWithReuseIdentifier:kStickTopCellReuseId];

  if (NEConversationIsNormalStyle()) {
    self.cellRowHeight = 62.0;
    CGFloat stickTopHeight = 181.0 - NENavigationAndStatusHeight();
    self.stickTopCollectionView.frame = CGRectMake(10.0, 0.0, CGRectGetWidth(self.view.frame) - 20.0, stickTopHeight);
    self.pinUserDividerLine.frame = CGRectMake(-10.0, stickTopHeight - 1.0, CGRectGetWidth(self.view.frame) + 20.0, 1.0);
  } else {
    self.cellRowHeight = 72.0;
    self.bodyTopViewHeight = 60.0;
    self.bodyTopView.backgroundColor = [NEConstant hexRGB:0xEDEDED];
    self.navigationView.titleBarBottomLine.hidden = YES;
    self.stickTopCollectionView.frame = CGRectMake(4.0, 0.0, CGRectGetWidth(self.view.frame) - 8.0, 104.0);

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchAction)];
    tap.cancelsTouchesInView = NO;
    [self.searchView addGestureRecognizer:tap];
    [self.bodyTopView addSubview:self.searchView];
    [NSLayoutConstraint activateConstraints:@[
      [self.searchView.topAnchor constraintEqualToAnchor:self.bodyTopView.topAnchor constant:12.0],
      [self.searchView.leftAnchor constraintEqualToAnchor:self.bodyTopView.leftAnchor constant:8.0],
      [self.searchView.rightAnchor constraintEqualToAnchor:self.bodyTopView.rightAnchor constant:-8.0],
      [self.searchView.heightAnchor constraintEqualToConstant:36.0],
    ]];
  }

  // MJRefresh 上拉加载更多
  __weak typeof(self) weakSelf = self;
  self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
    [weakSelf loadMoreData];
  }];
}

- (void)initialConfig {
  self.viewModel.delegate = self;

  // 配置 navigationView
  ConversationUIConfig *config = ConversationUIConfig.shared;
  if (config.titleBarTitle.length > 0) {
    [self.navigationView.brandBtn setTitle:config.titleBarTitle forState:UIControlStateNormal];
  }
  if (config.titleBarTitleColor) {
    [self.navigationView.brandBtn setTitleColor:config.titleBarTitleColor forState:UIControlStateNormal];
  }
  self.navigationView.searchBtn.hidden = !config.showTitleBarRight2Icon;
  self.navigationView.addBtn.hidden    = !config.showTitleBarRightIcon;
  if (config.titleBarRightRes) {
    [self.navigationView.addBtn setImage:config.titleBarRightRes forState:UIControlStateNormal];
  }
  if (config.titleBarRight2Res) {
    [self.navigationView.searchBtn setImage:config.titleBarRight2Res forState:UIControlStateNormal];
  }
  self.navigationView.hidden = !config.showTitleBar;
  if (!NEConversationIsNormalStyle()) {
    self.navigationView.searchBtn.hidden = YES;
    self.navigationView.titleBarBottomLine.hidden = YES;
  }
  [self changeLanguage];

  if (config.customController) {
    config.customController(self);
  }
}

- (void)changeLanguage {
  ConversationUIConfig *config = ConversationUIConfig.shared;
  NSString *title = config.titleBarTitle.length > 0 ? config.titleBarTitle : commonLocalizable(@"appName");
  [self.navigationView.brandBtn setTitle:title forState:UIControlStateNormal];
  self.brokenNetworkView.contentLabel.text = commonLocalizable(@"network_error");
  [self.searchView.searchButton setTitle:commonLocalizable(@"search") forState:UIControlStateNormal];
  self.popListView = [self getPopListView];
}

#pragma mark - 数据

- (void)requestData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel getConversationListByPage:^(NSError * _Nullable error, NSNumber * _Nullable finished) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;

    self.isRequestedData = YES;
    [self.viewModel getAIUserList];

    // 数据加载完成后移除 footer（对齐 Swift）
    if (finished.boolValue && self.viewModel.syncFinished) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.mj_footer = nil;
      });
    }

    if (error) {
      [self showToast:error.localizedDescription ?: @""];
      self.emptyView.hidden = NO;
    } else {
      [self reloadTableView];
      [self.delegate onDataLoaded];
    }
  }];
}

- (void)loadMoreData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel getConversationListByPage:^(NSError * _Nullable error, NSNumber * _Nullable finished) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;

    self.isRequestedData = YES;

    if (finished.boolValue && self.viewModel.syncFinished) {
      [self.tableView.mj_footer endRefreshingWithNoMoreData];
      dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.mj_footer = nil;
      });
    } else {
      [self.tableView.mj_footer endRefreshing];
    }
    [self.delegate onDataLoaded];
    [self reloadTableView];
  }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.conversationListData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger row = indexPath.row;
  if (row >= (NSInteger)self.viewModel.conversationListData.count) {
    return [[UITableViewCell alloc] init];
  }
  NEConversationListModel *model = self.viewModel.conversationListData[row];
  return [self cellForRowAtModel:model indexPath:indexPath tableView:tableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return self.cellRowHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSInteger row = indexPath.row;
  if (row >= (NSInteger)self.viewModel.conversationListData.count) return;
  NEConversationListModel *model = self.viewModel.conversationListData[row];
  [self didSelectConversation:model atIndexPath:indexPath];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
  NSInteger row = indexPath.row;
  if (row >= (NSInteger)self.viewModel.conversationListData.count) return nil;
  NEConversationListModel *model = self.viewModel.conversationListData[row];
  return [self trailingActionsForModel:model atIndexPath:indexPath];
}

- (void)subscribeVisibleRows {
  if (![IMKitConfigCenter shared].enableOnlineStatus) {
    return;
  }

  if (![[NESubscribeManager shared] outOfLimit]) {
    return;
  }

  NSArray<NSIndexPath *> *indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows;
  if (indexPathsForVisibleRows.count == 0) {
    return;
  }

  NSMutableArray<NSString *> *accountIds = [NSMutableArray array];
  for (NSIndexPath *indexPath in indexPathsForVisibleRows) {
    if (indexPath.row >= (NSInteger)self.viewModel.conversationListData.count) {
      continue;
    }

    NEConversationListModel *model = self.viewModel.conversationListData[indexPath.row];
    if (model.conversationId.length == 0 ||
        [V2NIMConversationIdUtil conversationType:model.conversationId] != V2NIM_CONVERSATION_TYPE_P2P) {
      continue;
    }

    NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:model.conversationId];
    if (accountId.length > 0 && ![[NESubscribeManager shared] hasSubscribe:accountId]) {
      [accountIds addObject:accountId];
    }
  }

  if (accountIds.count > 0) {
    [[NESubscribeManager shared] subscribeUsersOnlineState:accountIds completion:^(NSError * _Nullable error) {
    }];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  [self subscribeVisibleRows];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self subscribeVisibleRows];
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
      [weakSelf subscribeVisibleRows];
    });
  }
}

#pragma mark - ConversationViewModelDelegate

- (void)reloadData {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self reloadTableView];
  });
}

- (void)reloadTableView {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.emptyView.hidden = (self.viewModel.conversationListData.count > 0);
    [self setupStickTopView];
    [self.tableView reloadData];
  });
}

- (void)loadMoreStateChange:(BOOL)finish {
  if (finish) {
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
  } else {
    [self.tableView.mj_footer endRefreshing];
  }
}

#pragma mark - TabNavigationViewDelegate

- (void)brandBtnClick {
  if (ConversationUIConfig.shared.titleBarLeftClick) {
    ConversationUIConfig.shared.titleBarLeftClick(self);
  }
}

- (void)didClickAddBtn {
  if (ConversationUIConfig.shared.titleBarRightClick) {
    ConversationUIConfig.shared.titleBarRightClick(self);
    return;
  }

  if (!self.navigationController) {
    return;
  }

  if (![IMKitConfigCenter shared].enableTeam) {
    [[Router shared] use:NEConversationContactAddFriendRouter
              parameters:@{
                @"nav": self.navigationController,
                @"animated": @YES,
              }
                 closure:nil];
    return;
  }
  self.popListView.itemDatas = [self getPopListItems];
  self.popListView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  [self.popListView removeSelf];
  [self.view addSubview:self.popListView];
}

- (NEConversationBasePopListView *)getPopListView {
  return NEConversationIsNormalStyle() ? [[NEConversationNormalPopListView alloc] initWithFrame:CGRectZero] : [[NEConversationFunPopListView alloc] initWithFrame:CGRectZero];
}

- (NSArray<NEConversationPopListItem *> *)getPopListItems {
  __weak typeof(self) weakSelf = self;
  BOOL isNormalStyle = NEConversationIsNormalStyle();
  NSMutableArray<NEConversationPopListItem *> *items = [NSMutableArray array];

  NEConversationPopListItem *addFriend = [[NEConversationPopListItem alloc] init];
  addFriend.showName = NEConversationLocalizable(@"add_friend");
  addFriend.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  addFriend.image = [NEConversationLoader() loadImage:isNormalStyle ? @"add_friend" : @"fun_add_friend"];
  addFriend.completion = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self.navigationController) {
      return;
    }
    [[Router shared] use:NEConversationContactAddFriendRouter
              parameters:@{
                @"nav": self.navigationController,
                @"animated": @NO,
              }
                 closure:nil];
  };
  [items addObject:addFriend];

  NEConversationPopListItem *joinTeam = [[NEConversationPopListItem alloc] init];
  joinTeam.showName = commonLocalizable(@"join_team");
  joinTeam.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  joinTeam.image = [NEConversationLoader() loadImage:isNormalStyle ? @"join_team" : @"fun_join_team"];
  joinTeam.completion = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self.navigationController) {
      return;
    }
    [[Router shared] use:NEConversationTeamJoinTeamRouter
              parameters:@{
                @"nav": self.navigationController,
                @"animated": @YES,
              }
                 closure:nil];
  };
  [items addObject:joinTeam];

  NEConversationPopListItem *createDiscuss = [[NEConversationPopListItem alloc] init];
  createDiscuss.showName = NEConversationLocalizable(@"create_discussion_group");
  createDiscuss.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  createDiscuss.image = [NEConversationLoader() loadImage:isNormalStyle ? @"create_discussion" : @"fun_create_discussion"];
  createDiscuss.completion = ^{
    [weakSelf createDiscussGroup];
  };
  [items addObject:createDiscuss];

  NEConversationPopListItem *createGroup = [[NEConversationPopListItem alloc] init];
  createGroup.showName = NEConversationLocalizable(@"create_senior_group");
  createGroup.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  createGroup.image = [NEConversationLoader() loadImage:isNormalStyle ? @"create_group" : @"fun_create_team"];
  createGroup.completion = ^{
    [weakSelf createSeniorGroup];
  };
  [items addObject:createGroup];

  NEConversationPopListItem *scanQR = [[NEConversationPopListItem alloc] init];
  scanQR.showName = NEConversationLocalizable(@"scan_qr");
  scanQR.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  scanQR.image = [NEConversationLoader() loadImage:isNormalStyle ? @"scan_qr" : @"fun_scan_qr"];
  scanQR.completion = ^{
    [weakSelf openScanQR];
  };
  [items addObject:scanQR];

  return items;
}

- (void)openScanQR {
  if (!self.navigationController) {
    return;
  }

  NEBaseScanQRViewController *scanVC = [[NEBaseScanQRViewController alloc] init];
  __weak typeof(self) weakSelf = self;
  scanVC.onScanResult = ^BOOL(NSString *result) {
    return [weakSelf handleQRScanResult:result];
  };
  [self.navigationController pushViewController:scanVC animated:YES];
}

- (BOOL)handleQRScanResult:(NSString *)result {
  if (result.length == 0 || !self.navigationController) {
    return NO;
  }

  NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
  if (data != nil) {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([dict isKindOfClass:[NSDictionary class]] && [dict[@"qrCode"] isKindOfClass:[NSString class]]) {
      id expireAtValue = dict[@"expireAt"];
      if ([expireAtValue respondsToSelector:@selector(doubleValue)]) {
        NSTimeInterval expireAt = [expireAtValue doubleValue];
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000.0;
        if (expireAt > 0 && expireAt < now) {
          [self.navigationController.topViewController.view ne_makeToast:NEConversationLocalizable(@"qr_code_expired")];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                         dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
          });
          return YES;
        }
      }

      UINavigationController *nav = self.navigationController;
      [[Router shared] use:NEConversationContactAIRobotBindRouter
                parameters:@{
                  @"nav": nav,
                  @"qrCode": result,
                  @"animated": @YES,
                }
                   closure:nil];

      id<UIViewControllerTransitionCoordinator> coordinator = nav.transitionCoordinator;
      void (^removeScanVC)(void) = ^{
        NSMutableArray<UIViewController *> *viewControllers = [nav.viewControllers mutableCopy];
        NSIndexSet *indexes = [viewControllers indexesOfObjectsPassingTest:^BOOL(UIViewController * _Nonnull obj,
                                                                                 NSUInteger idx,
                                                                                 BOOL * _Nonnull stop) {
          return [obj isKindOfClass:[NEBaseScanQRViewController class]];
        }];
        if (indexes.count > 0) {
          [viewControllers removeObjectsAtIndexes:indexes];
          [nav setViewControllers:viewControllers animated:NO];
        }
      };
      if (coordinator) {
        [coordinator animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
          removeScanVC();
        }];
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          removeScanVC();
        });
      }
      return YES;
    }
  }

  [self.navigationController.topViewController.view ne_makeToast:NEConversationLocalizable(@"scan_qr_fail")];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [self.navigationController popViewControllerAnimated:YES];
  });
  return YES;
}

- (void)searchAction {
  if (ConversationUIConfig.shared.titleBarRight2Click) {
    ConversationUIConfig.shared.titleBarRight2Click(self);
    return;
  }

  if (!self.navigationController) {
    return;
  }

  [[Router shared] use:NEConversationSearchContactPageRouter
            parameters:@{
              @"nav": self.navigationController,
              @"animated": @YES,
            }
               closure:nil];
}

- (void)createDiscussGroup {
  __weak typeof(self) weakSelf = self;
  [[Router shared] register:NEConversationContactSelectedUsersRouter closure:^(NSDictionary<NSString *, id> *param) {
    [[Router shared] use:NEConversationTeamCreateDiscussRouter parameters:param closure:nil];
  }];

  NSMutableSet<NSString *> *filters = [NSMutableSet set];
  NSString *accountId = [[IMKitClient instance] account];
  if (accountId.length > 0) {
    [filters addObject:accountId];
  }

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  if (self.navigationController) {
    params[@"nav"] = self.navigationController;
  }
  params[@"animated"] = @NO;
  params[@"limit"] = @(inviteNumberLimit);
  params[@"filters"] = filters;

  if ([IMKitConfigCenter shared].enableAIUser) {
    [[Router shared] use:NEConversationContactFusionSelectRouter parameters:params closure:nil];
  } else {
    [[Router shared] use:NEConversationContactUserSelectRouter parameters:params closure:nil];
  }

  [[Router shared] register:NEConversationTeamCreateDiscussResultRouter closure:^(NSDictionary<NSString *, id> *param) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    NSInteger code = [param[@"code"] integerValue];
    NSString *teamId = param[@"teamId"];
    if (code == 0 && teamId.length > 0) {
      NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
      if (conversationId.length == 0 || !self.navigationController) {
        return;
      }
      [[Router shared] use:NEConversationPushTeamChatVCRouter
                parameters:@{
                  @"nav": self.navigationController,
                  @"conversationId": conversationId,
                }
                   closure:nil];
    } else if ([param[@"msg"] isKindOfClass:[NSString class]]) {
      [self.view ne_makeToast:param[@"msg"]];
    }
  }];
}

- (void)createSeniorGroup {
  __weak typeof(self) weakSelf = self;
  [[Router shared] register:NEConversationContactSelectedUsersRouter closure:^(NSDictionary<NSString *, id> *param) {
    [[Router shared] use:NEConversationTeamCreateSeniorRouter parameters:param closure:nil];
  }];

  NSMutableSet<NSString *> *filters = [NSMutableSet set];
  NSString *accountId = [[IMKitClient instance] account];
  if (accountId.length > 0) {
    [filters addObject:accountId];
  }

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  if (self.navigationController) {
    params[@"nav"] = self.navigationController;
  }
  params[@"animated"] = @NO;
  params[@"limit"] = @(inviteNumberLimit);
  params[@"filters"] = filters;

  if ([IMKitConfigCenter shared].enableAIUser) {
    [[Router shared] use:NEConversationContactFusionSelectRouter parameters:params closure:nil];
  } else {
    [[Router shared] use:NEConversationContactUserSelectRouter parameters:params closure:nil];
  }

  [[Router shared] register:NEConversationTeamCreateSeniorResultRouter closure:^(NSDictionary<NSString *, id> *param) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    NSInteger code = [param[@"code"] integerValue];
    NSString *teamId = param[@"teamId"];
    if (code == 0 && teamId.length > 0) {
      NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
      if (conversationId.length == 0 || !self.navigationController) {
        return;
      }
      [[Router shared] use:NEConversationPushTeamChatVCRouter
                parameters:@{
                  @"nav": self.navigationController,
                  @"conversationId": conversationId,
                }
                   closure:nil];
    } else if ([param[@"msg"] isKindOfClass:[NSString class]]) {
      [self.view ne_makeToast:param[@"msg"]];
    }
  }];
}

#pragma mark - 子类可重写

- (UITableViewCell *)cellForRowAtModel:(NEConversationListModel *)model
                             indexPath:(NSIndexPath *)indexPath
                             tableView:(UITableView *)tableView {
  NEConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseId forIndexPath:indexPath];
  [cell configureData:model];
  NSNumber *online = self.viewModel.onlineStatusDic[model.conversationId];
  [cell setOnline:online.boolValue];
  return cell;
}

- (void)didSelectConversation:(NEConversationListModel *)model atIndexPath:(NSIndexPath *)indexPath {
  if (ConversationUIConfig.shared.itemClick) {
    ConversationUIConfig.shared.itemClick(self, model, indexPath);
    return;
  }

  if (model.conversationId.length == 0 || self.navigationController == nil) {
    return;
  }

  NSDictionary *parameters = @{
    @"nav": self.navigationController,
    @"conversationId": model.conversationId,
    @"animated": @YES,
  };

  if (model.type == V2NIM_CONVERSATION_TYPE_P2P) {
    [[Router shared] use:NEConversationPushP2pChatVCRouter parameters:parameters closure:nil];
    return;
  }

  if (model.type == V2NIM_CONVERSATION_TYPE_TEAM) {
    [[Router shared] use:NEConversationPushTeamChatVCRouter parameters:parameters closure:nil];
    return;
  }

  NSLog(@"Unsupported conversation type: %ld, id: %@", (long)model.type, model.conversationId);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.viewModel.aiUserListData.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NEConversationStickTopCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kStickTopCellReuseId
                                                                                forIndexPath:indexPath];
  if (indexPath.item < self.viewModel.aiUserListData.count) {
    [cell configure:self.viewModel.aiUserListData[indexPath.item]];
  }
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return CGSizeMake(80.0, CGRectGetHeight(collectionView.bounds));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item >= self.viewModel.aiUserListData.count || self.navigationController == nil) {
    return;
  }

  NEAIUserModel *model = self.viewModel.aiUserListData[indexPath.item];
  NSString *accountId = model.aiUser.accountId;
  NSString *conversationId = accountId.length > 0 ? [V2NIMConversationIdUtil p2pConversationId:accountId] : nil;
  if (conversationId.length == 0) {
    return;
  }

  [[Router shared] use:NEConversationPushP2pChatVCRouter
            parameters:@{
              @"nav": self.navigationController,
              @"conversationId": conversationId,
              @"animated": @NO,
            }
               closure:nil];
}

- (UISwipeActionsConfiguration *)trailingActionsForModel:(NEConversationListModel *)model
                                              atIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
  ConversationUIConfig *config = ConversationUIConfig.shared;
  __weak typeof(self) weakSelf = self;

  UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                             title:config.deleteButtonTitle ?: NEConversationLocalizable(@"delete")
                                                                           handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      completionHandler(YES);
      return;
    }
    [self deleteActionHandlerWithIndexPath:indexPath];
    completionHandler(YES);
  }];
  deleteAction.backgroundColor = config.deleteButtonBackgroundColor
    ?: [UIColor colorWithRed:0.659 green:0.671 blue:0.714 alpha:1.0]; // #A8ABB6

  BOOL isStickTop = model.stickTop;
  NSString *stickTitle = isStickTop
    ? (config.stickTopButtonCancelTitle ?: NEConversationLocalizable(@"cancel_stickTop"))
    : (config.stickTopButtonTitle ?: NEConversationLocalizable(@"stickTop"));

  UIContextualAction *stickAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                            title:stickTitle
                                                                          handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      completionHandler(YES);
      return;
    }
    [self topActionHandlerWithIndexPath:indexPath isTop:isStickTop];
    completionHandler(YES);
  }];
  stickAction.backgroundColor = config.stickTopButtonBackgroundColor
    ?: [UIColor colorWithRed:0.2 green:0.49 blue:1.0 alpha:1.0]; // #337EFF

  UISwipeActionsConfiguration *swipeConfig = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, stickAction]];
  swipeConfig.performsFirstActionWithFullSwipe = NO;
  return swipeConfig;
}

- (void)deleteActionHandlerWithIndexPath:(NSIndexPath *)indexPath {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NEConversationListModel *conversationModel = nil;
  if (indexPath.row < (NSInteger)self.viewModel.conversationListData.count) {
    conversationModel = self.viewModel.conversationListData[indexPath.row];
  }

  if (conversationModel.conversationId.length == 0) {
    [self reloadTableView];
    return;
  }

  if (ConversationUIConfig.shared.deleteButtonClick) {
    ConversationUIConfig.shared.deleteButtonClick(self, conversationModel, indexPath);
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel deleteConversation:conversationModel.conversationId completion:^(NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    if (error) {
      [self showToast:error.localizedDescription ?: @""];
    }
    if (!error) {
      [self didDeleteConversationCell:conversationModel indexPath:indexPath];
    }
    [self reloadTableView];
  }];
}

- (void)topActionHandlerWithIndexPath:(NSIndexPath *)indexPath isTop:(BOOL)isTop {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  if (indexPath.row >= (NSInteger)self.viewModel.conversationListData.count) {
    return;
  }

  NEConversationListModel *conversationModel = self.viewModel.conversationListData[indexPath.row];
  if (conversationModel.conversationId.length == 0) {
    return;
  }

  if (ConversationUIConfig.shared.stickTopButtonClick) {
    ConversationUIConfig.shared.stickTopButtonClick(self, conversationModel, indexPath);
    return;
  }

  __weak typeof(self) weakSelf = self;
  void (^completion)(NSError * _Nullable) = ^(NSError * _Nullable error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    if (error) {
      [self showToast:error.localizedDescription ?: @""];
    } else if (isTop) {
      [self didRemoveStickTopSession:conversationModel indexPath:indexPath];
    } else {
      [self didAddStickTopSession:conversationModel indexPath:indexPath];
    }
    [self reloadTableView];
  };

  if (isTop) {
    [self.viewModel removeStickTop:conversationModel.conversationId completion:completion];
  } else {
    [self.viewModel addStickTop:conversationModel.conversationId completion:completion];
  }
}

- (void)didDeleteConversationCell:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

- (void)didRemoveStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

- (void)didAddStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

#pragma mark - StickTop

- (void)refreshAIUserDisplayState {
  if ([IMKitConfigCenter shared].enableAIUser) {
    if (self.viewModel.aiUserListData.count == 0) {
      [self.viewModel getAIUserList];
    }
  } else if (self.viewModel.aiUserListData.count > 0) {
    [self.viewModel.aiUserListData removeAllObjects];
  }
}

- (void)setBodyTopViewHeight:(CGFloat)bodyTopViewHeight {
  _bodyTopViewHeight = bodyTopViewHeight;
  self.bodyTopViewHeightAnchor.constant = bodyTopViewHeight;
  self.bodyTopView.hidden = (bodyTopViewHeight <= 0.0);
}

- (void)setupStickTopView {
  if (self.viewModel.aiUserListData.count > 0) {
    if (self.tableView.tableHeaderView != self.stickTopCollectionView) {
      self.tableView.tableHeaderView = self.stickTopCollectionView;
    }
    [self.stickTopCollectionView reloadData];
    if (NEConversationIsNormalStyle()) {
      self.navigationView.titleBarBottomLine.hidden = YES;
    }
  } else {
    self.tableView.tableHeaderView = nil;
    self.navigationView.titleBarBottomLine.hidden = !NEConversationIsNormalStyle();
  }
}

#pragma mark - Lazy Init

- (TabNavigationView *)navigationView {
  if (!_navigationView) {
    _navigationView = [[TabNavigationView alloc] init];
    _navigationView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationView.delegate = self;
    // 默认品牌文案
    [_navigationView.brandBtn setTitle:commonLocalizable(@"appName") forState:UIControlStateNormal];
    [_navigationView.brandBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _navigationView.brandBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:20] ?: [UIFont boldSystemFontOfSize:20];
  }
  return _navigationView;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
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
    _emptyView = [[NEEmptyDataView alloc] initWithImageName:(NEConversationIsNormalStyle() ? @"user_empty" : @"fun_user_empty")
                                                    content:NEConversationLocalizable(@"session_empty")
                                                      frame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyView.hidden = YES;
    _emptyView.userInteractionEnabled = NO;
  }
  return _emptyView;
}

- (NEBrokenNetworkView *)brokenNetworkView {
  if (!_brokenNetworkView) {
    _brokenNetworkView = [[NEBrokenNetworkView alloc] init];
    _brokenNetworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _brokenNetworkView.hidden = YES;
    if (!NEConversationIsNormalStyle()) {
      _brokenNetworkView.backgroundColor = UIColor.whiteColor;
      _brokenNetworkView.errorIconView.hidden = NO;
    }
  }
  return _brokenNetworkView;
}

- (UICollectionView *)stickTopCollectionView {
  if (!_stickTopCollectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0.0;
    layout.minimumInteritemSpacing = 0.0;

    CGFloat width = CGRectGetWidth(UIScreen.mainScreen.bounds) - 20.0;
    _stickTopCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 104.0)
                                                  collectionViewLayout:layout];
    _stickTopCollectionView.backgroundColor = UIColor.clearColor;
    _stickTopCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _stickTopCollectionView.dataSource = self;
    _stickTopCollectionView.delegate = self;
    _stickTopCollectionView.pagingEnabled = YES;
    _stickTopCollectionView.showsHorizontalScrollIndicator = NO;
    _stickTopCollectionView.showsVerticalScrollIndicator = NO;
    _stickTopCollectionView.alwaysBounceHorizontal = YES;
    [_stickTopCollectionView addSubview:self.pinUserDividerLine];
  }
  return _stickTopCollectionView;
}

- (UIView *)pinUserDividerLine {
  if (!_pinUserDividerLine) {
    _pinUserDividerLine = [[UIView alloc] initWithFrame:CGRectMake(-10.0, 103.0, CGRectGetWidth(UIScreen.mainScreen.bounds) + 20.0, 1.0)];
    _pinUserDividerLine.backgroundColor = [UIColor ne_navLineColor];
    _pinUserDividerLine.hidden = !NEConversationIsNormalStyle();
  }
  return _pinUserDividerLine;
}

- (FunSearchView *)searchView {
  if (!_searchView) {
    _searchView = [[FunSearchView alloc] initWithFrame:CGRectZero];
    _searchView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchView;
}

@end
