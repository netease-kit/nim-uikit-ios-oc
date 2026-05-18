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
#import "Main/NETabBarController.h"
#import <UserNotifications/UserNotifications.h>
#import <NEChatKitOC/ChatKitClient.h>
#import <NEChatKitOC/ChatRepo.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NEAIUserManager.h>
#import <NEChatKitOC/SettingRepo.h>
#import <NEChatKitOC/NECommonUtil.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NERouterUrl.h>
#import <NEChatKitOC/Router.h>
#import <NERtcCallKit/NERtcCallKit.h>
#import <NERtcCallUIKit/NERtcCallUIKit.h>
#import <NIMSDK/NIMSDK.h>

static NSString *const kEnableCloudConversationKey = @"nim_enable_v2_cloud_conversation";

@interface SceneDelegate () <AIUserAgentProvider, NEIMKitClientListener, UNUserNotificationCenterDelegate>

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *pendingPushUserInfo;
@property (nonatomic, copy) NSString *currentAppKey;

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
    NSNumber *enableCloudConversation = [NSUserDefaults.standardUserDefaults objectForKey:kEnableCloudConversationKey];
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
    [NEKeyboardManager shared].enable = YES;
    [NEKeyboardManager shared].shouldResignOnTouchOutside = YES;
    [self loadAppServices];
    [self loadSwiftDemoParityConfig];
    [IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth = YES;
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
            [self loginWithCustomConfig:configModel completion:completion];
            return;
        }
    }

    [ServerAddresses configServer];
    [self setupIMWithAppKey:NEAppKey];
    [self configureSharedServices];
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
    [self configureSharedServices];

    if (configModel.accountId.length <= 0 || configModel.accountIdToken.length <= 0) {
        [self showLoginViewController];
        if (completion) {
            completion(nil);
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self loginIMAccount:configModel.accountId token:configModel.accountIdToken completion:^(NSError * _Nullable error) {
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

    __weak typeof(self) weakSelf = self;
    [self loginIMAccount:configModel.accountId token:configModel.accountIdToken completion:^(NSError * _Nullable error) {
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

- (void)loginIMAccount:(NSString *)account token:(NSString *)token completion:(void (^)(NSError *_Nullable error))completion {
    V2NIMLoginOption *option = [[V2NIMLoginOption alloc] init];
    option.syncLevel = V2NIM_DATA_SYNC_TYPE_LEVEL_BASIC;
    [[NIMSDK sharedSDK].v2LoginService login:account
                                       token:token
                                     option:option
                                     success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
    } failure:^(V2NIMError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error.nserror);
            }
        });
    }];
}

- (void)showLoginViewController {
    NELoginViewController *loginVC = [[NELoginViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    loginVC.loginSuccess = ^{
        [weakSelf showMainViewController];
    };
    self.window.rootViewController = [[NENavigationController alloc] initWithRootViewController:loginVC];
}

- (void)showMainViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window.rootViewController = [[NETabBarController alloc] initWithChangeUI:NO];
        [self consumePendingPushUserInfoIfNeeded];
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
        self.window.rootViewController = [[NETabBarController alloc] initWithChangeUI:YES];
        [self consumePendingPushUserInfoIfNeeded];
    });
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

- (void)loadAppServices {
    IMPushConfigManager *pushManager = [IMPushConfigManager instance];
    V2NIMMessagePushConfig *pushConfig = [pushManager getPushConfig];
    if (pushConfig.pushEnabled) {
        [[SettingRepo shared] setMessagePushConfig:pushConfig];
    }

    __weak typeof(self) weakSelf = self;
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

        if (!sendParams) {
            sendParams = [[V2NIMSendMessageParams alloc] init];
            param.params = sendParams;
        }
        messagePushConfig.pushPayload = [NECommonUtil getJSONStringFromDictionary:pushDic];
        sendParams.pushConfig = messagePushConfig;
        [weakSelf consumePendingPushUserInfoIfNeeded];
        return param;
    };

    [[Router shared] register:MeSettingRouter closure:^(NSDictionary *param) {
        id navParam = param[@"nav"];
        if (![navParam isKindOfClass:[UINavigationController class]]) {
            return;
        }
        UINavigationController *nav = (UINavigationController *)navParam;
        [nav pushViewController:[[PersonInfoViewController alloc] init] animated:YES];
    }];
}

- (void)loadSwiftDemoParityConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isFunUI = ![[NEStyleManager instance] isNormalStyle];
        [self loadCallKitIfAvailable];
        [[CustomConfig shared] loadAIChatData];
        [[CustomConfig shared] loadSecurityWarningView];
        [[CustomConfig shared] loadRtcEntry];
        [[CustomConfig shared] loadPhotoBrowser];
        [[CustomConfig shared] registerCustomChatRouterForFunUI:isFunUI];
    });
}

- (void)loadCallKitIfAvailable {
    NESetupConfig *setupConfig = [[NESetupConfig alloc] initWithAppkey:self.currentAppKey ?: NEAppKey];
    [[NECallEngine sharedInstance] setup:setupConfig];
    [[NECallEngine sharedInstance] setTimeout:30];

    NECallUIKitConfig *uiConfig = [[NECallUIKitConfig alloc] init];
    [[NERtcCallUIKit sharedInstance] setupWithConfig:uiConfig];

    id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
    if ([delegate isKindOfClass:AppDelegate.class]) {
        [(AppDelegate *)delegate setupVoIPPushRegistryIfNeeded];
    }
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

    if (![self.window.rootViewController isKindOfClass:[NETabBarController class]]) {
        self.pendingPushUserInfo = userInfo;
        return;
    }

    NETabBarController *tabBar = (NETabBarController *)self.window.rootViewController;
    UINavigationController *nav = [tabBar.selectedViewController isKindOfClass:[UINavigationController class]]
        ? (UINavigationController *)tabBar.selectedViewController
        : nil;
    if (!nav) {
        return;
    }

    NSString *conversationId = nil;
    NSString *router = nil;
    if ([sessionType isEqualToString:@"p2p"]) {
        conversationId = [V2NIMConversationIdUtil p2pConversationId:sessionId];
        router = PushP2pChatVCRouter;
    } else if ([sessionType isEqualToString:@"team"]) {
        conversationId = [V2NIMConversationIdUtil teamConversationId:sessionId];
        router = PushTeamChatVCRouter;
    }

    if (conversationId.length <= 0 || router.length <= 0) {
        return;
    }

    [[Router shared] use:router
              parameters:@{
                  @"nav": nav,
                  @"conversationId": conversationId,
                  @"animated": @NO,
                  @"anchor": [NSNull null],
              }
                 closure:nil];
}

- (void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    (void)scene;
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
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
