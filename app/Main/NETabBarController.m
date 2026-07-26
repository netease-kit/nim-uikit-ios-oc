// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabBarController.h"
#import <NEChatKit/NEChatKitOC.h>
#import "NEStyleManager.h"
#import "AppKey.h"
#import "UITabBar+Badge.h"
#import "MeViewController.h"
#import <NEConversationUIKitOC/NEConversationViewController.h>
#import <NEConversationUIKitOC/ConversationViewModel.h>
#import <NEContactUIKitOC/ContactViewController.h>
#import <NEContactUIKitOC/FunContactViewController.h>
#import <NEContactUIKitOC/NETeamJoinAction.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/LocalConversationRepo.h>
#import <NIMSDK/NIMSDK.h>

/// 判断是否开启了 V2 云端会话
static BOOL NEIsCloudConversation(void) {
  return [NIMSDK sharedSDK].v2Option.enableV2CloudConversation;
}

@interface NETabBarController () <NEConversationListener, NELocalConversationListener, NEContactListener, NETeamListener>

@property (nonatomic, strong) UIViewController *chatVC;
@property (nonatomic, strong) UIViewController *contactVC;
@property (nonatomic, strong) MeViewController *meVC;
@property (nonatomic, assign) NSInteger sessionUnreadCount;
@property (nonatomic, assign) NSInteger contactUnreadCount;

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
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
  [[TeamRepo shared] removeTeamListener:self];
  if (NEIsCloudConversation()) {
    [[ConversationRepo shared] removeConversationListener:self];
  } else {
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
  NENavigationController *chatNav = [[NENavigationController alloc] initWithRootViewController:self.chatVC];

  self.contactVC = isNormalStyle ? [[ContactViewController alloc] init] : [[FunContactViewController alloc] init];
  self.contactVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NELocalizable(@"contact")
                                                            image:[UIImage imageNamed:contactImageName]
                                                    selectedImage:[[UIImage imageNamed:contactSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  self.contactVC.tabBarItem.accessibilityIdentifier = @"id.contact";
  NENavigationController *contactNav = [[NENavigationController alloc] initWithRootViewController:self.contactVC];

  self.meVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NELocalizable(@"mine")
                                                       image:[UIImage imageNamed:meImageName]
                                               selectedImage:[[UIImage imageNamed:meSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
  self.meVC.tabBarItem.accessibilityIdentifier = @"id.mine";
  NENavigationController *meNav = [[NENavigationController alloc] initWithRootViewController:self.meVC];

  self.tabBar.backgroundColor = tabBarBackgroundColor;
  self.viewControllers = @[chatNav, contactNav, meNav];
  self.selectedIndex = 0;

  if (@available(iOS 13.0, *)) {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    appearance.backgroundColor = tabBarBackgroundColor;
    appearance.stackedLayoutAppearance.normal.iconColor = normalIconColor;
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
      NSForegroundColorAttributeName: normalTitleColor
    };
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
      NSForegroundColorAttributeName: selectedTitleColor
    };
    self.tabBar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
      self.tabBar.scrollEdgeAppearance = appearance;
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
    self.sessionUnreadCount = [[ConversationRepo shared] getTotalUnreadCount];
  } else {
    self.sessionUnreadCount = [[LocalConversationRepo shared] getTotalUnreadCount];
  }

  if (self.sessionUnreadCount > 0) {
    [self.tabBar showBadgOnWithIndex:0 tabbarItemNums:3];
  } else {
    [self.tabBar hideBadgOn:0];
  }
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
      });
    }];
  }];
}

- (void)clearValidationUnreadCount {
  [self setUpContactBadgeValue];
}

#pragma mark - Notifications

- (void)changeLanguage {
  self.chatVC.tabBarItem.title = NELocalizable(@"message");
  self.contactVC.tabBarItem.title = NELocalizable(@"contact");
  self.meVC.tabBarItem.title = NELocalizable(@"mine");
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
}

- (void)onTotalUnreadCountChanged:(NSInteger)unreadCount {
  [self refreshSessionBadge];
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
}

@end
