// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabBarController.h"
#import <objc/runtime.h>
#import <NEAdaptiveUIKitOC/NEAdaptiveUIKitOC.h>
#import <NEChatUIKitOC/NEBaseChatRouter.h>
#import <NEChatUIKitOC/NEChatUIConstant.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NEPagingViewController.h>
#import <NEBaseUIKitOC/NEAdaptiveContentInsets.h>
#import <NEBaseUIKitOC/NEBaseViewController.h>
#import <NEChatUIKitOC/NEChatBaseViewController.h>
#import <NEContactUIKitOC/NEContactBaseViewController.h>
#import <NEContactUIKitOC/NEBaseContactViewController.h>
#import <NEChatKit/Router.h>

#import "NEStyleManager.h"
#import "CustomChatViewController.h"
#import "AppKey.h"
#import "UITabBar+Badge.h"
#import "MeViewController.h"
#import <NEConversationUIKitOC/NEConversationViewController.h>
#import <NEConversationUIKitOC/ConversationViewModel.h>
#import <NEContactUIKitOC/ContactViewController.h>
#import <NEContactUIKitOC/FunContactViewController.h>
#import <NEContactUIKitOC/NETeamJoinAction.h>
#import <NEContactUIKitOC/NEBaseContactUserViewController.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/LocalConversationRepo.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatUIKitOC/P2PChatViewController.h>
#import <NEChatUIKitOC/ChatViewController.h>
#import <NEChatUIKitOC/TeamChatViewController.h>
#import <NEChatUIKitOC/FunP2PChatViewController.h>
#import <NEChatUIKitOC/FunTeamChatViewController.h>

/// 判断是否开启了 V2 云端会话
static BOOL NEIsCloudConversation(void) {
  return [NIMSDK sharedSDK].v2Option.enableV2CloudConversation;
}

@interface NEAdaptiveDemoNavigationController : NENavigationController

@property (nonatomic, copy, nullable) BOOL (^presentSectionChild)(UIViewController *controller, BOOL animated);
@property (nonatomic, copy, nullable) BOOL (^suppressDetailPushAnimation)(void);
@property (nonatomic, copy, nullable) void (^prepareDetailPage)(UIViewController *controller);

@end

@implementation NEAdaptiveDemoNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (self.viewControllers.count > 0 && self.presentSectionChild &&
      self.presentSectionChild(viewController, animated)) {
    return;
  }
  // 同一页面身份只保留一层：连点「添加好友」等入口时复用已有页面 / 替换栈顶，
  if (self.viewControllers.count > 0) {
    if (!viewController.restorationIdentifier) {
      [viewController loadViewIfNeeded];
    }
    NSString *identity = viewController.restorationIdentifier;
    if (identity.length > 0) {
      for (UIViewController *existing in self.viewControllers) {
        if (existing != viewController && [existing.restorationIdentifier isEqualToString:identity]) {
          [self popToViewController:existing animated:animated];
          return;
        }
      }
      UIViewController *top = self.viewControllers.lastObject;
      if (top.restorationIdentifier.length > 0) {
        NSMutableArray<UIViewController *> *stack = [self.viewControllers mutableCopy];
        stack[stack.count - 1] = viewController;
        [self setViewControllers:stack animated:NO];
        return;
      }
    }
  }
  BOOL suppress = self.suppressDetailPushAnimation ? self.suppressDetailPushAnimation() : NO;
  if (suppress && self.prepareDetailPage) {
    self.prepareDetailPage(viewController);
  }
  [super pushViewController:viewController animated:animated && !suppress];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(void (^)(void))completion {
  [super presentViewController:viewControllerToPresent
                      animated:flag
                    completion:^{
                      if (completion) {
                        completion();
                      }
                      [[NSNotificationCenter defaultCenter]
                          postNotificationName:@"NEAdaptivePresentationDidChange"
                                        object:nil];
                    }];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
  [super dismissViewControllerAnimated:flag
                            completion:^{
                              if (completion) {
                                completion();
                              }
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:@"NEAdaptivePresentationDidChange"
                                                object:nil];
                            }];
}

@end

@interface NETabBarController () <NEConversationListener, NELocalConversationListener, NEContactListener, NETeamListener>

@property (nonatomic, strong) UIViewController *chatVC;
@property (nonatomic, strong) UIViewController *contactVC;
@property (nonatomic, strong) MeViewController *meVC;
@property (nonatomic, assign) NSInteger sessionUnreadCount;
@property (nonatomic, assign) NSInteger contactUnreadCount;
@property (nonatomic, strong) V2NIMConversationFilter *sessionUnreadFilter;
@property (nonatomic, strong) V2NIMLocalConversationFilter *localSessionUnreadFilter;
@property (nonatomic, weak, nullable) NEAdaptiveShellViewController *adaptiveShell;
@property (nonatomic, assign) BOOL ne_leftColumnSelectionOn;
@property (nonatomic, assign) BOOL ne_leftColumnSelectionResolved;
/// 统一延迟到下一轮 runloop 并合并多次请求。
@property (nonatomic, assign) BOOL ne_leftColumnSelectionUpdateScheduled;

@end

@implementation NETabBarController

- (instancetype)initWithChangeUI:(BOOL)isChangeUI {
  self = [super init];
  if (self) {
    _isChangeUIType = isChangeUI;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _meVC = [[MeViewController alloc] init];

  [self setUpControllers];
  [self setUpSessionBadgeValue];
  [self setUpContactBadgeValue];

  [[ContactRepo shared] addContactListener:self];
  [[TeamRepo shared] addTeamListener:self];

  // 监听会话变化以更新未读数红点
  if (NEIsCloudConversation()) {
    [[ConversationRepo shared] addConversationListener:self];
  } else {
    [[LocalConversationRepo shared] addLocalConversationListener:self];
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationChangeLanguage
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(clearValidationUnreadCount)
                                               name:NENotificationClearValidationMessageUnreadCount
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(clearAdaptiveConversation:)
                                               name:NENotificationPopGroupChatVC
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(clearAdaptiveConversation:)
                                               name:NENotificationDeleteConversation
                                             object:nil];
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
  [[TeamRepo shared] removeTeamListener:self];
  if (NEIsCloudConversation()) {
    if (self.sessionUnreadFilter) {
      [[ConversationRepo shared] unsubscribeUnreadCountByFilter:self.sessionUnreadFilter completion:^(NSError *error) {}];
    }
    [[ConversationRepo shared] removeConversationListener:self];
  } else {
    if (self.localSessionUnreadFilter) {
      [[LocalConversationRepo shared] unsubscribeUnreadCountByFilter:self.localSessionUnreadFilter];
    }
    [[LocalConversationRepo shared] removeLocalConversationListener:self];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setUpControllers {
  BOOL isNormalStyle = [NEStyleManager.instance isNormalStyle];
  UIColor *tabBarBackgroundColor = isNormalStyle
    ? [UIColor ne_colorWithHexString:@"#F6F8FA"]
    : [UIColor ne_colorWithHexString:@"#F6F6F6"];
  UIColor *normalIconColor = [UIColor ne_colorWithHexString:@"#C5C9D2"];
  UIColor *normalTitleColor = [UIColor ne_colorWithHexString:@"#999999"];
  UIColor *selectedTitleColor = isNormalStyle ? [UIColor ne_normalTheme] : [UIColor ne_funTheme];
  NSString *chatImageName = isNormalStyle ? @"chat" : @"funChat";
  NSString *chatSelectedImageName = isNormalStyle ? @"chatSelect" : @"funChatSelect";
  NSString *contactImageName = isNormalStyle ? @"contact" : @"funContact";
  NSString *contactSelectedImageName = isNormalStyle ? @"contactSelect" : @"funContactSelect";
  NSString *meImageName = isNormalStyle ? @"person" : @"funPerson";
  NSString *meSelectedImageName = isNormalStyle ? @"personSelect" : @"funPersonSelect";

  if (NEIsCloudConversation()) {
    self.chatVC = [NEConversationViewController cloudController];
  } else {
    self.chatVC = [NEConversationViewController localController];
  }
  ((NEConversationViewController *)self.chatVC).viewModel.syncFinished = self.isChangeUIType;

  self.chatVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NELocalizable(@"message")
                                                         image:[UIImage imageNamed:chatImageName]
                                                 selectedImage:[[UIImage imageNamed:chatSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  self.chatVC.tabBarItem.accessibilityIdentifier = @"id.conversation";
  BOOL useAdaptiveNavigation = [NEAdaptiveDeviceGate isFoldableDevice];
  NENavigationController *chatNav = useAdaptiveNavigation
      ? [[NEAdaptiveDemoNavigationController alloc] initWithRootViewController:self.chatVC]
      : [[NENavigationController alloc] initWithRootViewController:self.chatVC];
  _chatNavigation = chatNav;

  self.contactVC = isNormalStyle ? [[ContactViewController alloc] init] : [[FunContactViewController alloc] init];
  self.contactVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NELocalizable(@"contact")
                                                            image:[UIImage imageNamed:contactImageName]
                                                    selectedImage:[[UIImage imageNamed:contactSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  self.contactVC.tabBarItem.accessibilityIdentifier = @"id.contact";
  NENavigationController *contactNav = useAdaptiveNavigation
      ? [[NEAdaptiveDemoNavigationController alloc] initWithRootViewController:self.contactVC]
      : [[NENavigationController alloc] initWithRootViewController:self.contactVC];
  _contactNavigation = contactNav;

  self.meVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NELocalizable(@"mine")
                                                       image:[UIImage imageNamed:meImageName]
                                               selectedImage:[[UIImage imageNamed:meSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  self.meVC.tabBarItem.accessibilityIdentifier = @"id.mine";
  NENavigationController *meNav = useAdaptiveNavigation
      ? [[NEAdaptiveDemoNavigationController alloc] initWithRootViewController:self.meVC]
      : [[NENavigationController alloc] initWithRootViewController:self.meVC];
  _mineNavigation = meNav;

  self.viewControllers = @[chatNav, contactNav, meNav];
  self.selectedIndex = 0;

  if (@available(iOS 13.0, *)) {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    // 只设 backgroundColor 会让 tab bar 透明、露出窗口黑底（iOS 17 黑条）。
    // iOS 26+ 的玻璃 tab bar 与 Duo 竖排 tab bar 保持原逻辑，不覆盖 system 背景。
    BOOL isFoldableDevice = [NEAdaptiveDeviceGate isFoldableDevice];
    if (!isFoldableDevice) {
      if (@available(iOS 26.0, *)) {
        // 玻璃 tab bar 自带背景，不调用 configureWithOpaqueBackground。
      } else {
        [appearance configureWithOpaqueBackground];
      }
    }
    appearance.backgroundColor = tabBarBackgroundColor;
    appearance.stackedLayoutAppearance.normal.iconColor = normalIconColor;
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
      NSForegroundColorAttributeName: normalTitleColor
    };
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
      NSForegroundColorAttributeName: selectedTitleColor
    };
    self.tabBar.standardAppearance = appearance;
    if (!isFoldableDevice) {
      if (@available(iOS 15.0, *)) {
        // 列表停在顶部时使用 scrollEdgeAppearance，未设置会退回系统默认背景。
        self.tabBar.scrollEdgeAppearance = appearance;
      }
    }
  } else {
    self.tabBar.unselectedItemTintColor = normalIconColor;
    for (UIViewController *vc in self.viewControllers) {
      [vc.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: normalTitleColor} forState:UIControlStateNormal];
      [vc.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: selectedTitleColor} forState:UIControlStateSelected];
    }
  }
}

- (void)setUpSessionBadgeValue {
  if (NEIsCloudConversation()) {
    if (!self.sessionUnreadFilter) {
      self.sessionUnreadFilter = [[V2NIMConversationFilter alloc] init];
      self.sessionUnreadFilter.ignoreMuted = YES;
      [[ConversationRepo shared] subscribeUnreadCountByFilter:self.sessionUnreadFilter completion:^(NSError *error) {}];
    }
    [[ConversationRepo shared] getUnreadCountByFilter:self.sessionUnreadFilter completion:^(NSNumber *count, NSError *error) {
      if (!error) {
        [self updateSessionBadge:count.integerValue];
      }
    }];
  } else {
    if (!self.localSessionUnreadFilter) {
      self.localSessionUnreadFilter = [[V2NIMLocalConversationFilter alloc] init];
      self.localSessionUnreadFilter.ignoreMuted = YES;
      [[LocalConversationRepo shared] addUnreadCountChangeObserver:self.localSessionUnreadFilter completion:^(NSError *error) {}];
    }
    [[LocalConversationRepo shared] getUnreadCountByFilter:self.localSessionUnreadFilter completion:^(NSNumber *count, NSError *error) {
      if (!error) {
        [self updateSessionBadge:count.integerValue];
      }
    }];
  }

}

- (void)updateSessionBadge:(NSInteger)count {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.sessionUnreadCount = count;
    if (count > 0) {
      [self.tabBar showBadgOnWithIndex:0 tabbarItemNums:3];
    } else {
      [self.tabBar hideBadgOn:0];
    }
    [self syncRailBadgeForSection:0 count:count];
  });
}

///
- (void)syncRailBadgeForSection:(NSInteger)index count:(NSInteger)count {
  NEAdaptiveShellViewController *shell = self.adaptiveShell;
  if (!shell) {
    return;
  }
  UINavigationController *section = nil;
  if (index == 0) {
    section = self.chatNavigation;
  } else if (index == 1) {
    section = self.contactNavigation;
  } else {
    section = self.mineNavigation;
  }
  section.tabBarItem.badgeValue = count > 0 ? @"" : nil;
  [shell updateRailItems];
}

- (void)refreshSessionBadge {
  [self setUpSessionBadgeValue];
}

- (void)setUpContactBadgeValue {
  __weak typeof(self) weakSelf = self;
  [[ContactRepo shared] getUnreadApplicationCount:^(NSInteger count, NSError *_Nullable error) {
    if (error) {
      return;
    }

    if (!IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth) {
      weakSelf.contactUnreadCount = count;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.contactUnreadCount > 0) {
          [weakSelf.tabBar showBadgOnWithIndex:1 tabbarItemNums:3];
        } else {
          [weakSelf.tabBar hideBadgOn:1];
        }
      });
      return;
    }

    V2NIMTeamJoinActionInfoQueryOption *option = [[V2NIMTeamJoinActionInfoQueryOption alloc] init];
    option.offset = 0;
    option.limit = neTeamJoinActionPageLimit;
    [[TeamRepo shared] getTeamJoinActionInfoList:option completion:^(V2NIMTeamJoinActionInfoResult *_Nullable result, NSError *_Nullable teamError) {
      if (teamError) {
        return;
      }

      NSInteger unreadCount = count;
      if (result.infos) {
        for (V2NIMTeamJoinActionInfo *action in result.infos) {
          if (action.timestamp > neTeamJoinActionReadTime) {
            unreadCount += 1;
          }
        }
      }
      weakSelf.contactUnreadCount = unreadCount;
      dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.contactUnreadCount > 0) {
          [weakSelf.tabBar showBadgOnWithIndex:1 tabbarItemNums:3];
        } else {
          [weakSelf.tabBar hideBadgOn:1];
        }
        [weakSelf syncRailBadgeForSection:1 count:weakSelf.contactUnreadCount];
      });
    }];
  }];
}

- (void)clearValidationUnreadCount {
  [self setUpContactBadgeValue];
}

#pragma mark - Notifications

- (void)clearAdaptiveConversation:(NSNotification *)notification {
  NEAdaptiveShellViewController *shell = self.adaptiveShell;
  if (!shell) {
    return;
  }
  if ([notification.object isKindOfClass:[NSString class]]) {
    [shell clearConversationIfNeeded:(NSString *)notification.object];
  } else {
    [shell clearActiveConversation];
  }
}

- (void)changeLanguage {
  self.chatVC.tabBarItem.title = NELocalizable(@"message");
  self.contactVC.tabBarItem.title = NELocalizable(@"contact");
  self.meVC.tabBarItem.title = NELocalizable(@"mine");
  [self.adaptiveShell updateRailItems];
  self.adaptiveShell.configuration.backAccessibilityLabel = NELocalizable(@"adaptive_back");
}

#pragma mark - NEContactListener

- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application {
  [self setUpContactBadgeValue];
}

- (void)onFriendAddRejected:(V2NIMFriendAddApplication *)rejectionInfo {
  [self setUpContactBadgeValue];
}

#pragma mark - NETeamListener

- (void)onReceive:(V2NIMTeamJoinActionInfo *)joinActionInfo {
  [self setUpContactBadgeValue];
}

#pragma mark - NEConversationListener

- (void)onConversationChanged:(NSArray<V2NIMConversation *> *)conversations {
  [self refreshSessionBadge];
}

- (void)onConversationCreated:(V2NIMConversation *)conversation {
  [self refreshSessionBadge];
}

- (void)onConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self refreshSessionBadge];
  for (NSString *conversationId in conversationIds) {
    [self.adaptiveShell clearConversationIfNeeded:conversationId];
  }
}

- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount {
  [self refreshSessionBadge];
}

- (void)onUnreadCountChangedByFilter:(V2NIMConversationFilter *)filter unreadCount:(NSInteger)unreadCount {
  if (!filter.ignoreMuted || filter.conversationGroupId.length > 0) {
    return;
  }
  [self updateSessionBadge:unreadCount];
}

#pragma mark - NELocalConversationListener

- (void)onLocalConversationChanged:(NSArray<V2NIMLocalConversation *> *)conversations {
  [self refreshSessionBadge];
}

- (void)onLocalConversationCreated:(V2NIMLocalConversation *)conversation {
  [self refreshSessionBadge];
}

- (void)onLocalConversationDeleted:(NSArray<NSString *> *)conversationIds {
  [self refreshSessionBadge];
  for (NSString *conversationId in conversationIds) {
    [self.adaptiveShell clearConversationIfNeeded:conversationId];
  }
}

- (void)onLocalUnreadCountChangedByFilter:(V2NIMLocalConversationFilter *)filter unreadCount:(NSInteger)unreadCount {
  if (!filter.ignoreMuted) {
    return;
  }
  [self updateSessionBadge:unreadCount];
}


#pragma mark - 自适应外壳

/// 右列空详情占位：皮肤底色 + `NEEmptyDataView` 空态。
///
/// 文案取基础层公共文案 `no_content`，不跨模块引用 `NEConversationUIKitOC` 的私有 strings
/// （跨模块取不到资源时会显示原始 key）。
/// 递归清除视图树里的选中行（UITableView / UICollectionView 都覆盖）。
/// 只清选中态，不改变数据源与滚动位置。
+ (void)clearSelectionRecursivelyInView:(UIView *)view {
  if ([view isKindOfClass:[UITableView class]]) {
    UITableView *tableView = (UITableView *)view;
    for (NSIndexPath *indexPath in tableView.indexPathsForSelectedRows ?: @[]) {
      [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
  } else if ([view isKindOfClass:[UICollectionView class]]) {
    UICollectionView *collectionView = (UICollectionView *)view;
    for (NSIndexPath *indexPath in collectionView.indexPathsForSelectedItems ?: @[]) {
      [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
  }
  for (UIView *subview in view.subviews) {
    [self clearSelectionRecursivelyInView:subview];
  }
}

+ (UIViewController *)adaptiveEmptyDetailControllerForSection:(NSInteger)section {
  BOOL isNormal = [NEStyleManager.instance isNormalStyle];
  UIViewController *controller = [[UIViewController alloc] init];
  controller.view.backgroundColor = UIColor.whiteColor;
  controller.view.accessibilityIdentifier = @"id.adaptive.emptyDetail";

  NSArray<NSString *> *textKeys = @[
    @"adaptive_empty_conversation", @"adaptive_empty_contact", @"adaptive_empty_mine"
  ];
  NSString *textKey = section >= 0 && section < (NSInteger)textKeys.count ? textKeys[section] : textKeys.firstObject;
  NSString *imageName = isNormal ? @"user_empty" : @"fun_user_empty";

  NEEmptyDataView *emptyView = [[NEEmptyDataView alloc] initWithImageName:imageName
                                                                  content:NELocalizable(textKey)
                                                                    frame:CGRectZero];
  emptyView.translatesAutoresizingMaskIntoConstraints = NO;
  emptyView.userInteractionEnabled = NO;
  // NEEmptyDataView 在列表页里固定 176pt 顶距；右列占位需要垂直居中，只调整这一份。
  for (NSLayoutConstraint *constraint in emptyView.constraints) {
    if (constraint.firstItem == emptyView.emptyImageView && constraint.firstAttribute == NSLayoutAttributeTop) {
      constraint.constant = 0;
      break;
    }
  }
  [controller.view addSubview:emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [emptyView.centerXAnchor constraintEqualToAnchor:controller.view.centerXAnchor],
    [emptyView.centerYAnchor constraintEqualToAnchor:controller.view.centerYAnchor],
    [emptyView.heightAnchor constraintEqualToConstant:120],
    [emptyView.widthAnchor constraintLessThanOrEqualToAnchor:controller.view.widthAnchor constant:-32],
  ]];
  return controller;
}

+ (UIViewController *)adaptiveEmptyDetailController {
  return [self adaptiveEmptyDetailControllerForSection:0];
}

+ (void)ne_disablePagingSafeAreaInsetsIn:(UIViewController *)controller {
  if ([controller isKindOfClass:[NEPagingViewController class]]) {
    NEPagingViewController *paging = (NEPagingViewController *)controller;
    if (paging.includeSafeAreaInsets) {
      paging.includeSafeAreaInsets = NO;
      [paging.collectionView.collectionViewLayout invalidateLayout];
    }
  }
  for (UIViewController *child in controller.childViewControllers) {
    [self ne_disablePagingSafeAreaInsetsIn:child];
  }
}

/// 由同一 helper 恢复页面原始值。
+ (void)ne_updateScrollGeometryInView:(UIView *)view managedByContainer:(BOOL)managed {
  if ([view isKindOfClass:[UITableView class]]) {
    [(UIScrollView *)view ne_setContentInsetsManagedByContainer:managed];
  } else if ([view isKindOfClass:[UIScrollView class]]) {
    [(UIScrollView *)view ne_setScrollIndicatorsManagedByContainer:managed];
  }
  for (UIView *child in view.subviews) {
    [self ne_updateScrollGeometryInView:child managedByContainer:managed];
  }
}

static const void *NEAdaptivePagingOriginalSafeAreaKey = &NEAdaptivePagingOriginalSafeAreaKey;

+ (void)ne_updatePagingGeometryInController:(UIViewController *)controller managedByContainer:(BOOL)managed {
  if ([controller isKindOfClass:[NEPagingViewController class]]) {
    NEPagingViewController *paging = (NEPagingViewController *)controller;
    if (managed) {
      if (!objc_getAssociatedObject(paging, NEAdaptivePagingOriginalSafeAreaKey)) {
        objc_setAssociatedObject(paging, NEAdaptivePagingOriginalSafeAreaKey,
                                 @(paging.includeSafeAreaInsets), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
      if (paging.includeSafeAreaInsets) {
        paging.includeSafeAreaInsets = NO;
        [paging.collectionView.collectionViewLayout invalidateLayout];
      }
    } else {
      NSNumber *original = objc_getAssociatedObject(paging, NEAdaptivePagingOriginalSafeAreaKey);
      if (original) {
        paging.includeSafeAreaInsets = original.boolValue;
        [paging.collectionView.collectionViewLayout invalidateLayout];
        objc_setAssociatedObject(paging, NEAdaptivePagingOriginalSafeAreaKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
    }
  }
  for (UIViewController *child in controller.childViewControllers) {
    [self ne_updatePagingGeometryInController:child managedByContainer:managed];
  }
}

+ (void)ne_setTopConstantIfSupported:(UIViewController *)page {
  if ([page respondsToSelector:@selector(setTopConstant:)]) {
    [page setValue:@(NEUIKitNavigationAndStatusHeightForView(page.view)) forKey:@"topConstant"];
  }
}

+ (void)ne_setAdaptiveNavigationButtonWidths:(UIViewController *)page paired:(BOOL)paired {
  if (!paired) {
    return;
  }
  id navigationView = nil;
  @try {
    navigationView = [page valueForKey:@"navigationView"];
  } @catch (__unused NSException *exception) {
    navigationView = nil;
  }
  if ([navigationView respondsToSelector:@selector(setBackButtonWidth:)]) {
    [navigationView setBackButtonWidth:44.0];
  }
  if ([navigationView respondsToSelector:@selector(setMoreButtonWidth:)]) {
    UIButton *moreButton = [navigationView respondsToSelector:@selector(moreButton)]
                               ? [navigationView valueForKey:@"moreButton"] : nil;
    BOOL hasText = [moreButton isKindOfClass:[UIButton class]] &&
                   [[(UIButton *)moreButton currentTitle] length] > 0;
    [navigationView setMoreButtonWidth:hasText ? 100.0 : 44.0];
  }
}

+ (void)ne_setAdaptiveSelectionButtonWidth:(UIViewController *)page {
  if (![page respondsToSelector:@selector(selectedSureButton)] &&
      ![page respondsToSelector:@selector(sureButton)]) {
    return;
  }
  UIButton *button = nil;
  @try {
    id candidate = [page respondsToSelector:@selector(selectedSureButton)]
                      ? [page valueForKey:@"selectedSureButton"]
                      : [page valueForKey:@"sureButton"];
    if ([candidate isKindOfClass:[UIButton class]]) {
      button = candidate;
    }
  } @catch (__unused NSException *exception) {
    button = nil;
  }
  if (!button) {
    return;
  }
  CGRect frame = button.frame;
  frame.size.width = 100.0;
  button.frame = frame;
}

+ (void)ne_prepareAdaptivePage:(UIViewController *)page paired:(BOOL)paired managedByContainer:(BOOL)managed {
  if (!page.isViewLoaded) {
    return;
  }
  [self ne_updateScrollGeometryInView:page.view managedByContainer:managed];
  [self ne_updatePagingGeometryInController:page managedByContainer:managed];
  [self ne_setTopConstantIfSupported:page];
  if (paired) {
    [self ne_setAdaptiveSelectionButtonWidth:page];
  }
  [self ne_setAdaptiveNavigationButtonWidths:page paired:paired];
  [page.view setNeedsLayout];
  [page.view layoutIfNeeded];
}

/// 只构造页面并下发 anchor/恢复参数，不查改 SDK 状态、不注册监听。
+ (nullable UIViewController *)adaptiveConversationForIntent:(NEConversationOpenIntent *)intent {
  NSDictionary<NSString *, id> *parameters = intent.parameters;
  NSString *conversationId = [parameters[@"conversationId"] isKindOfClass:[NSString class]] ? parameters[@"conversationId"] : nil;
  if (conversationId.length == 0) {
    return nil;
  }
  BOOL normal = [NEStyleManager.instance isNormalStyle];
  V2NIMMessage *anchor = [parameters[@"anchor"] isKindOfClass:[V2NIMMessage class]] ? parameters[@"anchor"] : nil;
  UIViewController *controller = nil;

  if ([intent.route isEqualToString:@"imkit://chat/p2pChat.page"]) {
    // 与 Demo 的自定义路由保持一致：P2P 会话用 CustomNormal/Fun 聊天页（带安全提示等定制），
    controller = normal ? [[CustomNormalChatViewController alloc] initWithConversationId:conversationId anchor:anchor]
                        : [[CustomFunChatViewController alloc] initWithConversationId:conversationId anchor:anchor];
  } else if ([intent.route isEqualToString:@"imkit://chat/teamChat.page"]) {
    controller = normal ? [[TeamChatViewController alloc] initWithConversationId:conversationId anchor:anchor]
                        : [[FunTeamChatViewController alloc] initWithConversationId:conversationId anchor:anchor];
  } else {
    return nil;
  }
  [ChatRouter applyPresentationParameters:parameters toViewController:controller reload:NO];
  return controller;
}

/// 左列高亮只在「右列正在展示该行的详情」时点亮：
/// - 其它分区沿用「右列有内容」。
/// 合并调度：布局/占位回调可能在列表 reload 过程中触发，直接设置选中底色会重入 UIKit。
- (void)ne_scheduleLeftColumnSelectionUpdateInShell:(NEAdaptiveShellViewController *)shell {
  if (self.ne_leftColumnSelectionUpdateScheduled) {
    return;
  }
  self.ne_leftColumnSelectionUpdateScheduled = YES;
  __weak typeof(self) weakSelf = self;
  __weak NEAdaptiveShellViewController *weakShell = shell;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    self.ne_leftColumnSelectionUpdateScheduled = NO;
    [self ne_updateLeftColumnSelectionInShell:weakShell];
  });
}

- (void)ne_updateLeftColumnSelectionInShell:(NEAdaptiveShellViewController *)shell {
  if (!shell) {
    return;
  }
  // 搜索/添加好友/我的群聊等工具页也算「右列有内容」，保留上一次选中的行；
  BOOL showsSelection = !shell.conversationCoordinator.isShowingPlaceholder;
  if (self.ne_leftColumnSelectionResolved && self.ne_leftColumnSelectionOn == showsSelection) {
    return;
  }
  self.ne_leftColumnSelectionResolved = YES;
  self.ne_leftColumnSelectionOn = showsSelection;
  [self setLeftColumnSelectionEnabled:showsSelection inShell:shell];
}

/// 让当前分组保留该行（未读/@我 分组已读或清除 @ 后不会「打开即消失」）；
- (void)ne_updateConversationGroupRetentionInShell:(NEAdaptiveShellViewController *)shell {
  if (!shell || ![self.chatVC isKindOfClass:[NEBaseConversationController class]]) {
    return;
  }
  NEConversationNavigationCoordinator *coordinator = shell.conversationCoordinator;
  NSString *activeId = nil;
  if (!coordinator.isShowingPlaceholder) {
    id value = coordinator.activeIntent.parameters[@"conversationId"];
    if ([value isKindOfClass:[NSString class]]) {
      activeId = value;
    }
  }
  NSString *retained = (shell.isShowingPairedContent && activeId.length > 0) ? activeId : nil;
  [(NEBaseConversationController *)self.chatVC ne_retainConversationInGroup:retained];
}

- (void)setLeftColumnSelectionEnabled:(BOOL)enabled inShell:(NEAdaptiveShellViewController *)shell {  UIColor *color = enabled ? [shell.configuration.selectedTintColor colorWithAlphaComponent:0.1] : nil;
  for (UINavigationController *nav in shell.sections) {
    for (UIViewController *page in nav.viewControllers) {
      if (!page.isViewLoaded) {
        continue;
      }
      if ([page isKindOfClass:[NEBaseContactViewController class]]) {
        ((NEBaseContactViewController *)page).listSelectionBackgroundColor = color;
      } else if ([page isKindOfClass:[NEBaseConversationController class]]) {
        ((NEBaseConversationController *)page).listSelectionBackgroundColor = color;
      } else if ([page isKindOfClass:[MeViewController class]]) {
        ((MeViewController *)page).listSelectionBackgroundColor = color;
      }
    }
  }
}

- (UIViewController *)makeAdaptiveShellIfEnabled {
  // 回滚开关优先；关闭后与接入前完全一致。
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"disableAdaptiveUIKit"]) {
    return nil;
  }
  [NEAdaptiveDeviceGate setAdaptiveHostActive:[NEAdaptiveDeviceGate isFoldableDevice]];
  if (![NEAdaptiveDeviceGate adaptiveHostActive]) {
    return nil;
  }
  if (!self.chatNavigation || !self.contactNavigation || !self.mineNavigation) {
    [self loadViewIfNeeded];
  }
  if (!self.chatNavigation || !self.contactNavigation || !self.mineNavigation) {
    return nil;
  }
  if ([self.chatVC isKindOfClass:[NEConversationViewController class]]) {
    ((NEConversationViewController *)self.chatVC).adaptiveStickTopHeight =
        [NEStyleManager instance].isNormalStyle ? 88.0 : 96.0;
  }
  if ([self.contactVC isKindOfClass:[NEBaseViewController class]]) {
    ((NEBaseViewController *)self.contactVC).navigationView.titleBarBottomLine.hidden = YES;
  }
  if ([self.chatVC isKindOfClass:[NEBaseViewController class]]) {
    ((NEBaseViewController *)self.chatVC).navigationView.titleBarBottomLine.hidden = YES;
  }

  NEAdaptiveShellConfiguration *configuration =
      [[NEAdaptiveShellConfiguration alloc] initWithRailWidth:72
                                     singleContentMinimumWidth:240
                                          masterMinimumWidth:240
                                          detailMinimumWidth:320
                                                dividerWidth:1
                                            mediumMasterWidth:280
                                          expandedMasterWidth:320
                                          masterMaximumWidth:360];
  configuration.railUsesTrailingEdge = YES;
  BOOL normalStyle = [NEStyleManager instance].isNormalStyle;
  UIColor *themeColor = normalStyle ? UIColor.ne_normalTheme : UIColor.ne_funTheme;
  configuration.selectedTintColor = themeColor;
  configuration.backAccessibilityLabel = NELocalizable(@"adaptive_back");
  if (configuration.backAccessibilityLabel.length == 0 ||
      [configuration.backAccessibilityLabel isEqualToString:@"adaptive_back"]) {
    configuration.backAccessibilityLabel = @"返回";
  }
  configuration.railBackgroundColor = UIColor.whiteColor;
  configuration.dividerColor = normalStyle
      ? UIColor.ne_defaultNavigationDividerColor
      : [UIColor ne_colorWithHexString:@"#E4E9F2"];
  configuration.normalTintColor = [UIColor ne_colorWithHexString:@"#C5C9D2"];
  // 两端 Fun/Normal 的返回与动作文字都是 #333333，直接用同值公共色。
  configuration.backTintColor = [UIColor ne_colorWithHexString:@"#333333"];
  configuration.railControlBackgroundColor = UIColor.whiteColor;
  configuration.railControlBorderColor = normalStyle
      ? [UIColor ne_colorWithHexString:@"#E8EAED"]
      : [UIColor ne_colorWithHexString:@"#E4E9F2"];
  configuration.railActionTextColor = [UIColor ne_colorWithHexString:@"#333333"];
  configuration.railBadgeBackgroundColor = nil;
  configuration.railBadgeTextColor = UIColor.whiteColor;
  configuration.contentBackgroundColor =
      [NEStyleManager instance].isNormalStyle
          ? UIColor.whiteColor
          : [UIColor ne_colorWithHexString:@"#EDEDED"];  // Fun：通讯录导航灰
  configuration.contentTopInset = 12;
  configuration.railBackButtonSize = configuration.railActionButtonSize;
  configuration.railBackTopInset = 168;
  configuration.railItemHeight = 64;
  configuration.railItemSpacing = 18;
  configuration.railItemsTopInset = 268;

  UIViewController *emptyDetail = [self.class adaptiveEmptyDetailController];
  NEAdaptiveDemoNavigationController *detailNavigation =
      [[NEAdaptiveDemoNavigationController alloc] initWithRootViewController:emptyDetail];

  NEAdaptiveShellViewController *shell =
      [[NEAdaptiveShellViewController alloc] initWithSections:@[ self.chatNavigation, self.contactNavigation, self.mineNavigation ]
                                    detailNavigationController:detailNavigation
                                               configuration:configuration];
  self.adaptiveShell = shell;
  shell.view.tintColor = normalStyle ? UIColor.ne_defaultPrimaryColor : UIColor.ne_funTheme;
  shell.sectionEmptyDetailFactory = ^UIViewController *(NSInteger index) {
    return [NETabBarController adaptiveEmptyDetailControllerForSection:index];
  };

  __weak typeof(self) weakSelf = self;
  __weak NEAdaptiveShellViewController *weakShell = shell;
  __block NEChatConversationPresentationHandler adaptivePresentationHandler = nil;
  shell.sectionDetailNavigationFactory = ^UINavigationController *{
    NEAdaptiveDemoNavigationController *navigation = [[NEAdaptiveDemoNavigationController alloc] init];
    navigation.suppressDetailPushAnimation = ^BOOL {
      return weakShell.isUsingAdaptiveLayout;
    };
    navigation.prepareDetailPage = ^(UIViewController *page) {
      [NETabBarController ne_prepareAdaptivePage:page
                                          paired:weakShell.isShowingPairedContent
                             managedByContainer:weakShell.isUsingAdaptiveLayout];
    };
    return navigation;
  };
  shell.onSectionDetailNavigationCreated = ^(UINavigationController *navigation) {
    if (adaptivePresentationHandler) {
      [ChatRouter setConversationPresentationHandler:adaptivePresentationHandler
                              forNavigationController:navigation];
    }
  };
  for (UINavigationController *navigation in @[ self.chatNavigation, self.contactNavigation, self.mineNavigation ]) {
    if (![navigation isKindOfClass:[NEAdaptiveDemoNavigationController class]]) {
      continue;
    }
    NEAdaptiveDemoNavigationController *demoNavigation = (NEAdaptiveDemoNavigationController *)navigation;
    __weak UINavigationController *weakNavigation = navigation;
    demoNavigation.presentSectionChild = ^BOOL(UIViewController *controller, BOOL animated) {
      NEAdaptiveShellViewController *strongShell = weakShell;
      UINavigationController *strongNavigation = weakNavigation;
      if (!strongShell || !strongNavigation) {
        return NO;
      }
      return [strongShell presentSectionChild:controller
                    fromNavigationController:strongNavigation
                                     animated:animated];
    };
    demoNavigation.suppressDetailPushAnimation = ^BOOL {
      NEAdaptiveShellViewController *strongShell = weakShell;
      return strongShell ? strongShell.isUsingAdaptiveLayout : NO;
    };
  }
  detailNavigation.suppressDetailPushAnimation = ^BOOL {
    NEAdaptiveShellViewController *strongShell = weakShell;
    return strongShell ? strongShell.isUsingAdaptiveLayout : NO;
  };
  shell.onSectionSelected = ^(NSInteger index) {
    [weakSelf selectTabIndex:index];
  };
  shell.onConversationOpened = ^(NSString *conversationId) {
    UIViewController *root = weakSelf.chatVC;
    if (![root isKindOfClass:[NEBaseConversationController class]] || conversationId.length == 0) {
      return;
    }
    [weakSelf ne_updateConversationGroupRetentionInShell:weakShell];
    NEBaseConversationController *list = (NEBaseConversationController *)root;
    if (weakShell.isShowingPairedContent) {
      [list ne_selectConversation:conversationId animated:NO];
    } else {
      [list ne_markSelectedConversationId:conversationId];
    }
  };
  shell.onDetailPlaceholderChanged = ^(BOOL placeholder) {
    (void)placeholder;
    // 右列内容变化后按「栈顶是否是该行的详情」重算左列开关（见 ne_updateLeftColumnSelectionInShell:）。
    [weakSelf ne_updateLeftColumnSelectionInShell:weakShell];
    [weakSelf ne_updateConversationGroupRetentionInShell:weakShell];
    if (!weakShell.conversationCoordinator.isShowingPlaceholder) {
      return;
    }
    UIViewController *root = weakSelf.chatVC;
    if (!root.isViewLoaded) {
      return;
    }
    [NETabBarController clearSelectionRecursivelyInView:root.view];
  };

  adaptivePresentationHandler =
      ^BOOL(NSString *route, NSDictionary<NSString *, id> *parameters) {
        NEAdaptiveShellViewController *strongShell = weakShell;
        if (!strongShell) {
          return NO;
        }
        NSString *conversationId = parameters[@"conversationId"];
        if (![conversationId isKindOfClass:[NSString class]] || conversationId.length == 0) {
          return NO;
        }
        NSString *sessionId = [parameters[@"sessionId"] isKindOfClass:[NSString class]] ? parameters[@"sessionId"] : @"";
        V2NIMTopic *topic = [parameters[@"topic"] isKindOfClass:[V2NIMTopic class]] ? parameters[@"topic"] : nil;
        NSString *topicId = topic ? [NSString stringWithFormat:@"%lld", topic.topicId] : @"";
        BOOL hasAction = [parameters[@"anchor"] isKindOfClass:[V2NIMMessage class]] ||
                         parameters[@"onReceiveNewMsgs"] != nil;
        NEConversationOpenIntent *intent = [[NEConversationOpenIntent alloc]
                  initWithKey:[NSString stringWithFormat:@"%@|%@|%@|%@", route, conversationId, sessionId, topicId]
                        route:route
                   parameters:parameters
     requiresPresentationAction:hasAction];
        BOOL handled = [strongShell openConversation:intent];
        BOOL removeSource = [parameters[@"removeUserVC"] boolValue] || [parameters[@"removeTeamVC"] boolValue];
        UINavigationController *source = parameters[@"nav"];
        if (handled && removeSource && [source isKindOfClass:[UINavigationController class]] &&
            source != strongShell.conversationCoordinator.navigationController && source.viewControllers.count > 1) {
          [source popViewControllerAnimated:NO];
        }
        return handled;
      };
  for (UINavigationController *nav in @[ self.chatNavigation, self.contactNavigation, self.mineNavigation, detailNavigation ]) {
    if (!nav) {
      continue;
    }
    [ChatRouter setConversationPresentationHandler:adaptivePresentationHandler forNavigationController:nav];
  }
  [ChatRouter setConversationFallbackHandler:adaptivePresentationHandler];

  // 表现为「同一会话反复 loadData」「快速切换迟钝」「从通讯录进聊天不切分区」。
  shell.conversationCoordinator.controllerFactory = ^UIViewController *(NEConversationOpenIntent *intent) {
    return [NETabBarController adaptiveConversationForIntent:intent];
  };
  shell.conversationCoordinator.presentationAction = ^BOOL(NEConversationOpenIntent *intent, UIViewController *root) {
    return [ChatRouter applyPresentationParameters:intent.parameters toViewController:root reload:YES];
  };
  // 分页控制器再叠加 safeAreaInsets 会让页签内容宽出列宽，首次切页时整排页签横向跳动。
  shell.onContentLayout = ^(NSArray<UIViewController *> *controllers) {
    for (UIViewController *controller in controllers) {
      NSArray<UIViewController *> *pages = [controller isKindOfClass:[UINavigationController class]]
                                               ? ((UINavigationController *)controller).viewControllers
                                               : @[ controller ];
      for (UIViewController *page in pages) {
        [NETabBarController ne_prepareAdaptivePage:page
                                            paired:weakShell.isShowingPairedContent
                               managedByContainer:weakShell.isUsingAdaptiveLayout];
      }
    }
    // 右列栈变化（push/pop 工具页、返回聊天页）时同步左列高亮开关。
    [weakSelf ne_scheduleLeftColumnSelectionUpdateInShell:weakShell];
  };

  return shell;
}

- (void)selectTabIndex:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)self.viewControllers.count) {
    return;
  }
  self.selectedIndex = index;
}

@end
