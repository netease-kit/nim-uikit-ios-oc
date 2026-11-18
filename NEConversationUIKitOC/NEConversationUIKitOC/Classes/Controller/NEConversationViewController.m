// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <objc/runtime.h>
#import "NEConversationViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "NEBaseScanQRViewController.h"
#import "NEConversationPopListView.h"
#import "ConversationViewModel.h"
#import "NEConversationListModel.h"
#import "NEConversationListCell.h"
#import "ConversationUIConfig.h"
#import "NEConversationGroupManager.h"
#import <NEChatKit/NEChatKit.h>
@import NEBaseUIKitOC;
#import <NEBaseUIKitOC/FunSearchView.h>
#import <NEBaseUIKitOC/NEButtonExtension.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NEConfigManager.h>
#import <NEBaseUIKitOC/UITableViewCell+NEAdaptiveSelection.h>
#import <NEChatKit/NEAIUserModel.h>
#import <NEChatKit/NEAIRobotManager.h>
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
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <objc/message.h>

static NSString * const NEConversationContactUserSelectRouter = @"imkit://contact/selector.page";
static NSString * const NEConversationContactFusionSelectRouter = @"imkit://contact/fusionselector.page";
static NSString * const NEConversationContactSelectedUsersRouter = @"imkit://contact.selectUser.page";
static NSString * const NEConversationTeamCreateDiscussRouter = @"imkit://team.create.discuss";
static NSString * const NEConversationTeamCreateSeniorRouter = @"imkit://team.create.senior";
static NSString * const NEConversationTeamCreateDiscussResultRouter = @"imkit://team.create.discuss.result";
static NSString * const NEConversationTeamCreateSeniorResultRouter = @"imkit://team.create.senior.result";

static BOOL NEConversationIsNormalStyle(void);

static CGFloat NENavigationAndStatusHeight(void) {
  return NEUIKitNavigationAndStatusHeight();
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

@interface NEBaseConversationController () <NENavigationBarHeightProviding, ConversationViewModelDelegate, TabNavigationViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NEIMKitClientListener, NEConversationGroupManagerDelegate>
@property (nonatomic, strong) NSLayoutConstraint *bodyTopViewTopAnchor;
@property (nonatomic, strong) NSLayoutConstraint *brokenNetworkViewHeightAnchor;
@property (nonatomic, assign) BOOL networkBroken;
@property (nonatomic, assign) BOOL conversationListRenderPending;
@property (nonatomic, assign) BOOL stickTopRenderPending;
// 容器视图（对齐 Swift bodyTopView/bodyView）
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UICollectionView *stickTopCollectionView;
@property (nonatomic, strong) UIView *pinUserDividerLine;
@property (nonatomic, strong) FunSearchView *searchView;
@property (nonatomic, strong, nullable) NEConversationGroupManager *groupManager;
@property (nonatomic, strong, readwrite) ConversationGroupViewModel *conversationGroupViewModel;
@property (nonatomic, copy, nullable) NSString *renderedConversationGroupId;
- (void)updateConversationListFooter;
/// 当前查看会话的 id：列表刷新后据此恢复左列选中高亮。
@property (nonatomic, copy, nullable) NSString *adaptiveSelectedConversationId;
/// 自定义标题栏高度约束：安全区/状态栏就绪后需要自愈。
@property (nonatomic, strong, nullable) NSLayoutConstraint *navigationViewHeightAnchor;
@end

@implementation NEBaseConversationController

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
    _bodyBottomViewHeight = 0.0;
    _topConstant = 0.0;
    _deleteButtonBackgroundColor = [NEConstant hexRGB:0xA8ABB6];
    _topButtonBackgroundColor = [NEConstant hexRGB:0x337EFF];
    _brokenNetworkViewHeight = NEConversationBrokenNetworkHeight();
    BOOL funStyle = [self isKindOfClass:[FunConversationController class]] || !NEConversationIsNormalStyle();
    _cellRegisterDic = @{@0: funStyle ? [FunConversationListCell class] : [ConversationListCell class]};
    _stickTopCellRegisterDic = @{@0: funStyle ? [FunStickTopCell class] : [StickTopCell class]};
    _groupManager = [[NEConversationGroupManager alloc] init];
    _conversationGroupViewModel = [[ConversationGroupViewModel alloc] initWithManager:_groupManager];
    _conversationGroupViewModel.delegate = (id<ConversationGroupViewModelDelegate>)self;

    if (type == NEConversationDataSourceTypeCloud) {
      _viewModel = [ConversationViewModel cloudViewModel];
    } else {
      _viewModel = [ConversationViewModel localViewModel];
    }
  }
  return self;
}

+ (instancetype)cloudController {
  return [[self alloc] initWithDataSourceType:NEConversationDataSourceTypeCloud];
}

+ (instancetype)localController {
  return [[self alloc] initWithDataSourceType:NEConversationDataSourceTypeLocal];
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
  [self showTitleBar];
  [self setupSubviews];
  [self initialConfig];
  [[IMKitClient instance] addLoginListener:self];
  [self changeLanguage];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self ne_refreshNavigationBarHeightIfNeeded];
  [self showTitleBar];

  [self refreshAIUserDisplayState];
  [self reloadTableView];

  __weak typeof(self) weakSelf = self;
  [NEChatDetectNetworkTool.shareInstance netWorkReachability:^(NEReachabilityStatus status) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }

    BOOL notReachable = (status == NEReachabilityStatusNotReachable);
    self.brokenNetworkView.hidden = !notReachable;
    self.contentViewTopAnchor.constant = notReachable ? self.brokenNetworkViewHeight : 0.0;
  }];

  if (self.navigationController.viewControllers.count > 0 &&
      [self.navigationController.viewControllers.firstObject isKindOfClass:[NEBaseConversationController class]]) {
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
  }

  if (ConversationUIConfig.shared.customController) {
    ConversationUIConfig.shared.customController((NEBaseConversationController *)self);
  }

  [self subscribeVisibleRows];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.popListView removeSelf];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  if (parent != nil) {
    return;
  }
  if (!NEConversationIsNormalStyle()) {
    for (UIGestureRecognizer *gesture in [self.searchView.gestureRecognizers copy]) {
      [self.searchView removeGestureRecognizer:gesture];
    }
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  UINavigationController *navigationController = self.navigationController;
  if (navigationController &&
      gestureRecognizer == navigationController.interactivePopGestureRecognizer &&
      navigationController.visibleViewController == navigationController.viewControllers.firstObject) {
    return NO;
  }
  return YES;
}

- (void)showTitleBar {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  BOOL useSystemNavigation = useSystemNavValue && useSystemNavValue.boolValue;
  if (useSystemNavigation) {
    self.navigationView.hidden = YES;
    self.topConstant = 0.0;
    if (ConversationUIConfig.shared.showTitleBar) {
      [self.navigationController setNavigationBarHidden:NO animated:NO];
    } else {
      [self.navigationController setNavigationBarHidden:YES animated:NO];
      self.topConstant = NEUIKitStatusBarHeightForView(self.view);
    }
    return;
  }

  [self.navigationController setNavigationBarHidden:YES animated:NO];
  if (ConversationUIConfig.shared.showTitleBar) {
    self.navigationView.hidden = NO;
    self.topConstant = NEConstant.navigationHeight;
  } else {
    self.navigationView.hidden = YES;
    self.topConstant = 0.0;
  }
  self.topConstant += NEUIKitStatusBarHeightForView(self.view);
}

- (void)initSystemNav {
  self.edgesForExtendedLayout = UIRectEdgeNone;

  UIButton *brandButton = [UIButton buttonWithType:UIButtonTypeCustom];
  brandButton.accessibilityIdentifier = @"id.titleBarTitle";
  NSString *title = ConversationUIConfig.shared.titleBarTitle.length > 0
    ? ConversationUIConfig.shared.titleBarTitle
    : commonLocalizable(@"appName");
  [brandButton setTitle:title forState:UIControlStateNormal];
  [brandButton setImage:[coreLoader() loadImage:@"brand_yunxin"] forState:UIControlStateNormal];
  [brandButton layoutButtonImageWithStyle:NEButtonStyleLeft space:12.0];
  [brandButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
  brandButton.titleLabel.font = [NEConstant textFont:@"PingFangSC-Medium" size:20.0];
  [brandButton addTarget:self action:@selector(brandBtnClick) forControlEvents:UIControlEventTouchUpInside];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:brandButton];

  UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
  addButton.accessibilityIdentifier = @"id.titleBarMoreImg";
  [addButton setImage:[coreLoader() loadImage:@"nav_add"] forState:UIControlStateNormal];
  [addButton addTarget:self action:@selector(didClickAddBtn) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];

  if (!NEConversationIsNormalStyle()) {
    self.navigationItem.rightBarButtonItems = ConversationUIConfig.shared.showTitleBarRightIcon ? @[addItem] : @[];
    self.navigationView.searchBtn.hidden = YES;
    self.navigationView.addBtn.hidden = !ConversationUIConfig.shared.showTitleBarRightIcon;
    return;
  }

  UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
  searchButton.accessibilityIdentifier = @"id.titleBarSearchImg";
  [searchButton setImage:[NEConversationLoader() loadImage:@"nav_search"] forState:UIControlStateNormal];
  [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
  UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
  spaceItem.width = NEConstant.screenInterval;
  self.navigationItem.rightBarButtonItems = @[addItem, spaceItem, searchItem];
  if (!ConversationUIConfig.shared.showTitleBarRight2Icon) {
    self.navigationView.searchBtn.hidden = YES;
    self.navigationItem.rightBarButtonItems = @[addItem];
  }
  if (!ConversationUIConfig.shared.showTitleBarRightIcon) {
    self.navigationView.addBtn.hidden = YES;
    self.navigationItem.rightBarButtonItems = @[searchItem];
  }
}

#pragma mark - Setup

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self ne_refreshNavigationBarHeightIfNeeded];
}

#pragma mark - NENavigationBarHeightProviding

- (CGFloat)ne_navigationBarHeight {
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  return NEUIKitNavigationAndStatusHeightForView(self.view) + extra;
}

- (void)ne_applyNavigationBarHeight:(CGFloat)height {
  if (!self.navigationViewHeightAnchor || !self.navigationView.superview) {
    return;
  }
  if (fabs(self.navigationViewHeightAnchor.constant - height) < 0.5) {
    return;
  }
  self.navigationViewHeightAnchor.constant = height;
  // 内容起点同样依赖状态栏；showTitleBar 用 view 安全区重算 topConstant。
  [self showTitleBar];
  [self.view setNeedsLayout];
}

- (void)setupSubviews {
  CGFloat navH = NENavigationAndStatusHeight();

  // ── navigationView（自定义标题栏）
  [self.view addSubview:self.navigationView];
  [NSLayoutConstraint activateConstraints:@[
    [self.navigationView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.navigationView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.navigationView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
  self.navigationViewHeightAnchor =
      [self.navigationView.heightAnchor constraintEqualToConstant:navH + (NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0)];
  self.navigationViewHeightAnchor.active = YES;

  // ── bodyTopView（顶部自定义区域）
  self.bodyTopView = [[UIView alloc] init];
  self.bodyTopView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bodyTopView.backgroundColor = [UIColor clearColor];
  self.bodyTopView.hidden = YES;
  [self.view addSubview:self.bodyTopView];
  self.bodyTopViewTopAnchor = [self.bodyTopView.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                                         constant:self.topConstant];
  self.bodyTopViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
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

  self.bodyBottomView = [[UIView alloc] init];
  self.bodyBottomView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bodyBottomView.backgroundColor = UIColor.clearColor;
  self.bodyBottomView.hidden = YES;
  [self.view addSubview:self.bodyBottomView];

  [NSLayoutConstraint activateConstraints:@[
    [self.bodyView.topAnchor constraintEqualToAnchor:self.bodyTopView.bottomAnchor],
    [self.bodyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bodyView.bottomAnchor constraintEqualToAnchor:self.bodyBottomView.topAnchor],
    [self.bodyBottomView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyBottomView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bodyBottomView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  self.bodyBottomViewHeightAnchor = [self.bodyBottomView.heightAnchor constraintEqualToConstant:self.bodyBottomViewHeight];
  self.bodyBottomViewHeightAnchor.active = YES;

  // ── brokenNetworkView（网络断开提示，覆盖在 bodyView 顶部）
  [self.bodyView addSubview:self.brokenNetworkView];
  self.brokenNetworkViewHeightAnchor = [self.brokenNetworkView.heightAnchor constraintEqualToConstant:self.brokenNetworkViewHeight];
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
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:150],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
  ]];

  [self.cellRegisterDic enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, Class cellClass, BOOL *stop) {
    [self.tableView registerClass:cellClass forCellReuseIdentifier:key.stringValue];
  }];
  [self.stickTopCellRegisterDic enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, Class cellClass, BOOL *stop) {
    [self.stickTopCollectionView registerClass:cellClass forCellWithReuseIdentifier:key.stringValue];
  }];

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
    CGFloat funStickTopHeight = self.adaptiveStickTopHeight > 0 ? self.adaptiveStickTopHeight : 104.0;
    self.stickTopCollectionView.frame =
        CGRectMake(4.0, 0.0, CGRectGetWidth(self.view.frame) - 8.0, funStickTopHeight);

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
  if (!config.showTitleBarLeftIcon) {
    [self.navigationView.brandBtn setImage:nil forState:UIControlStateNormal];
    [self.navigationView.brandBtn layoutButtonImageWithStyle:NEButtonStyleLeft space:0.0];
  }
  if (config.titleBarLeftRes) {
    [self.navigationView.brandBtn setImage:config.titleBarLeftRes forState:UIControlStateNormal];
    if (CGSizeEqualToSize(config.titleBarLeftRes.size, CGSizeZero)) {
      [self.navigationView.brandBtn layoutButtonImageWithStyle:NEButtonStyleLeft space:0.0];
    }
  }
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
}

- (void)changeLanguage {
  ConversationUIConfig *config = ConversationUIConfig.shared;
  NSString *title = config.titleBarTitle.length > 0 ? config.titleBarTitle : commonLocalizable(@"appName");
  [self.navigationView.brandBtn setTitle:title forState:UIControlStateNormal];
  self.brokenNetworkView.contentLabel.text = commonLocalizable(@"network_error");
  [self.searchView.searchButton setTitle:commonLocalizable(@"search") forState:UIControlStateNormal];
  [self.groupManager refreshLocalizedDefaultGroupNames];
  [self requestData];
  [self initSystemNav];
  self.popListView = [self getPopListView];
}

- (BOOL)conversationGroupsEnabled {
  return NO;
}

- (NSArray<NEConversationListModel *> *)currentConversationData {
  if (self.groupManager) {
    return self.groupManager.displayedConversations ?: @[];
  }
  return self.viewModel.conversationListData ?: @[];
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
      NSArray<NEConversationListModel *> *data = self.viewModel.conversationListData ?: @[];
      [self.groupManager updateAllConversations:data];
      if (data.count == 0) {
        self.emptyView.hidden = NO;
      } else {
        self.emptyView.hidden = YES;
        [self reloadTableView];
        if ([self.delegate respondsToSelector:@selector(onDataLoaded)]) {
          [self.delegate onDataLoaded];
        }
      }
    }
  }];
}

- (void)loadMoreData {
  if (self.groupManager.isEnabled && self.groupManager.selectedGroup.kind == NEConversationGroupKindCustom) {
    __weak typeof(self) weakSelf = self;
    [self.groupManager loadMoreSelectedGroup:^(NSError * _Nullable error, BOOL finished) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      if (finished) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
      } else {
        [self.tableView.mj_footer endRefreshing];
      }
      [self reloadTableView];
    }];
    return;
  }

  if (self.groupManager.isEnabled && self.groupManager.selectedGroup.kind == NEConversationGroupKindUnread) {
    __weak typeof(self) weakSelf = self;
    [self.groupManager loadMoreSelectedUnreadGroup:^(NSError * _Nullable error, BOOL finished) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      if (finished) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
      } else {
        [self.tableView.mj_footer endRefreshing];
      }
      [self reloadTableView];
    }];
    return;
  }

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
    if ([self.delegate respondsToSelector:@selector(onDataLoaded)]) {
      [self.delegate onDataLoaded];
    }
    [self reloadTableView];
  }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.currentConversationData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger row = indexPath.row;
  NSArray *data = self.currentConversationData;
  if (row >= (NSInteger)data.count) {
    return [[UITableViewCell alloc] init];
  }
  NEConversationListModel *model = data[row];
  UITableViewCell *cell = [self cellForRowAtModel:model indexPath:indexPath tableView:tableView];
  [cell ne_captureAdaptiveSelectionBackground];
  [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor
                              selected:[self isSelectedConversationCell:cell]];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return self.cellRowHeight;
}

#pragma mark - UITableViewDelegate

- (void)setListSelectionBackgroundColor:(UIColor *)listSelectionBackgroundColor {
  _listSelectionBackgroundColor = listSelectionBackgroundColor;
  if (!self.isViewLoaded) {
    return;
  }
  [self refreshAdaptiveSelectionTint];
}

- (BOOL)isSelectedConversationCell:(UITableViewCell *)cell {
  if (!self.listSelectionBackgroundColor || self.adaptiveSelectedConversationId.length == 0) {
    return NO;
  }
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  NSArray *data = self.currentConversationData;
  if (!indexPath || indexPath.row >= (NSInteger)data.count) {
    return NO;
  }
  return [[data[indexPath.row] conversationId] isEqualToString:self.adaptiveSelectedConversationId];
}

- (NSArray *)adaptiveSelectionDataSource {
  return self.currentConversationData;
}

/// 唯一权威状态是 adaptiveSelectedConversationId：每次按它重算所有可见 cell 的底色，
/// 不依赖 UITableView 的选中集合（程序化 selectRow 不会取消其它行，快速切换会出现两行高亮）。
- (void)refreshAdaptiveSelectionTint {
  if (!self.isViewLoaded) {
    return;
  }
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor
                                selected:[self isSelectedConversationCell:cell]];
  }
}

- (void)ne_markSelectedConversationId:(nullable NSString *)conversationId {
  _adaptiveSelectedConversationId = [conversationId copy];
  [self refreshAdaptiveSelectionTint];
}

- (void)ne_selectConversation:(nullable NSString *)conversationId animated:(BOOL)animated {
  [self ne_markSelectedConversationId:conversationId];
  if (conversationId.length == 0 || !self.listSelectionBackgroundColor) {
    return;
  }
  NSArray *data = [self adaptiveSelectionDataSource];
  for (NSInteger row = 0; row < (NSInteger)data.count; row++) {
    if (![[data[row] conversationId] isEqualToString:conversationId]) {
      continue;
    }
    // 分组过滤可能在查找与滚动之间改变展示行数，越界滚动会抛异常；
    // 以表格实际行数为准，超界时只保留高亮，不做定位。
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if (row >= rows) {
      return;
    }
    if (self.view.window) {
      [self.tableView layoutIfNeeded];
    }
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:animated];
    [self refreshAdaptiveSelectionTint];
    return;
  }
}

- (void)ne_retainConversationInGroup:(nullable NSString *)conversationId {
  if (![self.conversationGroupViewModel setRetainedConversation:conversationId]) {
    return;
  }
  [self reloadTableView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor
                              selected:[self isSelectedConversationCell:cell]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // 选中态统一由 adaptiveSelectedConversationId + 底色负责，表格自身不保留选中行，
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  NSInteger row = indexPath.row;
  NSArray *data = self.currentConversationData;
  if (row >= (NSInteger)data.count) return;
  NEConversationListModel *model = data[row];
  self.adaptiveSelectedConversationId = model.conversationId;
  [self refreshAdaptiveSelectionTint];
  [self didSelectConversation:model atIndexPath:indexPath];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
  NSInteger row = indexPath.row;
  NSArray *data = self.currentConversationData;
  if (row >= (NSInteger)data.count) return nil;
  NEConversationListModel *model = data[row];
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
    NSArray *data = self.currentConversationData;
    if (indexPath.row >= (NSInteger)data.count) {
      continue;
    }

    NEConversationListModel *model = data[indexPath.row];
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
  if ([self.delegate respondsToSelector:@selector(onDataLoaded)]) {
    [self.delegate onDataLoaded];
  }
}

- (void)reloadTableView {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.groupManager updateAllConversations:self.viewModel.conversationListData ?: @[]];
    self.renderedConversationGroupId = self.groupManager.selectedGroup.groupId;
    self.emptyView.hidden = (self.currentConversationData.count > 0);
    [self updateConversationListFooter];
    [self scheduleConversationListRenderIncludingStickTop:YES];
    // 列表刷新会重建 cell，按当前会话 id 重新贴一次选中底色。
    [self refreshAdaptiveSelectionTint];
  });
}

- (void)updateConversationListFooter {
  BOOL finished = self.viewModel.syncFinished;
  if (self.groupManager.isEnabled && self.groupManager.selectedGroup.kind == NEConversationGroupKindCustom) {
    finished = self.groupManager.selectedGroupFinished;
  } else if (self.groupManager.isEnabled && self.groupManager.selectedGroup.kind == NEConversationGroupKindUnread) {
    finished = self.groupManager.selectedUnreadFinished;
  }

  if (finished) {
    self.tableView.mj_footer = nil;
    return;
  }
  if (self.tableView.mj_footer != nil) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
    [weakSelf loadMoreData];
  }];
}

- (void)scheduleConversationListRenderIncludingStickTop:(BOOL)includeStickTop {
  self.stickTopRenderPending = self.stickTopRenderPending || includeStickTop;
  if (self.conversationListRenderPending) return;
  self.conversationListRenderPending = YES;
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    // Allow updates triggered during rendering to schedule the next pass.
    BOOL renderStickTop = self.stickTopRenderPending;
    self.conversationListRenderPending = NO;
    self.stickTopRenderPending = NO;
    if (renderStickTop) [self setupStickTopView];
    [self.tableView reloadData];
  });
}

#pragma mark - Conversation groups

- (void)conversationGroupManagerDidReload {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.emptyView.hidden = self.groupManager.displayedConversations.count > 0;
  });
}

- (void)conversationGroupManagerSelectionDidChange {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.emptyView.hidden = self.groupManager.displayedConversations.count > 0;
    [self scheduleConversationListRenderIncludingStickTop:NO];
  });
}

- (void)conversationGroupDidReload {
  [self conversationGroupManagerDidReload];
}

- (void)conversationGroupSelectionChanged {
  [self conversationGroupManagerSelectionDidChange];
}

- (void)loadMoreStateChange:(BOOL)finish {
  if (finish) {
    self.tableView.mj_footer = nil;
    return;
  }
  [self updateConversationListFooter];
}

#pragma mark - TabNavigationViewDelegate

- (void)brandBtnClick {
  if (ConversationUIConfig.shared.titleBarLeftClick) {
    ConversationUIConfig.shared.titleBarLeftClick((NEBaseConversationController *)self);
  }
}

- (void)didClickAddBtn {
  if (ConversationUIConfig.shared.titleBarRightClick) {
    ConversationUIConfig.shared.titleBarRightClick((NEBaseConversationController *)self);
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

- (NEBasePopListView *)getPopListView {
  return NEConversationIsNormalStyle() ? [[PopListView alloc] initWithFrame:CGRectZero] : [[FunPopListView alloc] initWithFrame:CGRectZero];
}

- (NSArray<PopListItem *> *)getPopListItems {
  __weak typeof(self) weakSelf = self;
  BOOL isNormalStyle = NEConversationIsNormalStyle();
  NSMutableArray<PopListItem *> *items = [NSMutableArray array];

  PopListItem *addFriend = [[PopListItem alloc] init];
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

  PopListItem *joinTeam = [[PopListItem alloc] init];
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

  PopListItem *createDiscuss = [[PopListItem alloc] init];
  createDiscuss.showName = NEConversationLocalizable(@"create_discussion_group");
  createDiscuss.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  createDiscuss.image = [NEConversationLoader() loadImage:isNormalStyle ? @"create_discussion" : @"fun_create_discussion"];
  createDiscuss.completion = ^{
    [weakSelf createDiscussGroup];
  };
  [items addObject:createDiscuss];

  PopListItem *createGroup = [[PopListItem alloc] init];
  createGroup.showName = NEConversationLocalizable(@"create_senior_group");
  createGroup.showNameColor = isNormalStyle ? [NEConstant hexRGB:0x333333] : UIColor.whiteColor;
  createGroup.image = [NEConversationLoader() loadImage:isNormalStyle ? @"create_group" : @"fun_create_team"];
  createGroup.completion = ^{
    [weakSelf createSeniorGroup];
  };
  [items addObject:createGroup];

  PopListItem *scanQR = [[PopListItem alloc] init];
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

  NEBaseScanQRViewController *scanVC = [self getScanQRViewController];
  __weak typeof(self) weakSelf = self;
  scanVC.onScanResult = ^BOOL(NSString *result) {
    return [weakSelf handleQRScanResult:result];
  };
  [self.navigationController pushViewController:scanVC animated:YES];
}

- (NEBaseScanQRViewController *)getScanQRViewController {
  return NEConversationIsNormalStyle() ? [[ScanQRViewController alloc] init]
                                       : [[FunScanQRViewController alloc] init];
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
    ConversationUIConfig.shared.titleBarRight2Click((NEBaseConversationController *)self);
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
  NSString *reuseId = [NSString stringWithFormat:@"%ld", (long)model.customType];
  NEBaseConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
  [cell configureData:model];
  NSNumber *online = self.viewModel.onlineStatusDic[model.conversationId];
  [cell setOnline:online.boolValue];
  return cell;
}

- (void)ne_openConversationRoute:(NSString *)route parameters:(NSDictionary<NSString *, id> *)parameters {
  NSMutableDictionary<NSString *, id> *legacyParameters = [parameters mutableCopy];
  if ([NSThread isMainThread] && self.onOpenConversation) {
    if (self.onOpenConversation(route, parameters)) {
      return;
    }
    legacyParameters[@"ne_conversation_presentation_declined"] = @YES;
  }
  [[Router shared] use:route parameters:legacyParameters closure:nil];
}

- (void)didSelectConversation:(NEConversationListModel *)model atIndexPath:(NSIndexPath *)indexPath {
  // 会话可能通过 cell 手势或 itemClick 打开，不一定走 tableView:didSelectRow，
  self.adaptiveSelectedConversationId = model.conversationId;
  if (ConversationUIConfig.shared.itemClick) {
    ConversationUIConfig.shared.itemClick((NEBaseConversationController *)self, model, indexPath);
    return;
  }

  if (model.conversationId.length == 0 || self.navigationController == nil) {
    return;
  }

  [[Router shared] use:@"ClearAtMessageRemind"
            parameters:@{@"sessionId": model.conversationId}
               closure:nil];

  NSDictionary *parameters = @{
    @"nav": self.navigationController,
    @"conversationId": model.conversationId,
    @"animated": @YES,
  };

  if (model.type == V2NIM_CONVERSATION_TYPE_P2P) {
    NSString *sessionId = [V2NIMConversationIdUtil conversationTargetId:model.conversationId];
    if (sessionId.length == 0) return;
    BOOL isRobot = [[NEAIRobotManager shared] isRobot:sessionId];
    NSMutableDictionary *targetParameters = [parameters mutableCopy];
    targetParameters[@"sessionId"] = sessionId;
    V2NIMUserAIBot *bot = isRobot ? [[NEAIRobotManager shared] getBot:sessionId] : nil;
    targetParameters[@"sessionName"] = bot.name.length > 0 ? bot.name : (model.name.length > 0 ? model.name : sessionId);
    [self ne_openConversationRoute:NEConversationPushP2pChatVCRouter parameters:targetParameters];
    return;
  }

  if (model.type == V2NIM_CONVERSATION_TYPE_TEAM) {
    [self ne_openConversationRoute:NEConversationPushTeamChatVCRouter parameters:parameters];
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
  NEAIUserModel *model = self.viewModel.aiUserListData[indexPath.item];
  NSString *reuseId = [NSString stringWithFormat:@"%ld", (long)model.customType];
  NEBaseStickTopCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId
                                                                        forIndexPath:indexPath];
  if (indexPath.item < self.viewModel.aiUserListData.count) {
    [cell configAIUserCellData:model];
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
  deleteAction.backgroundColor = config.deleteButtonBackgroundColor ?: self.deleteButtonBackgroundColor;

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
  stickAction.backgroundColor = config.stickTopButtonBackgroundColor ?: self.topButtonBackgroundColor;

  UISwipeActionsConfiguration *swipeConfig = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, stickAction]];
  swipeConfig.performsFirstActionWithFullSwipe = NO;
  return swipeConfig;
}

- (void)deleteActionHandlerWithIndexPath:(NSIndexPath *)indexPath {
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NEConversationListModel *conversationModel = nil;
  NSArray *data = self.currentConversationData;
  if (indexPath.row < (NSInteger)data.count) {
    conversationModel = data[indexPath.row];
  }

  if (conversationModel.conversationId.length == 0) {
    [self reloadTableView];
    return;
  }

  if (ConversationUIConfig.shared.deleteButtonClick) {
    ConversationUIConfig.shared.deleteButtonClick((NEBaseConversationController *)self, conversationModel, indexPath);
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
    [self refreshConversationRowsAfterMutation];
  }];
}

- (void)topActionHandlerWithIndexPath:(NSIndexPath *)indexPath isTop:(BOOL)isTop {
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSArray *data = self.currentConversationData;
  if (indexPath.row >= (NSInteger)data.count) {
    return;
  }

  NEConversationListModel *conversationModel = data[indexPath.row];
  if (conversationModel.conversationId.length == 0) {
    return;
  }

  if (ConversationUIConfig.shared.stickTopButtonClick) {
    ConversationUIConfig.shared.stickTopButtonClick((NEBaseConversationController *)self, conversationModel, indexPath);
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
    [self refreshConversationRowsAfterMutation];
  };

  if (isTop) {
    [self.viewModel removeStickTop:conversationModel.conversationId completion:completion];
  } else {
    [self.viewModel addStickTop:conversationModel.conversationId completion:completion];
  }
}

- (void)refreshConversationRowsAfterMutation {
  if (self.groupManager.selectedGroup.kind == NEConversationGroupKindCustom) {
    [self.groupManager reloadSelectedCustomGroup];
  } else {
    [self reloadTableView];
  }
}

- (void)didDeleteConversationCell:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

- (void)didRemoveStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

- (void)didAddStickTopSession:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
}

- (void)onselectedTableRowWithConversation:(V2NIMConversation *)conversation {
  if (!conversation) return;
  NEConversationListModel *model = [NEConversationListModel modelWithCloudConversation:conversation];
  [self didSelectConversation:model atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)didDeleteConversationCellWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
  [self didDeleteConversationCell:model indexPath:indexPath];
}

- (void)didRemoveStickTopSessionWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
  [self didRemoveStickTopSession:model indexPath:indexPath];
}

- (void)didAddStickTopSessionWithModel:(NEConversationListModel *)model indexPath:(NSIndexPath *)indexPath {
  [self didAddStickTopSession:model indexPath:indexPath];
}

- (void)onTopRecentAtIndexPathWithConversation:(V2NIMConversation *)conversation
                                     indexPath:(NSIndexPath *)indexPath
                                         isTop:(BOOL)isTop
                                    completion:(void (^)(NSError *))completion {
  if (isTop) {
    [self.viewModel removeStickTopWithConversation:conversation :completion];
  } else {
    [self.viewModel addStickTopWithConversation:conversation :completion];
  }
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

- (void)setTopConstant:(CGFloat)topConstant {
  _topConstant = topConstant;
  self.bodyTopViewTopAnchor.constant = topConstant;
}

- (void)setBodyBottomViewHeight:(CGFloat)bodyBottomViewHeight {
  _bodyBottomViewHeight = bodyBottomViewHeight;
  self.bodyBottomViewHeightAnchor.constant = bodyBottomViewHeight;
  self.bodyBottomView.hidden = (bodyBottomViewHeight <= 0.0);
}

- (void)setAdaptiveStickTopHeight:(CGFloat)adaptiveStickTopHeight {
  _adaptiveStickTopHeight = adaptiveStickTopHeight;
  if (adaptiveStickTopHeight <= 0) {
    return;
  }
  CGFloat width = CGRectGetWidth(self.view.frame);
  BOOL isNormal = NEConversationIsNormalStyle();
  CGFloat inset = isNormal ? 10.0 : 4.0;
  self.stickTopCollectionView.frame = CGRectMake(inset, 0.0, width - inset * 2, adaptiveStickTopHeight);
  self.pinUserDividerLine.frame = CGRectMake(-inset, adaptiveStickTopHeight - 1.0, width + inset * 2, 1.0);
  if (self.tableView.tableHeaderView == self.stickTopCollectionView) {
    // 重新赋一次 header，让 UITableView 重算 header 高度。
    [self.tableView beginUpdates];
    self.tableView.tableHeaderView = self.stickTopCollectionView;
    [self.tableView endUpdates];
  }
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

- (UICollectionView *)stickTopCollcetionView {
  return self.stickTopCollectionView;
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

#pragma mark - Public controller compatibility

@implementation NEConversationViewController

@dynamic delegate;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [super initWithDataSourceType:NEConversationDataSourceTypeCloud];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithDataSourceType:NEConversationDataSourceTypeCloud];
}

- (void)setupSubviews {
  [super setupSubviews];
}

- (void)initialConfig {
  [super initialConfig];
}

- (void)brandBtnClick {
  [super brandBtnClick];
}

- (void)searchAction {
  [super searchAction];
}

- (void)didClickAddBtn {
  [super didClickAddBtn];
}

- (void)openScanQR {
  [super openScanQR];
}

- (BOOL)handleQRScanResult:(NSString *)result {
  return [super handleQRScanResult:result];
}

- (void)createDiscussGroup {
  [super createDiscussGroup];
}

- (void)createSeniorGroup {
  [super createSeniorGroup];
}

- (void)subscribeVisibleRows {
  [super subscribeVisibleRows];
}

- (NSArray<NEConversationListModel *> *)displayConversationList {
  return [self currentConversationData];
}

- (void)reloadData {
  [super reloadData];
}

- (void)reloadTableView {
  [super reloadTableView];
}

- (void)renderConversationList {
  [self scheduleConversationListRenderIncludingStickTop:YES];
}

- (void)loadMoreStateChange:(BOOL)finish {
  [super loadMoreStateChange:finish];
}

@end

@implementation ConversationController

- (UIButton *)searchBarButton {
  return self.navigationView.searchBtn;
}

- (UIView *)pinUserDividerLine {
  return [super pinUserDividerLine];
}

- (UIButton *)addBarButton {
  return self.navigationView.addBtn;
}

- (void)changeLanguage {
  [super changeLanguage];
}

- (void)setupNormalStickTopView {
  [self setupStickTopView];
}

@end

@implementation FunConversationController

- (void)viewDidLoad {
  [super viewDidLoad];
  // 左滑删除为红色、左滑置顶为统一主色、断网条为浅红底 + 50% 黑字。
  self.deleteButtonBackgroundColor = [NEConstant hexRGB:0xE75E58];
  self.brokenNetworkView.backgroundColor = [NEConstant hexRGB:0xFCEEEE];
  self.brokenNetworkView.contentLabel.textColor = [UIColor colorWithWhite:0 alpha:0.5];
}

- (FunSearchView *)searchView {
  return [super searchView];
}

- (void)changeLanguage {
  [super changeLanguage];
}

- (void)setupFunStickTopView {
  [self setupStickTopView];
}

@end
