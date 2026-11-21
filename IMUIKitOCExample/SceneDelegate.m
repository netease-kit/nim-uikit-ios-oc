#import <NETeamUIKitOC/TeamMemberSelectController.h>
#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "AppKey.h"
#import "Custom/CustomConfig.h"
#import "Mine/Controller/NELoginViewController.h"
#import "Main/NEStyleManager.h"
#import "Main/ServerAddresses.h"
#import "Manager/IMPushConfigManager.h"
#import "Manager/IMPocConfigManager.h"
#import "Mine/Controller/PersonInfoViewController.h"
#import <NEAdaptiveUIKitOC/NEAdaptiveUIKitOC.h>

#import "NETabBarController.h"
#import <UserNotifications/UserNotifications.h>

#import <NEChatKit/ChatKitClient.h>
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatKit/SettingRepo.h>
#import <NEChatKit/NECommonUtil.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>

#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NERtcCallKit/NERtcCallKit.h>
#import <NERtcCallUIKit/NERtcCallUIKit.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

static NSString *const kEnableCloudConversationKey = @"nim_enable_v2_cloud_conversation";
static NSString *const kConversationGroupDefaultEnabledMigrationKey = @"nim_conversation_group_default_enabled_v2";
static NSString *const NIMDemoMeSettingRouterCompat = @"imkit://mine/userInfo.page";
static NSString *const NIMDemoPushP2pChatVCRouterCompat = @"imkit://chat/p2pChat.page";
static NSString *const NIMDemoPushTeamChatVCRouterCompat = @"imkit://chat/teamChat.page";
static NSString *const NIMDemoCallViewRouterCompat = @"imkit://callkit.page";

@interface NEMapFallbackViewController : UIViewController
@property (nonatomic, assign) NEMapType mapType;
- (instancetype)initWithMapType:(NEMapType)mapType;
@end

@implementation NEMapFallbackViewController

- (instancetype)initWithMapType:(NEMapType)mapType {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _mapType = mapType;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.systemBackgroundColor;
  self.title = self.mapType == NEMapTypeSearch
                   ? NELocalizable(@"map_fallback_title_search")
                   : NELocalizable(@"map_fallback_title_detail");

  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;
  label.textColor = UIColor.secondaryLabelColor;
  label.font = [UIFont systemFontOfSize:15];
  label.text = NELocalizable(@"map_fallback_message");
  [self.view addSubview:label];

  [NSLayoutConstraint activateConstraints:@[
    [label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
    [label.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
    [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

@end


@interface SceneDelegate () <AIUserAgentProvider, NEIMKitClientListener, UNUserNotificationCenterDelegate>

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *pendingPushUserInfo;
@property (nonatomic, copy) NSString *currentAppKey;
@property (nonatomic, strong, nullable) NETabBarController *retainedTabBarController;

- (void)loadService;
- (void)restoreTranslationConfig;
- (void)registerMapFallbackRouter;
- (void)loginIMAccount:(NSString *)account
                 token:(NSString *)token
                option:(nullable V2NIMLoginOption *)option
            completion:(void (^)(NSError *_Nullable error))completion;
- (void)initConfig;
/// 只有“展开后被转成竖屏”（窗口 669x951）才把根列表导航栏按钮迁移到侧栏。
- (void)updateSectionRootNavigationMigrationInScene:(UIWindowScene *)scene;

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    (void)session;
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    if (!self.window) {
        self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    }

    NSDictionary<NSString *, id> *userInfo = [connectionOptions.notificationResponse.notification.request.content.userInfo isKindOfClass:[NSDictionary class]]
        ? connectionOptions.notificationResponse.notification.request.content.userInfo
        : nil;
    [self startWithInitialNotificationUserInfo:userInfo];
}

- (NSUserActivity *)stateRestorationActivityForScene:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    (void)scene;
    return nil;
}

- (void)startWithInitialNotificationUserInfo:(NSDictionary<NSString *,id> *)initialNotificationUserInfo {
    if (!self.window) {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }

    self.pendingPushUserInfo = initialNotificationUserInfo;
    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = UIColor.whiteColor;
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLogout)
                                                 name:NENotificationLogout
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUIStyle)
                                                 name:NENotificationChangeUI
                                               object:nil];

    [self registerAPNS];
    [self setupInitWithCompletion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[IMKitClient instance] removeLoginListener:self];
}

- (void)setupIMWithAppKey:(nullable NSString *)appKey {
    NSString *resolvedAppKey = appKey ?: NEAppKey;
    self.currentAppKey = resolvedAppKey;

    NIMSDKOption *option = [NIMSDKOption optionWithAppKey:resolvedAppKey];
    option.v2 = YES;
    option.apnsCername = NEAPNSCername;
    option.pkCername = NEPKCerName;

    V2NIMSDKOption *v2Option = [[V2NIMSDKOption alloc] init];
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    if ([userDefaults objectForKey:kConversationGroupDefaultEnabledMigrationKey] == nil) {
        [userDefaults setBool:NO forKey:kEnableCloudConversationKey];
        [userDefaults setBool:YES forKey:kConversationGroupDefaultEnabledMigrationKey];
    }
    NSNumber *enableCloudConversation = [userDefaults objectForKey:kEnableCloudConversationKey];
    v2Option.enableV2CloudConversation = enableCloudConversation ? enableCloudConversation.boolValue : NO;

    IMKitClient.instance.config.shouldSyncStickTopSessionInfos = YES;
    IMKitClient.instance.config.teamReceiptEnabled = YES;
    IMKitClient.instance.config.shouldSyncUnreadCount = YES;
    IMKitClient.instance.config.fetchAttachmentAutomaticallyAfterReceiving = YES;
    IMKitClient.instance.config.shouldConsiderRevokedMessageUnreadCount = YES;

    [[IMKitClient instance] setupIM2:option v2Option:v2Option];
    [[IMKitClient instance] addLoginListener:self];
}

- (void)configureSharedServices {
    [[NEAIUserManager shared] setProvider:self];
}

- (void)restoreTranslationConfig {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [IMKitConfigCenter shared].autoTranslationEnableTime =
        [userDefaults doubleForKey:@"autoTranslationEnableTime"];

    NSString *savedLanguage = [userDefaults stringForKey:@"translationTargetLanguage"];
    if (savedLanguage.length > 0) {
        [IMKitConfigCenter shared].translationTargetLanguage = savedLanguage;
    }
}

- (void)setupInitWithCompletion:(void (^)(NSError *_Nullable error))completion {
    IMPocConfigModel *configModel = [[IMPocConfigManager instance] getConfig];
    if (configModel.enableCustomConfig.boolValue) {
        [ServerAddresses configCustomServer:configModel];
        if (configModel.customJson.length > 0) {
            [self loginWithAutoParseConfig:configModel completion:completion];
            return;
        }

        NSString *customAppKey = [ServerAddresses customAppkeyFromConfig:configModel];
        if (customAppKey.length > 0) {
            [self setupIMWithAppKey:customAppKey];
            [self configureSharedServices];
            [self loadService];
            [self restoreTranslationConfig];
            [IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth = YES;
            [self loginWithCustomConfig:configModel completion:completion];
            return;
        }
    }

    [ServerAddresses configServer];
    if (NEAppKey.length == 0) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }
    [self setupIMWithAppKey:NEAppKey];
    [self configureSharedServices];
    [self loadService];
    [self restoreTranslationConfig];
    [IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth = YES;
    [self showLoginViewController];
    if (completion) {
        completion(nil);
    }
}

- (void)loginWithAutoParseConfig:(IMPocConfigModel *)configModel completion:(void (^)(NSError *_Nullable error))completion {
    if (configModel.customJson.length <= 0) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }

    NSData *jsonData = [configModel.customJson dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }

    NSError *jsonError = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        [self showLoginViewController];
        if (completion) {
            completion(jsonError);
        }
        return;
    }

    NSString *appKey = [dictionary[@"appkey"] isKindOfClass:[NSString class]] ? dictionary[@"appkey"] : nil;
    [self setupIMWithAppKey:appKey];

    if (configModel.accountId.length <= 0 || configModel.accountIdToken.length <= 0) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }

    [[NEAIUserManager shared] setProvider:self];
    __weak typeof(self) weakSelf = self;
    [self loginIMAccount:configModel.accountId
                   token:configModel.accountIdToken
                  option:nil
              completion:^(NSError * _Nullable error) {
        if (error) {
            if (error.localizedDescription.length > 0) {
                [weakSelf showWindowToast:error.localizedDescription];
            }
            [weakSelf showLoginViewController];
        } else {
            [weakSelf showMainViewController];
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)loginWithCustomConfig:(IMPocConfigModel *)configModel completion:(void (^)(NSError *_Nullable error))completion {
    if (configModel.accountId.length <= 0 || configModel.accountIdToken.length <= 0) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }

    [[NEAIUserManager shared] setProvider:self];
    __weak typeof(self) weakSelf = self;
    [self loginIMAccount:configModel.accountId
                   token:configModel.accountIdToken
                  option:nil
              completion:^(NSError * _Nullable error) {
        if (error) {
            if (error.localizedDescription.length > 0) {
                [weakSelf showWindowToast:error.localizedDescription];
            }
            [weakSelf showLoginViewController];
        } else {
            [weakSelf showMainViewController];
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)loginIMAccount:(NSString *)account
                 token:(NSString *)token
                option:(nullable V2NIMLoginOption *)option
            completion:(void (^)(NSError *_Nullable error))completion {
    [[IMKitClient instance] login:account
                            token:token
                            option:option
                       completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error);
            }
        });
    }];
}

- (void)showLoginViewController {
    [NEKeyboardManager shared].enable = NO;
    NELoginViewController *loginVC = [[NELoginViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    loginVC.loginSuccess = ^{
        [weakSelf showMainViewController];
    };
    self.window.rootViewController = [[NENavigationController alloc] initWithRootViewController:loginVC];
}

- (void)showMainViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NEKeyboardManager shared].enable = YES;
        [NEKeyboardManager shared].shouldResignOnTouchOutside = YES;
        [self initConfig];
        [self initializePageWithChangeUI:NO];
    });
}

- (void)showWindowToast:(NSString *)message {
    if (message.length <= 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window ne_makeToast:message];
    });
}

- (void)handleLogout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoginViewController];
    });
}

- (void)refreshUIStyle {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initializePageWithChangeUI:YES];
    });
}

- (void)initializePageWithChangeUI:(BOOL)isChangeUI {
    [self loadService];
    NETabBarController *tabBar = [[NETabBarController alloc] initWithChangeUI:isChangeUI];
    UIViewController *adaptiveShell = [tabBar makeAdaptiveShellIfEnabled];
    self.retainedTabBarController =
        [adaptiveShell isKindOfClass:[NEAdaptiveShellViewController class]] ? tabBar : nil;
    self.window.rootViewController = adaptiveShell ?: tabBar;
    if (self.window.windowScene) {
      [self updateSectionRootNavigationMigrationInScene:self.window.windowScene];
    }
    if ([adaptiveShell isKindOfClass:[NEAdaptiveShellViewController class]]) {
      // 刚挂到 window 上时还没有 window 引用，延后一轮再采集窗口事实。
      __weak NEAdaptiveShellViewController *weakShell = (NEAdaptiveShellViewController *)adaptiveShell;
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakShell refreshWindow];
      });
    }
    [self consumePendingPushUserInfoIfNeeded];
}

/// 只有“展开后被转成竖屏”（窗口 669x951）才把根列表导航栏按钮迁移到侧栏；
/// 折叠单屏（466x678 / 678x466）保持原导航栏按钮。
- (void)updateSectionRootNavigationMigrationInScene:(UIWindowScene *)scene {
    UIViewController *root = self.window.rootViewController;
    if (![root isKindOfClass:[NEAdaptiveShellViewController class]]) {
        return;
    }
    CGSize size = scene.coordinateSpace.bounds.size;
    // 只认竖屏展开尺寸；折叠单屏（466x678）与横屏（951x669）都保持 NO。
    BOOL unfoldedPortrait = fabs(size.width - 669.0) <= 2.0 && fabs(size.height - 951.0) <= 2.0;
    ((NEAdaptiveShellViewController *)root).migratesSectionRootNavigation = unfoldedPortrait;
}

- (void)registerAPNS {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        (void)error;
        if (!granted) {
            [self showWindowToast:NELocalizable(@"open_push")];
        }
    }];
    [UIApplication.sharedApplication registerForRemoteNotifications];
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
}

- (void)loadService {
    BOOL isFunUI = ![[NEStyleManager instance] isNormalStyle];
    [[ChatKitClient shared] setupInit:isFunUI];
    [[CustomConfig shared] loadSecurityWarningView];
    [[CustomConfig shared] loadAIChatData];
    [[CustomConfig shared] loadPhotoBrowser];

    IMPushConfigManager *pushManager = [IMPushConfigManager instance];
    V2NIMMessagePushConfig *pushConfig = [pushManager getPushConfig];
    if (pushConfig.pushEnabled) {
        [[SettingRepo shared] setMessagePushConfig:pushConfig];
    }

    [ChatKitClient shared].beforeSend = ^MessageSendParams * _Nullable(__unused UIViewController *viewController, MessageSendParams *param) {
        V2NIMSendMessageParams *sendParams = param.params;
        V2NIMMessagePushConfig *messagePushConfig = sendParams.pushConfig ?: [[SettingRepo shared] getMessagePushConfig];
        if (!messagePushConfig) {
            return param;
        }

        NSMutableDictionary *pushDic = [[NECommonUtil getDictionaryFromJSONString:messagePushConfig.pushPayload ?: @""] mutableCopy];
        if (!pushDic) {
            pushDic = [NSMutableDictionary dictionary];
        }

        V2NIMConversationType sessionType = [V2NIMConversationIdUtil conversationType:ChatRepo.conversationId];
        if (sessionType == V2NIM_CONVERSATION_TYPE_P2P) {
            pushDic[@"sessionId"] = [IMKitClient instance].account ?: @"";
            pushDic[@"sessionType"] = @"p2p";
        } else {
            pushDic[@"sessionId"] = ChatRepo.sessionId ?: @"";
            pushDic[@"sessionType"] = @"team";
        }

        messagePushConfig.pushPayload = [NECommonUtil getJSONStringFromDictionary:pushDic];
        sendParams.pushConfig = messagePushConfig;
        return param;
    };

    [[Router shared] register:NIMDemoMeSettingRouterCompat closure:^(NSDictionary *param) {
        id navParam = param[@"nav"];
        if (![navParam isKindOfClass:[UINavigationController class]]) {
            return;
        }
        UINavigationController *nav = (UINavigationController *)navParam;
        [nav pushViewController:[[PersonInfoViewController alloc] init] animated:YES];
    }];
    [[CustomConfig shared] registerCustomChatRouterForFunUI:isFunUI];
    [self registerMapFallbackRouter];
}

- (void)registerMapFallbackRouter {
    [[Router shared] register:NERouterUrl.LocationVCRouter closure:^(NSDictionary<NSString *, id> *param) {
        UINavigationController *nav = param[@"nav"];
        if (![nav isKindOfClass:[UINavigationController class]]) {
            return;
        }
        NSNumber *typeValue = param[@"type"];
        NEMapType type = typeValue ? (NEMapType)typeValue.integerValue : NEMapTypeDetail;
        [nav pushViewController:[[NEMapFallbackViewController alloc] initWithMapType:type] animated:YES];
    }];
}

- (void)initConfig {
    NESetupConfig *setupConfig = [[NESetupConfig alloc] initWithAppkey:self.currentAppKey ?: NEAppKey];
    [[NECallEngine sharedInstance] setup:setupConfig];
    [[NECallEngine sharedInstance] setTimeout:30];

    NECallUIKitConfig *uiConfig = [[NECallUIKitConfig alloc] init];
    [[NERtcCallUIKit sharedInstance] setupWithConfig:uiConfig];
    [self registerCallRouter];

    id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
    if ([delegate isKindOfClass:AppDelegate.class]) {
        [(AppDelegate *)delegate setupVoIPPushRegistryIfNeeded];
    }
}

- (void)registerCallRouter {
    __weak typeof(self) weakSelf = self;
    [[Router shared] register:NIMDemoCallViewRouterCompat closure:^(NSDictionary<NSString *, id> *param) {
        if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
            UIView *toastHost = weakSelf.window;
            [toastHost ne_makeToast:commonLocalizable(@"network_error")
                            duration:2
                            position:NEToastPositionCenter];
            return;
        }

        NEUICallParam *callParam = [[NEUICallParam alloc] init];
        id remoteUserAccid = param[@"remoteUserAccid"];
        id remoteShowName = param[@"remoteShowName"];
        id remoteAvatar = param[@"remoteAvatar"];
        id type = param[@"type"];

        callParam.remoteUserAccid = [remoteUserAccid isKindOfClass:NSString.class] ? remoteUserAccid : @"";
        callParam.remoteShowName = [remoteShowName isKindOfClass:NSString.class] ? remoteShowName : @"";
        callParam.remoteAvatar = [remoteAvatar isKindOfClass:NSString.class] ? remoteAvatar : @"";
        callParam.callType = ([type isKindOfClass:NSNumber.class] && [type integerValue] == 1)
            ? NECallTypeAudio
            : NECallTypeVideo;

        [[NERtcCallUIKit sharedInstance] callWithParam:callParam];
    }];
}

- (void)consumePendingPushUserInfoIfNeeded {
    if (self.pendingPushUserInfo.count <= 0) {
        return;
    }

    NSDictionary<NSString *, id> *pendingUserInfo = [self.pendingPushUserInfo copy];
    self.pendingPushUserInfo = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self pushToChat:pendingUserInfo];
    });
}

- (void)pushToChat:(NSDictionary<NSString *, id> *)userInfo {
    NSString *sessionId = [userInfo[@"sessionId"] isKindOfClass:[NSString class]] ? userInfo[@"sessionId"] : @"";
    NSString *sessionType = [userInfo[@"sessionType"] isKindOfClass:[NSString class]] ? userInfo[@"sessionType"] : @"";
    if (sessionId.length <= 0 || sessionType.length <= 0) {
        return;
    }

    UIViewController *root = self.window.rootViewController;
    NEAdaptiveShellViewController *adaptiveShell =
        [root isKindOfClass:[NEAdaptiveShellViewController class]] ? (NEAdaptiveShellViewController *)root : nil;
    if (!adaptiveShell && ![root isKindOfClass:[NETabBarController class]]) {
        self.pendingPushUserInfo = userInfo;
        return;
    }

    UINavigationController *nav = nil;
    BOOL adaptivePresentation = adaptiveShell != nil;
    if (adaptivePresentation) {
        [adaptiveShell selectSection:0];
        nav = adaptiveShell.sections.firstObject;
    } else {
        NETabBarController *tabBar = (NETabBarController *)root;
        nav = [tabBar.selectedViewController isKindOfClass:[UINavigationController class]]
            ? (UINavigationController *)tabBar.selectedViewController
            : nil;
    }
    if (!nav) {
        return;
    }

    NSString *conversationId = nil;
    NSString *router = nil;
    if ([sessionType isEqualToString:@"p2p"]) {
        conversationId = [V2NIMConversationIdUtil p2pConversationId:sessionId];
        router = NIMDemoPushP2pChatVCRouterCompat;
    } else if ([sessionType isEqualToString:@"team"]) {
        conversationId = [V2NIMConversationIdUtil teamConversationId:sessionId];
        router = NIMDemoPushTeamChatVCRouterCompat;
    }

    if (conversationId.length <= 0 || router.length <= 0) {
        return;
    }

    NSMutableDictionary<NSString *, id> *parameters = [@{
        @"nav": nav,
        @"conversationId": conversationId,
        @"animated": @NO,
    } mutableCopy];
    if (!adaptivePresentation) {
        parameters[@"anchor"] = [NSNull null];
    }
    [[Router shared] use:router parameters:parameters closure:nil];
}

- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    (void)scene;
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
}

/// 启动即展开/折叠时不会触发 didUpdate，激活时按当前姿态补一次迁移开关。
- (void)sceneDidBecomeActive:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    [self updateSectionRootNavigationMigrationInScene:(UIWindowScene *)scene];
}

- (void)windowScene:(UIWindowScene *)windowScene
    didUpdateCoordinateSpace:(id<UICoordinateSpace>)previousCoordinateSpace
    interfaceOrientation:(UIInterfaceOrientation)previousInterfaceOrientation
    traitCollection:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(13.0)) {
    (void)previousCoordinateSpace;
    (void)previousInterfaceOrientation;
    (void)previousTraitCollection;
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:[NEAdaptiveShellViewController class]]) {
        [(NEAdaptiveShellViewController *)root refreshWindow];
    }
    [self updateSectionRootNavigationMigrationInScene:windowScene];
}

- (void)onLoginFailed:(V2NIMError *)error {
    if (error.code == userBannedCode) {
        [self showWindowToast:NELocalizable(@"account_forbidden")];
        [self handleLogout];
    }
}

- (void)onKickedOffline:(V2NIMKickedOfflineDetail *)detail {
    if (detail.reason == V2NIM_KICKED_OFFLINE_REASON_SERVER) {
        [self showWindowToast:NELocalizable(@"account_kicked_offline")];
        [self handleLogout];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    (void)center;
    NSDictionary<NSString *, id> *userInfo = [response.notification.request.content.userInfo isKindOfClass:[NSDictionary class]]
        ? response.notification.request.content.userInfo
        : nil;
    if (userInfo) {
        [self pushToChat:userInfo];
    }
    if (completionHandler) {
        completionHandler();
    }
}

- (nullable V2NIMAIUser *)getAISearchUser:(NSArray<V2NIMAIUser *> *)users {
    for (V2NIMAIUser *user in users) {
        if ([user.accountId isEqualToString:@"search"]) {
            return user;
        }
    }
    return nil;
}

- (nullable V2NIMAIUser *)getAITranslateUser:(NSArray<V2NIMAIUser *> *)users {
    for (V2NIMAIUser *user in users) {
        if ([user.accountId isEqualToString:@"translation"]) {
            return user;
        }
    }
    return nil;
}

- (NSArray<NSString *> *)getAITranslateLangs:(NSArray<V2NIMAIUser *> *)users {
    (void)users;
    return @[ @"英语", @"日语", @"韩语", @"俄语", @"法语", @"德语" ];
}

@end
