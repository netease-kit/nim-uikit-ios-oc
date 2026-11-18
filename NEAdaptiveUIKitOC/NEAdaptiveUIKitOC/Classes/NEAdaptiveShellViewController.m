// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveShellViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "NEAdaptiveLayoutPolicy.h"
#import "NEAdaptiveRailPageNavigation.h"
#import "NEAdaptiveUIKitOCInternals.h"
#import "NEAdaptiveWindowContext.h"

#pragma mark - 列底色

@implementation NEAdaptiveColumnColors

- (instancetype)initWithMaster:(UIColor *)master detail:(UIColor *)detail {
  self = [super init];
  if (self) {
    _master = master;
    _detail = detail;
  }
  return self;
}

@end

#pragma mark - 尾部安全区归属

/// 整段尾部安全区，UIKit 会据此把左滑操作按钮再向内缩进。UIKit 允许负的
/// `additionalSafeAreaInsets`，因此可以按页面抵消继承值而不改页面自身布局。
static CGFloat NEAdaptiveTrailingInsetCancellation(CGFloat safeAreaRight, CGFloat applied) {
  CGFloat inherited = safeAreaRight - applied;
  return fabs(inherited) > 0.5 ? -inherited : 0;
}

typedef struct {
  BOOL hasOcclusionBottom;
  CGFloat occlusionBottom;
  BOOL hasOcclusionCenterX;
  CGFloat occlusionCenterX;
  BOOL hasDivisionMaxX;
  CGFloat divisionMaxX;
  BOOL hasDivisionMinX;
  CGFloat divisionMinX;
} NEAdaptiveReservedRegionMetrics;

static NEAdaptiveReservedRegionMetrics NEAdaptiveEmptyMetrics(void) {
  NEAdaptiveReservedRegionMetrics metrics;
  memset(&metrics, 0, sizeof(metrics));
  return metrics;
}

#pragma mark - 决策工具

static BOOL NEAdaptiveDecisionHasMode(NEAdaptiveLayoutDecision decision, BOOL hasDecision) {
  return hasDecision && decision.hasMode;
}

static BOOL NEAdaptiveDecisionIsPaired(NEAdaptiveLayoutDecision decision, BOOL hasDecision) {
  if (!NEAdaptiveDecisionHasMode(decision, hasDecision)) {
    return NO;
  }
  return decision.mode == NEAdaptiveLayoutModeMedium || decision.mode == NEAdaptiveLayoutModeExpanded;
}

static BOOL NEAdaptiveDecisionIsCompact(NEAdaptiveLayoutDecision decision, BOOL hasDecision) {
  return NEAdaptiveDecisionHasMode(decision, hasDecision) && decision.mode == NEAdaptiveLayoutModeCompact;
}

static BOOL NEAdaptiveDecisionNeedsLegacy(NEAdaptiveLayoutDecision decision, BOOL hasDecision) {
  return hasDecision && !decision.hasMode;
}

static BOOL NEAdaptiveDecisionsEqual(NEAdaptiveLayoutDecision lhs, NEAdaptiveLayoutDecision rhs) {
  return lhs.hasMode == rhs.hasMode && lhs.mode == rhs.mode && lhs.fallback == rhs.fallback &&
         lhs.contentWidth == rhs.contentWidth && lhs.contentHeight == rhs.contentHeight &&
         lhs.masterWidth == rhs.masterWidth && lhs.detailWidth == rhs.detailWidth &&
         lhs.dividerWidth == rhs.dividerWidth;
}

static NSString *NEAdaptiveModeName(NEAdaptiveLayoutDecision decision, BOOL hasDecision) {
  if (!NEAdaptiveDecisionHasMode(decision, hasDecision)) {
    return @"legacy";
  }
  switch (decision.mode) {
    case NEAdaptiveLayoutModeCompact:
      return @"compact";
    case NEAdaptiveLayoutModeMedium:
      return @"medium";
    case NEAdaptiveLayoutModeExpanded:
      return @"expanded";
  }
  return @"legacy";
}

/// 同一个入口重复入栈时复用已有页面：页面用稳定的 `restorationIdentifier` 声明身份。
static BOOL NEAdaptiveReuseExistingPage(UIViewController *controller, UINavigationController *navigation) {
  if (controller.restorationIdentifier.length == 0) {
    (void)controller.view;
  }
  NSString *identity = controller.restorationIdentifier;
  if (identity.length == 0) {
    return NO;
  }
  UIViewController *existing = nil;
  for (UIViewController *page in navigation.viewControllers) {
    if ([page.restorationIdentifier isEqualToString:identity]) {
      existing = page;
      break;
    }
  }
  if (!existing || existing == controller) {
    return NO;
  }
  if (navigation.topViewController == existing) {
    return YES;
  }
  [navigation popToViewController:existing animated:YES];
  return YES;
}

@interface NEAdaptiveShellViewController () <UITabBarDelegate>

@property (nonatomic, strong, readwrite) NEAdaptiveShellConfiguration *configuration;
@property (nonatomic, copy, readwrite) NSArray<UINavigationController *> *sections;
@property (nonatomic, strong, readwrite) NEChatDetailHostController *detailHost;
@property (nonatomic, strong, readwrite) NEConversationNavigationCoordinator *conversationCoordinator;
@property (nonatomic, assign, readwrite) NSInteger selectedSectionIndex;
@property (nonatomic, assign, readwrite) BOOL isUsingLegacyLayout;

@end

@implementation NEAdaptiveShellViewController {
  UIStackView *_rail;
  UIView *_railBackground;
  UIScrollView *_railScroll;
  UIButton *_backButton;
  UIStackView *_railActionStack;
  NSMutableArray<UIView *> *_railActionContainers;
  NSMutableArray<UIButton *> *_railActionButtons;
  NSMutableArray<UILabel *> *_railActionBadges;
  NSArray<NEAdaptiveRailAction *> *_railActions;
  void (^_railBackHandler)(void);
  void (^_adaptiveOverlayDismissHandler)(void);
  BOOL _adaptiveOverlayPresented;

  NSMutableDictionary<NSValue *, NEAdaptiveRailPageNavigation *> *_railNavigationBindings;
  BOOL _railRefreshScheduled;
  NSMutableArray<id> *_notificationTokens;

  UITabBar *_fallbackTabBar;
  UIView *_contentHost;
  UIView *_contentTopMasterGap;
  UIView *_contentTopDetailGap;
  UIView *_dividerView;

  NSMutableArray<NEAdaptiveSectionHost *> *_sectionHosts;
  NSMutableArray<NEAdaptiveNavigationObserver *> *_sectionStackObservations;
  NEAdaptiveNavigationObserver *_chatStackObservation;
  NSMutableArray<UIButton *> *_railButtons;
  NSMutableArray<UIView *> *_railBadgeViews;

  NEAdaptiveWindowContext *_context;
  __weak UIWindow *_observedWindow;

  NEAdaptiveLayoutDecision _decision;
  BOOL _hasDecision;
  BOOL _compactShowsDetail;
  BOOL _legacyFallbackPending;
  BOOL _shellVisible;
  BOOL _isTransferringConversationSectionChild;
  NSNumber *_compactChatOriginSection;
  NSNumber *_lastLaidOutMode;
  BOOL _prefersConversationList;
  __weak UIViewController *_lastDetailTopController;
}

#pragma mark - 生命周期

- (instancetype)initWithSections:(NSArray<UINavigationController *> *)sections
        detailNavigationController:(UINavigationController *)detailNavigationController
                   configuration:(NEAdaptiveShellConfiguration *)configuration {
  NSParameterAssert(sections.count > 0);
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _sections = [sections copy];
    _configuration = configuration;
    _detailHost = [[NEChatDetailHostController alloc] initWithNavigationController:detailNavigationController];
    _conversationCoordinator =
        [[NEConversationNavigationCoordinator alloc] initWithNavigationController:detailNavigationController];
    _selectedSectionIndex = 0;
    _railActionContainers = [NSMutableArray array];
    _railActionButtons = [NSMutableArray array];
    _railActionBadges = [NSMutableArray array];
    _railActions = @[];
    _railNavigationBindings = [NSMutableDictionary dictionary];
    _notificationTokens = [NSMutableArray array];
    _sectionHosts = [NSMutableArray array];
    _sectionStackObservations = [NSMutableArray array];
    _railButtons = [NSMutableArray array];
    _railBadgeViews = [NSMutableArray array];
    _lastLaidOutMode = nil;
  }
  return self;
}

- (void)dealloc {
  [self restoreRailPageNavigation];
  for (id token in _notificationTokens) {
    [[NSNotificationCenter defaultCenter] removeObserver:token];
  }
  [_notificationTokens removeAllObjects];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
  __weak typeof(self) weakSelf = self;
  [super dismissViewControllerAnimated:flag completion:^{
    if (completion) {
      completion();
    }
    NEAdaptiveShellViewController *strongSelf = weakSelf;
    if (!strongSelf || !strongSelf.isViewLoaded) {
      return;
    }
    [strongSelf.view setNeedsLayout];
    [strongSelf.view layoutIfNeeded];
  }];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.view setNeedsLayout];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  NEAdaptiveShellConfiguration *configuration = self.configuration;
  self.view.backgroundColor = configuration.contentBackgroundColor;

  _contentHost = [[UIView alloc] init];
  _contentHost.clipsToBounds = YES;
  _contentHost.backgroundColor = configuration.contentBackgroundColor;
  [self.view addSubview:_contentHost];

  _contentTopMasterGap = [[UIView alloc] init];
  _contentTopMasterGap.userInteractionEnabled = NO;
  _contentTopMasterGap.backgroundColor = configuration.contentBackgroundColor;
  [self.view addSubview:_contentTopMasterGap];

  _contentTopDetailGap = [[UIView alloc] init];
  _contentTopDetailGap.userInteractionEnabled = NO;
  _contentTopDetailGap.backgroundColor = configuration.contentBackgroundColor;
  [self.view addSubview:_contentTopDetailGap];

  _rail = [[UIStackView alloc] init];
  _rail.axis = UILayoutConstraintAxisVertical;
  _rail.alignment = UIStackViewAlignmentFill;
  _rail.spacing = configuration.railItemSpacing;

  _railBackground = [[UIView alloc] init];
  _railScroll = [[UIScrollView alloc] init];
  _railScroll.showsVerticalScrollIndicator = NO;
  _railScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  [_railScroll addSubview:_rail];
  [self.view addSubview:_railBackground];
  [self.view addSubview:_railScroll];

  [self registerNotifications];

  _railActionStack = [[UIStackView alloc] init];
  _railActionStack.axis = UILayoutConstraintAxisVertical;
  _railActionStack.alignment = UIStackViewAlignmentCenter;
  _railActionStack.spacing = configuration.railActionSpacing;
  _railActionStack.hidden = YES;
  [self.view addSubview:_railActionStack];

  _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.view addSubview:_backButton];
  [self applyBackButtonStyle];
  _backButton.accessibilityIdentifier = @"id.adaptive.back";
  [_backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];

  _fallbackTabBar = [[UITabBar alloc] init];
  _fallbackTabBar.delegate = self;
  NSMutableArray<UITabBarItem *> *items = [NSMutableArray array];
  for (UINavigationController *section in self.sections) {
    if (section.tabBarItem) {
      [items addObject:section.tabBarItem];
    }
  }
  _fallbackTabBar.items = items;
  _fallbackTabBar.selectedItem = self.sections.firstObject.tabBarItem;
  _fallbackTabBar.hidden = YES;
  [self.view addSubview:_fallbackTabBar];

  for (UINavigationController *section in self.sections) {
    [_sectionHosts addObject:[[NEAdaptiveSectionHost alloc] initWithContent:section]];
  }
  __weak typeof(self) weakSelf = self;
  for (NSUInteger index = 1; index < _sectionHosts.count; index++) {
    NEAdaptiveSectionHost *host = _sectionHosts[index];
    host.makeDetailNavigation = ^UINavigationController *{
      NEAdaptiveShellViewController *strongSelf = weakSelf;
      return strongSelf.sectionDetailNavigationFactory ? strongSelf.sectionDetailNavigationFactory() : [[UINavigationController alloc] init];
    };
    host.makeEmptyDetail = ^UIViewController *{
      NEAdaptiveShellViewController *strongSelf = weakSelf;
      return strongSelf.sectionEmptyDetailFactory ? strongSelf.sectionEmptyDetailFactory(index) : [[UIViewController alloc] init];
    };
    host.onDetailNavigationCreated = ^(UINavigationController *navigation) {
      NEAdaptiveShellViewController *strongSelf = weakSelf;
      if (strongSelf.onSectionDetailNavigationCreated) {
        strongSelf.onSectionDetailNavigationCreated(navigation);
      }
    };
    host.onStackChanged = ^{
      [weakSelf layoutContent];
    };
  }

  for (UINavigationController *navigation in self.sections) {
    NEAdaptiveNavigationObserver *observer =
        [[NEAdaptiveNavigationObserver alloc] initWithNavigationController:navigation
                                                                  didShow:^{
      NEAdaptiveShellViewController *strongSelf = weakSelf;
      if (!strongSelf || !strongSelf.isViewLoaded) {
        return;
      }
      [strongSelf layoutContent];
    }];
    observer.willShow = ^(UIViewController *page) {
      [weakSelf prepareRailNavigationBeforeTransition:page];
    };
    [_sectionStackObservations addObject:observer];
  }

  _chatStackObservation =
      [[NEAdaptiveNavigationObserver alloc] initWithNavigationController:self.conversationCoordinator.navigationController
                                                                 didShow:^{
    [weakSelf layoutContent];
  }];
  _chatStackObservation.willShow = ^(UIViewController *page) {
    [weakSelf prepareRailNavigationBeforeTransition:page];
  };

  // （如文本详情）在自身 present 前显式设置。
  NEAdaptiveSectionHost *firstHost = _sectionHosts.firstObject;
  [self addChildViewController:firstHost];
  [_contentHost addSubview:firstHost.view];
  [firstHost didMoveToParentViewController:self];

  [self addChildViewController:self.detailHost];
  [_contentHost addSubview:self.detailHost.view];
  [self.detailHost didMoveToParentViewController:self];

  for (NSUInteger index = 1; index < _sectionHosts.count; index++) {
    NEAdaptiveSectionHost *host = _sectionHosts[index];
    [self addChildViewController:host];
    [_contentHost addSubview:host.view];
    [host didMoveToParentViewController:self];
    host.view.hidden = YES;
  }

  _dividerView = [[UIView alloc] init];
  _dividerView.userInteractionEnabled = NO;
  _dividerView.hidden = YES;
  _dividerView.accessibilityIdentifier = @"id.adaptive.chat.divider";
  [_contentHost addSubview:_dividerView];

  [self.sections enumerateObjectsUsingBlock:^(UINavigationController *section, NSUInteger index, BOOL *stop) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = (NSInteger)index;
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    [button addTarget:self action:@selector(sectionTapped:) forControlEvents:UIControlEventTouchUpInside];
    [[button.heightAnchor constraintEqualToConstant:configuration.railItemHeight] setActive:YES];

    UIView *badge = [[UIView alloc] init];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.backgroundColor = [UIColor systemRedColor];
    badge.layer.cornerRadius = 4;
    badge.hidden = YES;
    badge.userInteractionEnabled = NO;
    [button addSubview:badge];
    [NSLayoutConstraint activateConstraints:@[
      [badge.widthAnchor constraintEqualToConstant:8],
      [badge.heightAnchor constraintEqualToConstant:8],
      [badge.topAnchor constraintEqualToAnchor:button.topAnchor constant:8],
      [badge.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-8],
    ]];

    [self->_rail addArrangedSubview:button];
    [self->_railButtons addObject:button];
    [self->_railBadgeViews addObject:badge];
    button.accessibilityIdentifier = section.tabBarItem.accessibilityIdentifier;
  }];

  [self updateRailItems];
}

- (void)registerNotifications {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  __weak typeof(self) weakSelf = self;
  // 不要再监听进程级的 UINavigationControllerDidShowViewControllerNotification，
  id overlayPresent = [center addObserverForName:@"NEAdaptiveOverlayDidPresent"
                                          object:nil
                                           queue:[NSOperationQueue mainQueue]
                                      usingBlock:^(NSNotification *note) {
    NEAdaptiveShellViewController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    void (^dismiss)(void) = note.userInfo[@"dismiss"];
    strongSelf->_adaptiveOverlayDismissHandler = dismiss;
    strongSelf->_adaptiveOverlayPresented = YES;
    [strongSelf.view setNeedsLayout];
    [strongSelf.view layoutIfNeeded];
  }];
  id overlayDismiss = [center addObserverForName:@"NEAdaptiveOverlayDidDismiss"
                                          object:nil
                                           queue:[NSOperationQueue mainQueue]
                                      usingBlock:^(NSNotification *note) {
    NEAdaptiveShellViewController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf->_adaptiveOverlayDismissHandler = nil;
    strongSelf->_adaptiveOverlayPresented = NO;
    [strongSelf.view setNeedsLayout];
    [strongSelf.view layoutIfNeeded];
  }];
  id previewDismiss = [center addObserverForName:@"NEAdaptivePreviewDidDismiss"
                                          object:nil
                                           queue:[NSOperationQueue mainQueue]
                                      usingBlock:^(NSNotification *note) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NEAdaptiveShellViewController *strongSelf = weakSelf;
      if (!strongSelf || !strongSelf.isViewLoaded) {
        return;
      }
      [strongSelf.view setNeedsLayout];
      [strongSelf.view layoutIfNeeded];
    });
  }];
  id presentationChange = [center addObserverForName:@"NEAdaptivePresentationDidChange"
                                              object:nil
                                               queue:[NSOperationQueue mainQueue]
                                          usingBlock:^(NSNotification *note) {
    [weakSelf prepareRailNavigationForPresentationChange];
  }];
  id actionsChanged = [center addObserverForName:@"NENavigationViewDidChangeActions"
                                          object:nil
                                           queue:[NSOperationQueue mainQueue]
                                      usingBlock:^(NSNotification *note) {
    [weakSelf refreshRailNavigation];
  }];
  [_notificationTokens addObjectsFromArray:@[ overlayPresent, overlayDismiss, previewDismiss, presentationChange, actionsChanged ]];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  _shellVisible = YES;
  [self refreshWindow];
  [self updateVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  _shellVisible = NO;
  [self updateVisibility];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self refreshWindow];
  [self layoutContent];
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  [self refreshWindow];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  __weak typeof(self) weakSelf = self;
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [weakSelf refreshWindow];
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [weakSelf refreshWindow];
  }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  [self refreshWindow];
}

#pragma mark - 计算属性

- (BOOL)isUsingAdaptiveLayout {
  return !self.isUsingLegacyLayout && NEAdaptiveDecisionHasMode(_decision, _hasDecision);
}

- (BOOL)isShowingPairedContent {
  return NEAdaptiveDecisionIsPaired(_decision, _hasDecision);
}

- (nullable UIViewController *)activeContentViewController {
  if (self.selectedSectionIndex < 0 || self.selectedSectionIndex >= (NSInteger)self.sections.count) {
    return nil;
  }
  if (self.selectedSectionIndex == 0) {
    if (self.isShowingPairedContent) {
      return self.detailHost.navigationControllerContent.visibleViewController;
    }
    return self.conversationCoordinator.navigationController.visibleViewController;
  }
  if (self.selectedSectionIndex < (NSInteger)_sectionHosts.count) {
    NEAdaptiveSectionHost *host = _sectionHosts[self.selectedSectionIndex];
    if (host.splitDetail.visibleViewController) {
      return host.splitDetail.visibleViewController;
    }
  }
  return self.sections[self.selectedSectionIndex].visibleViewController;
}

#pragma mark - 窗口事实

- (void)refreshWindow {
  if (!self.isViewLoaded) {
    return;
  }
  UIWindow *window = self.view.window;
  if (!window) {
    return;
  }
  if (_observedWindow != window) {
    [_context invalidate];
    _observedWindow = window;
    __weak typeof(self) weakSelf = self;
    _context = [[NEAdaptiveWindowContext alloc] initWithWindow:window
                                                      onChange:^(NEWindowSnapshot *snapshot) {
      [weakSelf applySnapshot:snapshot];
    }];
  }
  [_context refresh];
}

- (void)invalidateWindowContext {
  [_context invalidate];
  _context = nil;
  _observedWindow = nil;
}

- (NSArray<UINavigationController *> *)detachSectionsForLegacyTransfer {
  [self restoreRailPageNavigation];
  [self restoreHostedTrailingSafeArea];
  [self.sections enumerateObjectsUsingBlock:^(UINavigationController *section, NSUInteger index, BOOL *stop) {
    NEAdaptiveSectionHost *host = self->_sectionHosts[index];
    [host detachContentForTransfer];
    if (index < self->_sectionStackObservations.count) {
      section.delegate = self->_sectionStackObservations[index].originalDelegate;
    }
  }];
  [_sectionStackObservations removeAllObjects];
  return self.sections;
}

#pragma mark - 会话

- (BOOL)openConversation:(NEConversationOpenIntent *)intent {
  [self dismissColumnPresentations];
  // 从通讯录/我的分区打开会话：共享详情列先回到会话列表的空占位，再压入聊天页。
  if (self.selectedSectionIndex != 0) {
    [self.conversationCoordinator reset];
  }
  _compactChatOriginSection =
      (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) && self.selectedSectionIndex != 0)
          ? @(self.selectedSectionIndex)
          : nil;
  if (![self.conversationCoordinator open:intent]) {
    return NO;
  }
  _prefersConversationList = NO;
  _compactShowsDetail = YES;
  if (self.selectedSectionIndex != 0) {
    self.selectedSectionIndex = 0;
    [self updateRailItems];
    if (self.onSectionSelected) {
      self.onSectionSelected(0);
    }
  }
  [self layoutContent];
  [self refreshRailNavigation];
  NSString *conversationId = intent.parameters[@"conversationId"];
  if ([conversationId isKindOfClass:[NSString class]] && self.onConversationOpened) {
    self.onConversationOpened(conversationId);
  }
  return YES;
}

- (void)clearConversationIfNeeded:(NSString *)conversationId {
  NEConversationOpenIntent *activeIntent = self.conversationCoordinator.activeIntent;
  id activeConversationId = activeIntent.parameters[@"conversationId"];
  if (!activeIntent || ![activeConversationId isKindOfClass:[NSString class]] ||
      ![activeConversationId isEqualToString:conversationId]) {
    return;
  }
  [self dismissColumnPresentations];
  [self.conversationCoordinator reset];
  _compactShowsDetail = NO;
  [self layoutContent];
}

- (void)clearActiveConversation {
  if (self.conversationCoordinator.activeIntent == nil) {
    return;
  }
  [self dismissColumnPresentations];
  [self.conversationCoordinator reset];
  _compactShowsDetail = NO;
  [self layoutContent];
}

- (void)showConversationList {
  if (self.selectedSectionIndex != 0) {
    return;
  }
  if (!NEAdaptiveDecisionIsCompact(_decision, _hasDecision) && !self.isUsingLegacyLayout) {
    return;
  }
  if ([self restoreCompactChatOriginSection]) {
    return;
  }
  if (!self.isUsingLegacyLayout) {
    [self dismissColumnPresentations];
    [self.conversationCoordinator reset];
  }
  _prefersConversationList = YES;
  _compactShowsDetail = NO;
  [self layoutContent];
}

- (void)selectSection:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)self.sections.count) {
    return;
  }
  _compactChatOriginSection = nil;
  [self dismissColumnPresentations];
  _prefersConversationList = NO;
  BOOL changed = self.selectedSectionIndex != index;
  if (index == 0) {
    [self.conversationCoordinator reset];
    UINavigationController *messages = self.sections.firstObject;
    if (messages.viewControllers.count > 1) {
      [messages setViewControllers:@[ messages.viewControllers.firstObject ] animated:NO];
    }
    _compactShowsDetail = NO;
  } else if (index < (NSInteger)_sectionHosts.count) {
    for (NSUInteger hostIndex = 1; hostIndex < _sectionHosts.count; hostIndex++) {
      [_sectionHosts[hostIndex] resetDetail];
    }
    UIViewController *placeholder = self.sectionEmptyDetailFactory ? self.sectionEmptyDetailFactory(index)
                                                                   : [[UIViewController alloc] init];
    [self.conversationCoordinator showPlaceholder:placeholder];
    _compactShowsDetail = NO;
  }
  self.selectedSectionIndex = index;
  [self updateRailItems];
  if (changed && self.onSectionSelected) {
    self.onSectionSelected(index);
  }
  [self layoutContent];
}

- (BOOL)presentSectionChild:(UIViewController *)controller
    fromNavigationController:(UINavigationController *)navigationController
                     animated:(BOOL)animated {
  __block NSInteger index = NSNotFound;
  [self.sections enumerateObjectsUsingBlock:^(UINavigationController *section, NSUInteger idx, BOOL *stop) {
    if (section == navigationController) {
      index = (NSInteger)idx;
      *stop = YES;
    }
  }];
  if (index == NSNotFound || !NEAdaptiveDecisionIsPaired(_decision, _hasDecision) ||
      self.isUsingLegacyLayout || controller.parentViewController != nil) {
    return NO;
  }
  if (index == 0) {
    // 会话列表是保留的左列；它的一级页面（搜索、加好友、选人、建群）属于右列详情栈。
    UINavigationController *detail = self.conversationCoordinator.navigationController;
    if (detail.viewControllers.count == 0) {
      return NO;
    }
    [self dismissColumnPresentations];
    if (NEAdaptiveReuseExistingPage(controller, detail)) {
      return YES;
    }
    // 一级页面采用"重置右列"的呈现方式：清掉正在展示的聊天，让一级页面成为右列根，
    // 返回直接回到空占位，而不是退回聊天页。
    if (self.conversationCoordinator.activeIntent != nil) {
      [self.conversationCoordinator reset];
    }
    UIViewController *base = self.conversationCoordinator.currentPlaceholder;
    if (base && base != controller) {
      [detail setViewControllers:@[ base, controller ] animated:NO];
    } else {
      [detail setViewControllers:@[ controller ] animated:NO];
    }
    [self layoutContent];
    // 非动画换栈不一定触发 willShow：延后校正一次，确保页面出现前入口已隐藏。
    [self refreshRailNavigation];
    return YES;
  }
  UINavigationController *sharedDetail = self.conversationCoordinator.navigationController;
  if (sharedDetail.viewControllers.count == 0) {
    return NO;
  }
  [self dismissColumnPresentations];
  if (NEAdaptiveReuseExistingPage(controller, sharedDetail)) {
    return YES;
  }
  // 保留占位页作为栈底、页面压栈顶（栈深 2）：栈深 > 1 才会显示返回按钮并预留导航栏高度。
  UIViewController *base = self.conversationCoordinator.currentPlaceholder ?: [[UIViewController alloc] init];
  [sharedDetail setViewControllers:@[ base, controller ] animated:NO];
  [self layoutContent];
  [self refreshRailNavigation];
  return YES;
}

#pragma mark - 侧栏外观

/// 单屏聊天返回入口的系统返回样式：复用 `chevron.left`，与系统返回按钮同形状同字重。
- (void)applyBackButtonStyle {
  NEAdaptiveShellConfiguration *configuration = self.configuration;
  if (configuration.usesSystemBackButtonStyle) {
    UIImageSymbolConfiguration *symbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    UIImage *symbol = [UIImage systemImageNamed:@"chevron.left" withConfiguration:symbolConfiguration];
    [_backButton setImage:(symbol ?: configuration.backImage) forState:UIControlStateNormal];
  } else {
    [_backButton setImage:configuration.backImage forState:UIControlStateNormal];
  }
  _backButton.tintColor = configuration.backTintColor;
  _backButton.accessibilityLabel = configuration.backAccessibilityLabel;
  // 产品稿：返回入口与右侧操作使用同一套圆形控件（浅色底 + 细描边）。
  _backButton.backgroundColor = configuration.railControlBackgroundColor;
  _backButton.layer.cornerRadius = configuration.railBackButtonSize / 2;
  _backButton.layer.borderWidth = configuration.railControlBorderWidth;
  _backButton.layer.borderColor = configuration.railControlBorderColor.CGColor;
  _backButton.clipsToBounds = YES;
}

- (void)updateRailItems {
  if (!self.isViewLoaded) {
    return;
  }
  NEAdaptiveShellConfiguration *configuration = self.configuration;
  [self applyBackButtonStyle];
  _railBackground.backgroundColor = configuration.railBackgroundColor;
  _fallbackTabBar.tintColor = configuration.selectedTintColor;
  if (self.selectedSectionIndex < (NSInteger)self.sections.count) {
    _fallbackTabBar.selectedItem = self.sections[self.selectedSectionIndex].tabBarItem;
  }
  [self.sections enumerateObjectsUsingBlock:^(UINavigationController *section, NSUInteger index, BOOL *stop) {
    if (index >= self->_railButtons.count) {
      return;
    }
    UITabBarItem *item = section.tabBarItem;
    if (!item) {
      return;
    }
    UIButton *button = self->_railButtons[index];
    BOOL selected = (NSInteger)index == self.selectedSectionIndex;

    UIButtonConfiguration *appearance = [UIButtonConfiguration plainButtonConfiguration];
    appearance.title = item.title;
    appearance.image = selected ? (item.selectedImage ?: item.image) : item.image;
    appearance.imagePlacement = NSDirectionalRectEdgeTop;
    appearance.imagePadding = 8;
    appearance.contentInsets = NSDirectionalEdgeInsetsZero;
    appearance.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attributes) {
      NSMutableDictionary<NSAttributedStringKey, id> *updated = [attributes mutableCopy];
      updated[NSFontAttributeName] = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
      return [updated copy];
    };
    button.configuration = appearance;
    button.tintColor = selected ? configuration.selectedTintColor : configuration.normalTintColor;
    button.accessibilityLabel = item.title;
    button.accessibilityValue = item.badgeValue;
    button.accessibilityTraits = selected ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
                                          : UIAccessibilityTraitButton;
    if (index < self->_railBadgeViews.count) {
      self->_railBadgeViews[index].hidden = item.badgeValue == nil;
    }
  }];
}

- (void)sectionTapped:(UIButton *)sender {
  [self selectSection:sender.tag];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
  __block NSInteger index = NSNotFound;
  [self.sections enumerateObjectsUsingBlock:^(UINavigationController *section, NSUInteger idx, BOOL *stop) {
    if (section.tabBarItem == item) {
      index = (NSInteger)idx;
      *stop = YES;
    }
  }];
  if (index == NSNotFound) {
    return;
  }
  [self selectSection:index];
}

- (void)backTapped {
  if (_adaptiveOverlayDismissHandler) {
    void (^dismiss)(void) = _adaptiveOverlayDismissHandler;
    _adaptiveOverlayDismissHandler = nil;
    dismiss();
    [self.view setNeedsLayout];
    return;
  }
  if ([self restoreCompactChatOriginSection]) {
    [self.view setNeedsLayout];
    return;
  }
  if (_railBackHandler) {
    _railBackHandler();
  }
  [self.view setNeedsLayout];
}

- (BOOL)restoreCompactChatOriginSection {
  if (self.isUsingLegacyLayout || !NEAdaptiveDecisionIsCompact(_decision, _hasDecision) ||
      _compactChatOriginSection == nil) {
    return NO;
  }
  NSInteger origin = _compactChatOriginSection.integerValue;
  _compactChatOriginSection = nil;
  [self dismissColumnPresentations];
  [self.conversationCoordinator reset];
  _compactShowsDetail = NO;
  _prefersConversationList = NO;
  self.selectedSectionIndex = origin;
  [self updateRailItems];
  if (self.onSectionSelected) {
    self.onSectionSelected(origin);
  }
  [self layoutContent];
  return YES;
}

- (void)railActionTapped:(UIButton *)sender {
  if (sender.tag < 0 || sender.tag >= (NSInteger)_railActions.count) {
    return;
  }
  [_railActions[sender.tag] perform];
}

- (void)prepareRailNavigationForPresentationChange {
  if (!self.isViewLoaded || !self.isUsingAdaptiveLayout) {
    return;
  }
  BOOL compactChat = NEAdaptiveDecisionIsCompact(_decision, _hasDecision) &&
                     self.selectedSectionIndex == 0 && _compactShowsDetail;
  [self syncRailNavigationWithLegacy:NO compactChat:compactChat];
  [self.view setNeedsLayout];
  [self refreshRailNavigation];
}

- (void)refreshRailNavigation {
  if (!self.isViewLoaded || _railRefreshScheduled) {
    return;
  }
  _railRefreshScheduled = YES;
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    NEAdaptiveShellViewController *strongSelf = weakSelf;
    if (!strongSelf || !strongSelf.isViewLoaded) {
      return;
    }
    strongSelf->_railRefreshScheduled = NO;
    [strongSelf layoutContent];
  });
}

#pragma mark - 侧栏承载链

///
/// 只有 `.overCurrentContext` 且呈现上下文确实落在该列的页面才视为"列内覆盖"；
/// 系统窗口级弹层，同样不参与列内链。
- (NSArray<UIViewController *> *)resolveRailColumnPresentationPages {
  if (!self.isUsingAdaptiveLayout) {
    return @[];
  }
  UINavigationController *navigation = nil;
  if (self.isShowingPairedContent) {
    navigation = self.detailHost.navigationControllerContent;
  } else if (self.selectedSectionIndex == 0) {
    navigation = _compactShowsDetail ? self.conversationCoordinator.navigationController
                                     : self.sections.firstObject;
  } else if (self.selectedSectionIndex < (NSInteger)self.sections.count) {
    navigation = self.sections[self.selectedSectionIndex];
  } else {
    return @[];
  }

  // 列顶页面用导航栈顶而不是 `visibleViewController`：后者在有 present 页面时
  // 可能直接返回 present 页面，导致底层承载页从链里丢失。
  UIViewController *base = navigation.viewControllers.lastObject;
  NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
  if (base) {
    [pages addObject:base];
  }
  UIViewController *presented = navigation.presentedViewController ?: base.presentedViewController;
  while (presented) {
    if ([presented isKindOfClass:[UIAlertController class]]) {
      break;
    }
    UIViewController *presenter = presented.presentingViewController;
    UIViewController *previous = pages.lastObject;
    BOOL insideColumn = presenter == navigation || presenter == previous ||
                        (presenter != nil && [presenter.view isDescendantOfView:navigation.view]);
    if (presented.modalPresentationStyle != UIModalPresentationOverCurrentContext || !insideColumn) {
      break;
    }
    UIViewController *resolved = [presented isKindOfClass:[UINavigationController class]]
                                     ? ((UINavigationController *)presented).visibleViewController
                                     : presented;
    if (!resolved) {
      break;
    }
    [pages addObject:resolved];
    presented = resolved.presentedViewController;
  }
  UIViewController *overlay = [NEAdaptiveShellViewController columnOverlayPageIn:pages.lastObject];
  if (overlay) {
    [pages addObject:overlay];
  }
  return pages;
}

/// 列内嵌页面的接入约定：直接挂在承载页下、覆盖整列，并在根视图上以
+ (nullable UIViewController *)columnOverlayPageIn:(nullable UIViewController *)page {
  if (!page) {
    return nil;
  }
  for (UIViewController *child in page.childViewControllers.reverseObjectEnumerator) {
    if (child.isViewLoaded && [child.view.accessibilityIdentifier isEqualToString:@"id.adaptive.columnOverlay"]) {
      return child;
    }
  }
  return nil;
}

- (void)syncRailNavigationWithLegacy:(BOOL)legacy compactChat:(BOOL)compactChat {
  if (legacy) {
    [self restoreRailPageNavigation];
    _railActions = @[];
    [self updateRailActionButtons];
    __weak typeof(self) weakSelf = self;
    _railBackHandler = compactChat ? ^{
      [weakSelf showConversationList];
    } : nil;
    return;
  }
  NSArray<UIViewController *> *chain = [self resolveRailColumnPresentationPages];
  NSMutableSet<NSValue *> *chainKeys = [NSMutableSet set];
  for (UIViewController *page in chain) {
    [chainKeys addObject:[NSValue valueWithPointer:(__bridge const void *)page]];
  }
  // 离开承载链的页面（pop / dismiss / 切换列）归还原入口。
  for (NSValue *key in _railNavigationBindings.allKeys) {
    if ([chainKeys containsObject:key]) {
      continue;
    }
    NEAdaptiveRailPageNavigation *binding = _railNavigationBindings[key];
    binding.onChange = nil;
    [binding restore];
    [_railNavigationBindings removeObjectForKey:key];
  }
  for (UIViewController *page in chain) {
    [self bindRailNavigationIfNeededForPage:page];
  }
  UIViewController *topPage = chain.lastObject;
  NEAdaptiveRailPageNavigation *topBinding =
      topPage ? _railNavigationBindings[[NSValue valueWithPointer:(__bridge const void *)topPage]] : nil;
  _railActions = topBinding ? [topBinding trailingActions] : @[];
  [self updateRailActionButtons];
  _railBackHandler = [self makeRailBackHandlerForPage:topPage compactChat:compactChat binding:topBinding];
}

/// 为承载页建立（或复用）入口绑定，并立即隐藏页面自己的入口。
- (nullable NEAdaptiveRailPageNavigation *)bindRailNavigationIfNeededForPage:(UIViewController *)page {
  NSValue *key = [NSValue valueWithPointer:(__bridge const void *)page];
  NEAdaptiveRailPageNavigation *existing = _railNavigationBindings[key];
  if (existing) {
    if ([existing isValidForPage:page]) {
      [existing refreshSuppressedSystemItems];
      return existing;
    }
    existing.onChange = nil;
    [existing restore];
    [_railNavigationBindings removeObjectForKey:key];
  }
  (void)page.view;
  NEAdaptiveRailPageNavigation *binding = [NEAdaptiveRailPageNavigation makeForPage:page];
  if (!binding) {
    return nil;
  }
  __weak typeof(self) weakSelf = self;
  binding.onChange = ^{
    [weakSelf refreshRailNavigation];
  };
  [binding suppress];
  _railNavigationBindings[key] = binding;
  return binding;
}

- (void)prepareRailNavigationBeforeTransition:(UIViewController *)incoming {
  if (!self.isViewLoaded || !self.isUsingAdaptiveLayout) {
    return;
  }
  BOOL isRailColumn = NO;
  if (self.isShowingPairedContent) {
    isRailColumn = incoming.navigationController == self.detailHost.navigationControllerContent;
  } else {
    isRailColumn = incoming.navigationController == self.conversationCoordinator.navigationController ||
                   (self.selectedSectionIndex < (NSInteger)self.sections.count &&
                    incoming.navigationController == self.sections[self.selectedSectionIndex]);
  }
  if (isRailColumn) {
    [self bindRailNavigationIfNeededForPage:incoming];
  } else {
    BOOL compactChat = NEAdaptiveDecisionIsCompact(_decision, _hasDecision) &&
                       self.selectedSectionIndex == 0 && _compactShowsDetail;
    [self syncRailNavigationWithLegacy:NO compactChat:compactChat];
  }
  [self.view setNeedsLayout];
  // 页面可能在自己的 viewWillAppear 里重配导航栏（例如系统导航开关），转场完成后再校正一次。
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf refreshRailNavigation];
  });
  id<UIViewControllerTransitionCoordinator> coordinator = incoming.navigationController.transitionCoordinator;
  [coordinator animateAlongsideTransition:nil
                               completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [weakSelf refreshRailNavigation];
  }];
}

- (void)restoreRailPageNavigation {
  for (NEAdaptiveRailPageNavigation *binding in _railNavigationBindings.allValues) {
    binding.onChange = nil;
    [binding restore];
  }
  [_railNavigationBindings removeAllObjects];
}

/// 返回入口语义：
/// - 其它页面优先转发页面自己的返回按钮，保留清理未读、二次确认等语义；
- (nullable void (^)(void))makeRailBackHandlerForPage:(nullable UIViewController *)page
                                           compactChat:(BOOL)compactChat
                                               binding:(nullable NEAdaptiveRailPageNavigation *)binding {
  if (!page) {
    return nil;
  }
  UINavigationController *chatNavigation = self.conversationCoordinator.navigationController;
  if (compactChat && page == chatNavigation.viewControllers.firstObject) {
    __weak typeof(self) weakSelf = self;
    return ^{
      [weakSelf showConversationList];
    };
  }
  NEAdaptiveRailAction *pageBack = [binding backAction];
  if (pageBack) {
    return ^{
      [pageBack perform];
    };
  }
  // 只对“真正位于该导航栈顶”的 push 页面补返回：列内嵌页面的 navigationController
  // 来自宿主，若据此 pop 会把底层页面退掉。
  UINavigationController *navigation = page.navigationController;
  if (navigation && navigation.topViewController == page && navigation.viewControllers.count > 1) {
    __weak UINavigationController *weakNavigation = navigation;
    return ^{
      [weakNavigation popViewControllerAnimated:YES];
    };
  }
  return nil;
}

- (void)updateRailActionButtons {
  NEAdaptiveShellConfiguration *configuration = self.configuration;
  _railActionStack.spacing = configuration.railActionSpacing;
  CGFloat actionSize = configuration.railActionButtonSize;
  while (_railActionButtons.count < _railActions.count) {
    // 角标挂在承载容器上、位于按钮之后：圆形按钮的图层描边会压住自身子视图，
    // 角标只有作为按钮的兄弟视图，才能完整覆盖在按钮及其描边之上。
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = configuration.railControlBackgroundColor;
    button.layer.borderWidth = configuration.railControlBorderWidth;
    button.layer.borderColor = configuration.railControlBorderColor.CGColor;
    button.layer.cornerRadius = actionSize / 2;
    button.titleLabel.font = configuration.railActionTextFont;
    button.titleLabel.numberOfLines = 1;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.7;
    [button addTarget:self action:@selector(railActionTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:button];

    UILabel *badge = [[UILabel alloc] init];
    badge.textAlignment = NSTextAlignmentCenter;
    badge.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    badge.textColor = configuration.railBadgeTextColor;
    badge.backgroundColor = configuration.railBadgeBackgroundColor ?: configuration.selectedTintColor;
    badge.layer.cornerRadius = 10;
    badge.clipsToBounds = YES;
    badge.hidden = YES;
    badge.userInteractionEnabled = NO;
    badge.isAccessibilityElement = NO;
    [container addSubview:badge];

    [NSLayoutConstraint activateConstraints:@[
      [container.widthAnchor constraintEqualToConstant:actionSize],
      [container.heightAnchor constraintEqualToConstant:actionSize],
      [button.topAnchor constraintEqualToAnchor:container.topAnchor],
      [button.leftAnchor constraintEqualToAnchor:container.leftAnchor],
      [button.rightAnchor constraintEqualToAnchor:container.rightAnchor],
      [button.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    [_railActionStack addArrangedSubview:container];
    [_railActionContainers addObject:container];
    [_railActionButtons addObject:button];
    [_railActionBadges addObject:badge];
  }

  [_railActionButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger index, BOOL *stop) {
    BOOL visible = index < self->_railActions.count;
    self->_railActionContainers[index].hidden = !visible;
    if (!visible) {
      return;
    }
    NEAdaptiveRailAction *action = self->_railActions[index];
    button.tag = (NSInteger)index;
    [button setTitle:action.title forState:UIControlStateNormal];
    // 产品稿：文本型右侧按钮保留原文案，图标型按钮沿用原图标。
    [button setImage:action.title == nil ? action.image : nil forState:UIControlStateNormal];
    button.tintColor = self.configuration.railActionTextColor;
    [button setTitleColor:self.configuration.railActionTextColor forState:UIControlStateNormal];
    [button setTitleColor:[self.configuration.railActionTextColor colorWithAlphaComponent:0.4]
                 forState:UIControlStateDisabled];
    button.enabled = action.isEnabled;
    button.accessibilityIdentifier = action.identifier ? [@"id.adaptive.action." stringByAppendingString:action.identifier] : nil;
    // 视觉只保留操作名 + 角标；无障碍仍读出页面原本的完整文案（含计数）。
    button.accessibilityLabel = action.accessibilityText;
    [self applyRailBadge:self->_railActionBadges[index] text:action.badge];
  }];
  _railActionStack.hidden = _railActions.count == 0;
}

- (void)applyRailBadge:(UILabel *)badge text:(nullable NSString *)text {
  if (text.length == 0) {
    badge.text = nil;
    badge.hidden = YES;
    return;
  }
  badge.text = text;
  badge.hidden = NO;
  UIFont *font = badge.font ?: [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
  CGFloat width = MAX(20, [text sizeWithAttributes:@{NSFontAttributeName : font}].width + 10);
  CGFloat size = self.configuration.railActionButtonSize;
  // 角标压在圆形按钮右上角；坐标相对承载容器（与按钮同框）。
  badge.frame = CGRectMake(size - width + 4, -4, width, 20);
  badge.layer.cornerRadius = 10;
}

#pragma mark - 决策与布局

- (void)applySnapshot:(NEWindowSnapshot *)snapshot {
  NEAdaptiveLayoutDecision old = _decision;
  BOOL hasOld = _hasDecision;
  BOOL wasSinglePage = NEAdaptiveDecisionIsCompact(old, hasOld) || self.isUsingLegacyLayout;

  NEAdaptiveWindowGeometry geometry = NEAdaptiveWindowGeometryMake(snapshot.size.width, snapshot.size.height,
                                                                  snapshot.safeAreaTop, snapshot.safeAreaLeft,
                                                                  snapshot.safeAreaBottom, snapshot.safeAreaRight);
  _decision = [NEAdaptiveLayoutPolicy resolveWithWindow:geometry
                                          configuration:[self.configuration policyConfiguration]];
  _hasDecision = YES;
  BOOL enteringFallback = NEAdaptiveDecisionNeedsLegacy(_decision, _hasDecision) && !self.isUsingLegacyLayout;
  self.isUsingLegacyLayout = NEAdaptiveDecisionNeedsLegacy(_decision, _hasDecision);
  if (!wasSinglePage && (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) || self.isUsingLegacyLayout)) {
    _compactShowsDetail = self.conversationCoordinator.activeIntent != nil;
  }
  if (enteringFallback) {
    _legacyFallbackPending = self.conversationCoordinator.activeIntent != nil;
  }
  [self layoutContent];
}

/// 右列是否停留在空占位（只有占位页、没有打开任何页面）。
- (BOOL)isDetailHostShowingPlaceholder {
  UINavigationController *navigation = self.detailHost.navigationControllerContent;
  return navigation.viewControllers.count <= 1;
}

- (void)layoutContent {
  if (!self.isViewLoaded) {
    return;
  }
  BOOL enteringFallback = [self syncDecisionToCurrentViewBounds];
  if (!_hasDecision) {
    return;
  }
  if (!NEAdaptiveDecisionIsCompact(_decision, _hasDecision)) {
    _compactChatOriginSection = nil;
  }
  [self.conversationCoordinator syncActiveIntentWithNavigationStack];
  [self syncDetailStackAcrossPosture:NEAdaptiveDecisionIsPaired(_decision, _hasDecision)];
  [self updateVisibility];

  NEAdaptiveShellConfiguration *configuration = self.configuration;
  UIEdgeInsets safeArea = self.view.safeAreaInsets;
  CGRect bounds = self.view.bounds;
  CGRect safe = UIEdgeInsetsInsetRect(bounds, safeArea);
  BOOL legacy = self.isUsingLegacyLayout;
  CGFloat railWidth = configuration.railWidth;
  CGFloat railX = configuration.railUsesTrailingEdge ? CGRectGetMaxX(bounds) - railWidth
                                                     : CGRectGetMaxX(safe) - railWidth;
  NEAdaptiveReservedRegionMetrics railMetrics = [self reservedRegionMetricsWithRailMinX:railX];
  CGFloat tabHeight = legacy ? MIN(49, MAX(0, CGRectGetHeight(safe))) : 0;
  CGFloat contentWidth = legacy ? CGRectGetWidth(safe) : railX - CGRectGetMinX(safe);
  CGFloat contentBottom = legacy ? CGRectGetMaxY(safe) - tabHeight : CGRectGetMaxY(bounds);
  // Duo 在承载页上方留一小段设计间距，颜色取自当前分区，保持条带连续。
  CGFloat contentTop = legacy ? CGRectGetMinY(safe)
                              : CGRectGetMinY(bounds) + MAX(0, configuration.contentTopInset);
  _contentHost.frame = CGRectMake(CGRectGetMinX(safe), contentTop, MAX(0, contentWidth),
                                  MAX(0, contentBottom - contentTop));

  CGFloat topGapHeight = legacy ? 0 : MAX(0, contentTop - CGRectGetMinY(bounds));
  CGFloat masterGapWidth = legacy ? 0 : MIN(MAX(0, _decision.masterWidth), CGRectGetWidth(_contentHost.bounds));
  CGFloat detailGapX = CGRectGetMinX(safe) + masterGapWidth + (legacy ? 0 : configuration.dividerWidth);
  CGFloat detailGapWidth = legacy ? 0
                                  : MAX(0, CGRectGetWidth(_contentHost.bounds) - masterGapWidth - configuration.dividerWidth);
  _contentTopMasterGap.frame = CGRectMake(CGRectGetMinX(safe), CGRectGetMinY(bounds), masterGapWidth, topGapHeight);
  _contentTopDetailGap.frame = CGRectMake(detailGapX, CGRectGetMinY(bounds), detailGapWidth, topGapHeight);
  _contentTopMasterGap.hidden = YES;
  _contentTopDetailGap.hidden = YES;

  _fallbackTabBar.hidden = !legacy;
  _fallbackTabBar.frame = CGRectMake(CGRectGetMinX(safe), CGRectGetMaxY(safe) - tabHeight,
                                     MAX(0, CGRectGetWidth(safe)), tabHeight);
  _rail.hidden = legacy;
  _railScroll.hidden = legacy;
  _railBackground.hidden = legacy;

  BOOL compactChat = (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) || legacy) &&
                     self.selectedSectionIndex == 0 && _compactShowsDetail;
  [self syncRailNavigationWithLegacy:legacy compactChat:compactChat];

  UINavigationController *chatNavigation = self.conversationCoordinator.navigationController;
  BOOL showsBack = legacy ? (compactChat && chatNavigation.viewControllers.count == 1)
                          : (_railBackHandler != nil);
  BOOL showsRailActions = !legacy && _railActions.count > 0;
  BOOL compactSectionChild = NEAdaptiveDecisionIsCompact(_decision, _hasDecision) &&
                             self.selectedSectionIndex > 0 &&
                             self.sections[self.selectedSectionIndex].viewControllers.count > 1;
  BOOL compactConversationSectionChild = NEAdaptiveDecisionIsCompact(_decision, _hasDecision) &&
                                         self.selectedSectionIndex == 0 &&
                                         self.sections.firstObject.viewControllers.count > 1;
  BOOL showsRailItems = !legacy && !compactChat && !compactSectionChild && !compactConversationSectionChild;

  _railBackground.frame = CGRectMake(railX, legacy ? CGRectGetMinY(safe) : CGRectGetMinY(bounds),
                                     configuration.railWidth,
                                     legacy ? CGRectGetHeight(safe) : CGRectGetHeight(bounds));
  CGFloat railHeight = (CGFloat)self.sections.count * configuration.railItemHeight +
                       (CGFloat)MAX(0, (NSInteger)self.sections.count - 1) * configuration.railItemSpacing;
  CGFloat backSize = configuration.railBackButtonSize;
  CGFloat actionSize = configuration.railActionButtonSize;
  CGFloat actionsHeight = showsRailActions
                              ? (CGFloat)_railActions.count * actionSize +
                                    (CGFloat)MAX(0, (NSInteger)_railActions.count - 1) * configuration.railActionSpacing
                              : 0;

  // 官方做法：按 reserved region 的实际 frame 避让系统占位区，拿不到时退回设计常量。
  CGFloat backTop;
  CGFloat maxBackTop = MAX(contentTop, CGRectGetMaxY(safe) - backSize);
  if (legacy) {
    backTop = contentTop;
  } else if (railMetrics.hasOcclusionBottom) {
    backTop = MIN(MAX(contentTop, railMetrics.occlusionBottom), maxBackTop);
  } else {
    backTop = MIN(MAX(contentTop, CGRectGetMinY(bounds) + configuration.railBackTopInset), maxBackTop);
  }
  // 返回按钮固定在垂直轴顶部（HIG），右侧操作紧随其下；窗口高度不足时整组上移。
  if (showsRailActions) {
    CGFloat controlsBottomLimit = CGRectGetMaxY(safe) - backSize - configuration.railActionTopSpacing - actionsHeight;
    backTop = MIN(backTop, MAX(contentTop, controlsBottomLimit));
  }
  CGFloat actionsTop = showsBack ? backTop + backSize + configuration.railActionTopSpacing : backTop;
  CGFloat backAxisX = railX + configuration.railWidth / 2;
  CGFloat backX = legacy ? CGRectGetMinX(safe) : backAxisX - backSize / 2;
  _backButton.frame = CGRectMake(backX, backTop, backSize, backSize);
  _backButton.backgroundColor = legacy ? [UIColor clearColor] : configuration.railControlBackgroundColor;
  _backButton.layer.borderWidth = legacy ? 0 : configuration.railControlBorderWidth;
  _backButton.layer.cornerRadius = legacy ? 0 : backSize / 2;
  _railActionStack.frame = CGRectMake(railX + (configuration.railWidth - actionSize) / 2, actionsTop,
                                      actionSize, actionsHeight);

  CGFloat railTop = legacy ? CGRectGetMinY(safe) : CGRectGetMinY(bounds);
  CGFloat controlsBottom = showsRailActions ? (actionsTop + actionsHeight)
                                            : (showsBack ? backTop + backSize : railTop);
  CGFloat tabsTop = MAX(railTop, controlsBottom + 8);
  CGFloat tabsBottom = MAX(tabsTop, CGRectGetMaxY(safe) - configuration.railItemsBottomInset);
  _railScroll.frame = CGRectMake(railX, tabsTop, configuration.railWidth, MAX(0, tabsBottom - tabsTop));
  _railScroll.contentSize = CGSizeMake(configuration.railWidth, MAX(railHeight, CGRectGetHeight(_railScroll.bounds)));
  _rail.frame = CGRectMake(0, MAX(0, CGRectGetHeight(_railScroll.bounds) - railHeight),
                           configuration.railWidth, railHeight);

  if (self.selectedSectionIndex < (NSInteger)_sectionHosts.count) {
    [self.view bringSubviewToFront:_sectionHosts[self.selectedSectionIndex].view];
    if (self.selectedSectionIndex == 0) {
      [self.view bringSubviewToFront:self.detailHost.view];
    }
    [self.view bringSubviewToFront:_railBackground];
    [self.view bringSubviewToFront:_railScroll];
    [self.view bringSubviewToFront:_rail];
    [self.view bringSubviewToFront:_backButton];
    [self.view bringSubviewToFront:_railActionStack];
  }

  if (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) &&
      self.selectedSectionIndex < (NSInteger)_sectionHosts.count) {
    NEAdaptiveSectionHost *host = _sectionHosts[self.selectedSectionIndex];
    UIViewController *top = host.content.topViewController;
    if (top) {
      BOOL enteringCompact = _lastLaidOutMode.integerValue != NEAdaptiveLayoutModeCompact;
      // UIKit 在宽度变化的首次布局里可能先把 offset 夹到一个很小的值（合成环境实测会掉到 ~35），
      NSArray<NSArray *> *snapshot = enteringCompact ? [self captureTableOffsetsIn:top.view] : nil;
      [top.view setNeedsLayout];
      [top.view layoutIfNeeded];
      if (enteringCompact) {
        [self restoreTableOffsets:snapshot reload:YES];
        host.view.hidden = YES;
        host.view.hidden = NO;
        [top.view setNeedsDisplay];
        [top.view.layer setNeedsDisplay];
        [CATransaction flush];
      }
      [self fixOverflowingScrollOffsetsIn:top.view];
    }
  }
  _lastLaidOutMode = @(_decision.mode);

  _backButton.hidden = !showsBack;
  BOOL hiddenByPresentation = self.presentedViewController != nil || _adaptiveOverlayPresented;
  _rail.hidden = !showsRailItems || hiddenByPresentation;
  _railScroll.hidden = !showsRailItems || hiddenByPresentation;
  _railActionStack.hidden = !showsRailActions || hiddenByPresentation;
  [self.view bringSubviewToFront:_backButton];
  [self.view bringSubviewToFront:_railActionStack];

  CGFloat masterWidth = railMetrics.hasDivisionMinX
                            ? MIN(MAX(0, railMetrics.divisionMinX), CGRectGetWidth(_contentHost.bounds))
                            : _decision.masterWidth;
  _sectionHosts.firstObject.view.frame = CGRectMake(0, 0, masterWidth, CGRectGetHeight(_contentHost.bounds));
  self.detailHost.view.frame = CGRectMake(masterWidth + configuration.dividerWidth, 0,
                                          MAX(0, CGRectGetWidth(_contentHost.bounds) - masterWidth - configuration.dividerWidth),
                                          CGRectGetHeight(_contentHost.bounds));
  _dividerView.backgroundColor = configuration.dividerColor;
  _dividerView.frame = CGRectMake(masterWidth, 0, configuration.dividerWidth, CGRectGetHeight(_contentHost.bounds));
  _dividerView.hidden = self.selectedSectionIndex != 0 || legacy ||
                        NO == NEAdaptiveDecisionIsPaired(_decision, _hasDecision) || configuration.dividerWidth <= 0;

  for (NSUInteger index = 1; index < _sectionHosts.count; index++) {
    _sectionHosts[index].view.frame = _contentHost.bounds;
    [_sectionHosts[index] configureSplitWithMasterWidth:nil
                                           dividerWidth:configuration.dividerWidth
                                           dividerColor:configuration.dividerColor];
  }

  if (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) || legacy) {
    UIViewController *detailTop = chatNavigation.topViewController;
    if (detailTop != _lastDetailTopController) {
      _lastDetailTopController = detailTop;
      _prefersConversationList = NO;
    }
    _compactShowsDetail = self.selectedSectionIndex == 0
                              ? (_prefersConversationList ? NO : !self.conversationCoordinator.isShowingPlaceholder)
                              : !_sectionHosts[self.selectedSectionIndex].isShowingDetailPlaceholder;
    if (_compactShowsDetail) {
      _sectionHosts.firstObject.view.hidden = YES;
      self.detailHost.view.hidden = NO;
      self.detailHost.view.frame = _contentHost.bounds;
    } else {
      _sectionHosts.firstObject.view.hidden = NO;
      _sectionHosts.firstObject.view.frame = _contentHost.bounds;
      self.detailHost.view.hidden = YES;
    }
  } else {
    // 展开态统一：左列=选中分区根列表，右列=共享 detail。
    _sectionHosts.firstObject.view.hidden = self.selectedSectionIndex != 0;
    _sectionHosts.firstObject.view.frame = CGRectMake(0, 0, masterWidth, CGRectGetHeight(_contentHost.bounds));
    for (NSUInteger index = 1; index < _sectionHosts.count; index++) {
      BOOL isSelected = (NSInteger)index == self.selectedSectionIndex;
      _sectionHosts[index].view.hidden = !isSelected;
      if (isSelected) {
        _sectionHosts[index].view.frame = CGRectMake(0, 0, masterWidth, CGRectGetHeight(_contentHost.bounds));
      }
    }
    self.detailHost.view.hidden = NO;
    self.detailHost.view.frame = CGRectMake(masterWidth + configuration.dividerWidth, 0,
                                            MAX(0, CGRectGetWidth(_contentHost.bounds) - masterWidth - configuration.dividerWidth),
                                            CGRectGetHeight(_contentHost.bounds));
  }

  // 右列是否有内容：每次布局幂等同步给宿主，宿主据此点亮/取消左列选中高亮。
  BOOL paired = NEAdaptiveDecisionIsPaired(_decision, _hasDecision);
  BOOL placeholder;
  if (!paired) {
    placeholder = YES;
  } else if (self.selectedSectionIndex == 0) {
    placeholder = self.conversationCoordinator.isShowingPlaceholder;
  } else if (self.selectedSectionIndex > 0 && self.selectedSectionIndex < (NSInteger)self.sections.count) {
    NEAdaptiveSectionHost *host = _sectionHosts[self.selectedSectionIndex];
    // 默认 Demo 采用共享 detailHost；如果宿主启用了独立 section detail，
    placeholder = host.splitDetail ? host.isShowingDetailPlaceholder : [self isDetailHostShowingPlaceholder];
  } else {
    placeholder = self.conversationCoordinator.isShowingPlaceholder;
  }
  if (self.onDetailPlaceholderChanged) {
    self.onDetailPlaceholderChanged(placeholder);
  }

  [self updateVisibility];
  [self applyContentBackground];
  [self.view layoutIfNeeded];
  _contentTopMasterGap.hidden = legacy;
  _contentTopDetailGap.hidden = legacy;

  UIViewController *chatRoot = chatNavigation.viewControllers.firstObject;
  if (chatRoot && self.onCompactChatVisibilityChanged) {
    BOOL visible = (NEAdaptiveDecisionIsCompact(_decision, _hasDecision) || legacy) && _compactShowsDetail;
    self.onCompactChatVisibilityChanged(chatRoot, visible);
  }

  if (legacy) {
    [self restoreHostedTrailingSafeArea];
  } else {
    [self suppressHostedTrailingSafeArea];
  }

  if (self.onContentLayout) {
    NSMutableArray<UIViewController *> *controllers = [NSMutableArray arrayWithArray:self.sections];
    [controllers addObject:chatNavigation];
    for (NEAdaptiveSectionHost *host in _sectionHosts) {
      if (host.splitDetail) {
        [controllers addObject:host.splitDetail];
      }
    }
    self.onContentLayout(controllers);
  }
  if (self.onGeometryChanged) {
    UIWindow *window = self.view.window;
    self.onGeometryChanged(@{
      @"windowWidth" : @((window ? window.bounds.size.width : self.view.bounds.size.width)),
      @"windowHeight" : @((window ? window.bounds.size.height : self.view.bounds.size.height)),
      @"contentWidth" : @(_contentHost.bounds.size.width),
      @"masterWidth" : @(_decision.masterWidth),
      @"detailWidth" : @(self.detailHost.view.bounds.size.width),
      @"railWidth" : @(legacy ? 0 : railWidth),
      @"mode" : NEAdaptiveModeName(_decision, _hasDecision),
    });
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveGeometryDidChange" object:self];

  if (enteringFallback) {
    _legacyFallbackPending = self.conversationCoordinator.activeIntent != nil;
    if (!_legacyFallbackPending && self.onLegacyFallback) {
      self.onLegacyFallback();
    }
  } else if (_legacyFallbackPending && self.conversationCoordinator.activeIntent == nil) {
    _legacyFallbackPending = NO;
    if (self.onLegacyFallback) {
      self.onLegacyFallback();
    }
  }
}

- (BOOL)syncDecisionToCurrentViewBounds {
  CGRect bounds = self.view.bounds;
  if (bounds.size.width <= 0 || bounds.size.height <= 0) {
    return NO;
  }
  UIEdgeInsets safe = self.view.safeAreaInsets;
  NEAdaptiveWindowGeometry geometry = NEAdaptiveWindowGeometryMake(bounds.size.width, bounds.size.height,
                                                                  safe.top, safe.left, safe.bottom, safe.right);
  NEAdaptiveLayoutDecision current =
      [NEAdaptiveLayoutPolicy resolveWithWindow:geometry configuration:[self.configuration policyConfiguration]];
  if (_hasDecision && NEAdaptiveDecisionsEqual(current, _decision)) {
    return NO;
  }
  NEAdaptiveLayoutDecision old = _decision;
  BOOL hasOld = _hasDecision;
  BOOL wasSinglePage = NEAdaptiveDecisionIsCompact(old, hasOld) || self.isUsingLegacyLayout;
  BOOL enteringFallback = !current.hasMode && !self.isUsingLegacyLayout;
  _decision = current;
  _hasDecision = YES;
  self.isUsingLegacyLayout = !current.hasMode;
  if (!wasSinglePage && (NEAdaptiveDecisionIsCompact(current, YES) || self.isUsingLegacyLayout)) {
    _compactShowsDetail = self.conversationCoordinator.activeIntent != nil;
  }
  return enteringFallback;
}

- (void)syncDetailStackAcrossPosture:(BOOL)paired {
  if (_isTransferringConversationSectionChild ||
      self.selectedSectionIndex >= (NSInteger)self.sections.count) {
    return;
  }
  UINavigationController *master = self.sections[self.selectedSectionIndex];
  UINavigationController *detail = self.conversationCoordinator.navigationController;
  UIViewController *masterRoot = master.viewControllers.firstObject;
  if (!masterRoot) {
    return;
  }
  if (!paired && self.selectedSectionIndex == 0 && self.conversationCoordinator.activeIntent != nil) {
    return;
  }
  NSArray<UIViewController *> *masters = [master.viewControllers subarrayWithRange:NSMakeRange(1, master.viewControllers.count - 1)];
  NSMutableArray<UIViewController *> *detailPages = [NSMutableArray array];
  for (UIViewController *page in detail.viewControllers) {
    if (page != self.conversationCoordinator.currentPlaceholder) {
      [detailPages addObject:page];
    }
  }
  BOOL isMovingPages = paired ? masters.count > 0 : detailPages.count > 0;
  UIViewController *picker = isMovingPages ? [self adaptiveForwardPickerIn:(paired ? master : detail)] : nil;
  UINavigationController *pickerTarget = paired ? detail : master;
  if (picker) {
    [picker dismissViewControllerAnimated:NO completion:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        if (pickerTarget.presentedViewController) return;
        pickerTarget.definesPresentationContext = YES;
        picker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [pickerTarget presentViewController:picker animated:NO completion:nil];
      });
    }];
  }
  _isTransferringConversationSectionChild = YES;
  [UIView performWithoutAnimation:^{
    if (paired) {
      if (masters.count > 0) {
        // 列内选择器（转发/搜索等）挂在左列导航上时，页面迁到右列后选择器
        // 会继续留在左列，形成「选择页 + 原页面」并排的异常布局；换列前先收起。
        [self dismissColumnPresentations];
        [master setViewControllers:@[ masterRoot ] animated:NO];
        // activeIntent 由 layoutContent 里的 syncActiveIntentWithNavigationStack 收敛。
        NSMutableArray<UIViewController *> *pages = [masters mutableCopy];
        UIViewController *placeholder = self.conversationCoordinator.currentPlaceholder;
        if (placeholder) {
          BOOL contains = NO;
          for (UIViewController *page in pages) {
            if (page == placeholder) {
              contains = YES;
              break;
            }
          }
          if (!contains) {
            [pages insertObject:placeholder atIndex:0];
          }
        }
        [detail setViewControllers:pages animated:NO];
      }
    } else if (detailPages.count > 0) {
      [self dismissColumnPresentations];
      [detail setViewControllers:@[ self.conversationCoordinator.currentPlaceholder ?: [[UIViewController alloc] init] ]
                        animated:NO];
      NSMutableArray<UIViewController *> *pages = [NSMutableArray arrayWithObject:masterRoot];
      [pages addObjectsFromArray:detailPages];
      [master setViewControllers:pages animated:NO];
    }
  }];
  _isTransferringConversationSectionChild = NO;
}

- (void)applyContentBackground {
  UIColor *fallback = self.contentBackgroundColorProvider ? self.contentBackgroundColorProvider()
                                                          : self.configuration.contentBackgroundColor;
  if (!fallback) {
    fallback = self.configuration.contentBackgroundColor;
  }
  NEAdaptiveColumnColors *colors = self.contentBackgroundColorsProvider ? self.contentBackgroundColorsProvider() : nil;
  UIColor *master = colors.master ?: fallback;
  UIColor *detail = colors.detail ?: fallback;
  // 通讯录/我的根页占满内容宿主，其右列只是空占位：顶部留白右侧也要用根页颜色。
  // 如果宿主启用了独立 section detail，则详情页自己的背景应保留在右侧。
  if (self.selectedSectionIndex > 0 && self.selectedSectionIndex < (NSInteger)_sectionHosts.count) {
    NEAdaptiveSectionHost *host = _sectionHosts[self.selectedSectionIndex];
    if (!host.splitDetail || !host.hasDetailContent) {
      detail = master;
    }
  }
  _contentTopMasterGap.backgroundColor = master;
  _contentTopDetailGap.backgroundColor = detail;
  self.view.backgroundColor = fallback;
  _contentHost.backgroundColor = fallback;
}

- (NSArray<UINavigationController *> *)hostedNavigations {
  NSMutableArray<UINavigationController *> *navigations = [NSMutableArray arrayWithArray:self.sections];
  [navigations addObject:self.conversationCoordinator.navigationController];
  for (NEAdaptiveSectionHost *host in _sectionHosts) {
    if (host.splitDetail) {
      [navigations addObject:host.splitDetail];
    }
  }
  return navigations;
}

- (void)suppressHostedTrailingSafeArea {
  for (UINavigationController *navigation in self.hostedNavigations) {
    for (UIViewController *page in navigation.viewControllers) {
      if (!page.isViewLoaded) {
        continue;
      }
      CGFloat owned = NEAdaptiveTrailingInsetCancellation(page.view.safeAreaInsets.right,
                                                           page.additionalSafeAreaInsets.right);
      if (fabs(page.additionalSafeAreaInsets.right - owned) > 0.5) {
        UIEdgeInsets insets = page.additionalSafeAreaInsets;
        insets.right = owned;
        page.additionalSafeAreaInsets = insets;
      }
    }
  }
}

- (void)restoreHostedTrailingSafeArea {
  for (UINavigationController *navigation in self.hostedNavigations) {
    for (UIViewController *page in navigation.viewControllers) {
      if (!page.isViewLoaded) {
        continue;
      }
      if (page.additionalSafeAreaInsets.right != 0) {
        UIEdgeInsets insets = page.additionalSafeAreaInsets;
        insets.right = 0;
        page.additionalSafeAreaInsets = insets;
      }
    }
  }
}

- (NSArray<NSArray *> *)captureTableOffsetsIn:(UIView *)root {
  NSMutableArray<NSArray *> *result = [NSMutableArray array];
  [self collectTableOffsets:root into:result];
  return result;
}

- (void)collectTableOffsets:(UIView *)root into:(NSMutableArray<NSArray *> *)result {
  if ([root isKindOfClass:[UITableView class]]) {
    UITableView *table = (UITableView *)root;
    [result addObject:@[ table, [NSValue valueWithCGPoint:table.contentOffset] ]];
    return;
  }
  for (UIView *child in root.subviews) {
    [self collectTableOffsets:child into:result];
  }
}

/// 按快照恢复表格滚动位置；`reload` 为 YES 时先重算行高，再按新内容高度夹取。
- (void)restoreTableOffsets:(NSArray<NSArray *> *)snapshot reload:(BOOL)reload {
  for (NSArray *entry in snapshot) {
    UITableView *table = entry.firstObject;
    CGPoint offset = [entry.lastObject CGPointValue];
    if (reload) {
      [table reloadData];
      [table layoutIfNeeded];
    }
    CGFloat maxY = MAX(0, table.contentSize.height - CGRectGetHeight(table.bounds) + table.contentInset.bottom);
    if (maxY > 0 && offset.y > maxY) {
      offset.y = maxY;
    }
    [table setContentOffset:offset animated:NO];
  }
}

///
- (void)reloadTablesPreservingOffsetIn:(UIView *)root {
  if ([root isKindOfClass:[UITableView class]]) {
    UITableView *table = (UITableView *)root;
    CGPoint offset = table.contentOffset;
    [table reloadData];
    [table layoutIfNeeded];
    CGFloat maxY = MAX(0, table.contentSize.height - CGRectGetHeight(table.bounds) + table.contentInset.bottom);
    if (offset.y > maxY) {
      offset.y = maxY;
    }
    if (!CGPointEqualToPoint(table.contentOffset, offset)) {
      [table setContentOffset:offset animated:NO];
    }
    return;
  }
  for (UIView *child in root.subviews) {
    [self reloadTablesPreservingOffsetIn:child];
  }
}

- (void)fixOverflowingScrollOffsetsIn:(UIView *)root {
  if ([root isKindOfClass:[UITableView class]]) {
    UITableView *table = (UITableView *)root;
    [table layoutIfNeeded];
    CGFloat maxY = MAX(0, table.contentSize.height - CGRectGetHeight(table.bounds) + table.contentInset.bottom);
    if (table.contentOffset.y > maxY + 1) {
      [table setContentOffset:CGPointMake(table.contentOffset.x, maxY) animated:NO];
    }
  } else if ([root isKindOfClass:[UIScrollView class]]) {
    UIScrollView *scroll = (UIScrollView *)root;
    CGFloat maxY = MAX(0, scroll.contentSize.height - CGRectGetHeight(scroll.bounds));
    if (scroll.contentOffset.y > maxY + 1) {
      [scroll setContentOffset:CGPointMake(scroll.contentOffset.x, maxY) animated:NO];
    }
  }
  for (UIView *child in root.subviews) {
    [self fixOverflowingScrollOffsetsIn:child];
  }
}

/// 切换右栏内容前，先关闭该栏上仍处于模态的页面（文本详情等以 overCurrentContext 呈现）。
- (nullable UIViewController *)adaptiveForwardPickerIn:(UINavigationController *)navigation {
  UIViewController *presented = navigation.presentedViewController;
  if (!presented || [presented isKindOfClass:[UIAlertController class]]) return nil;
  if (presented.modalPresentationStyle != UIModalPresentationOverCurrentContext) return nil;
  if (![presented respondsToSelector:@selector(usesAdaptiveContainerPresentation)]) return nil;
  id value = [presented valueForKey:@"usesAdaptiveContainerPresentation"];
  return [value boolValue] ? presented : nil;
}

- (void)dismissColumnPresentations {
  for (UINavigationController *navigation in self.hostedNavigations) {
    [self dismissColumnPresentation:navigation.presentedViewController];
    [self dismissColumnPresentation:navigation.visibleViewController.presentedViewController];
  }
}

- (void)dismissColumnPresentation:(nullable UIViewController *)presented {
  if (!presented || presented.isBeingDismissed || presented.isBeingPresented) {
    return;
  }
  if ([presented isKindOfClass:[UIAlertController class]]) {
    return;
  }
  [presented dismissViewControllerAnimated:NO completion:nil];
}

- (NEAdaptiveReservedRegionMetrics)reservedRegionMetricsWithRailMinX:(CGFloat)railMinX {
  NEAdaptiveReservedRegionMetrics metrics = NEAdaptiveEmptyMetrics();
  if (@available(iOS 27.1, *)) {
    NSArray<UIViewReservedRegion *> *occlusions =
        [self.view reservedRegionsOfKind:[UIViewReservedRegionKind occlusionRegionKind]];
    NSArray<UIViewReservedRegion *> *divisions =
        [self.view reservedRegionsOfKind:[UIViewReservedRegionKind divisionRegionKind]];

    CGRect unionFrame = CGRectNull;
    CGFloat maxOcclusionY = -CGFLOAT_MAX;
    for (UIViewReservedRegion *region in occlusions) {
      if (!region.isActive) {
        continue;
      }
      CGRect frame = region.frame;
      if (CGRectGetMaxX(frame) > railMinX && CGRectGetMinX(frame) < CGRectGetMaxX(self.view.bounds)) {
        unionFrame = CGRectIsNull(unionFrame) ? frame : CGRectUnion(unionFrame, frame);
        maxOcclusionY = MAX(maxOcclusionY, CGRectGetMaxY(frame));
      }
    }
    if (maxOcclusionY > -CGFLOAT_MAX) {
      metrics.hasOcclusionBottom = YES;
      metrics.occlusionBottom = maxOcclusionY;
    }
    if (!CGRectIsNull(unionFrame)) {
      metrics.hasOcclusionCenterX = YES;
      metrics.occlusionCenterX = CGRectGetMidX(unionFrame);
    }
    CGFloat maxDivisionX = -CGFLOAT_MAX;
    CGFloat minDivisionX = CGFLOAT_MAX;
    for (UIViewReservedRegion *region in divisions) {
      if (!region.isActive) {
        continue;
      }
      maxDivisionX = MAX(maxDivisionX, CGRectGetMaxX(region.frame));
      minDivisionX = MIN(minDivisionX, CGRectGetMinX(region.frame));
    }
    if (maxDivisionX > -CGFLOAT_MAX) {
      metrics.hasDivisionMaxX = YES;
      metrics.divisionMaxX = maxDivisionX;
    }
    if (minDivisionX < CGFLOAT_MAX) {
      metrics.hasDivisionMinX = YES;
      metrics.divisionMinX = minDivisionX;
    }
  }
  return metrics;
}

- (void)updateVisibility {
  BOOL messages = self.selectedSectionIndex == 0;
  BOOL paired = NEAdaptiveDecisionIsPaired(_decision, _hasDecision);
  if (_sectionHosts.count > 0) {
    // 隐藏条件：不在消息分区，或单栏下正在展示详情（详情覆盖左列）。
    BOOL hideMessagesHost = !messages || (!paired && _compactShowsDetail);
    _sectionHosts.firstObject.view.hidden = hideMessagesHost;
  }
  if (_sectionHosts.count > 0) {
    [_sectionHosts.firstObject setVisible:_shellVisible && messages && (paired || !_compactShowsDetail)];
  }
  // 共享右列由三个分区共用：appearance 只能按"这段内容是否真的在屏幕上"转发。
  [self.detailHost setContentVisible:_shellVisible && (paired || _compactShowsDetail) animated:NO];
  for (NSUInteger index = 1; index < _sectionHosts.count; index++) {
    NEAdaptiveSectionHost *host = _sectionHosts[index];
    host.view.hidden = self.selectedSectionIndex != (NSInteger)index;
    [host setVisible:_shellVisible && self.selectedSectionIndex == (NSInteger)index];
  }
}

@end
