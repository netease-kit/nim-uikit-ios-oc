#import "AppDelegate.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/ChatKitClient.h>
#import "SceneDelegate.h"
#import <NERtcCallKit/NERtcCallKit.h>
#import <NIMSDK/NIMSDK.h>
#import <PushKit/PushKit.h>

@interface AppDelegate () <PKPushRegistryDelegate>
@property (nonatomic, strong, nullable) SceneDelegate *legacySceneDelegate;
@property (nonatomic, strong, nullable) PKPushRegistry *pushRegistry;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    if (@available(iOS 13.0, *)) {
        return YES;
    }

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.legacySceneDelegate = [[SceneDelegate alloc] init];
    self.legacySceneDelegate.window = self.window;

    NSDictionary<NSString *, id> *userInfo = [launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] isKindOfClass:[NSDictionary class]]
        ? launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]
        : nil;
    [self.legacySceneDelegate startWithInitialNotificationUserInfo:userInfo];
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0)) {
    (void)application;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                                                          sessionRole:connectingSceneSession.role];
    configuration.delegateClass = SceneDelegate.class;
    return configuration;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    (void)application;
    [[IMKitClient instance] updateApnsToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    (void)application;
    NSLog(@"register remote notifications failed: %@", error.localizedDescription ?: @"");
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    (void)application;
    (void)window;
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setupVoIPPushRegistryIfNeeded {
    if (self.pushRegistry) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.pushRegistry) {
            return;
        }

        PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        pushRegistry.delegate = self;
        pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
        self.pushRegistry = pushRegistry;
    });
}

- (void)pushRegistry:(PKPushRegistry *)registry
didUpdatePushCredentials:(PKPushCredentials *)pushCredentials
             forType:(PKPushType)type {
    (void)registry;
    (void)type;
    if (pushCredentials.token.length <= 0) {
        NSLog(@"voip token isEmpty");
        return;
    }
    [[NIMSDK sharedSDK] updatePushKitToken:pushCredentials.token];
}

- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(PKPushType)type
      withCompletion:(void (^)(void))completion {
    (void)registry;
    (void)type;
    if (![payload.dictionaryPayload[@"nim"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"not found nim payload");
        if (completion) {
            completion();
        }
        return;
    }

    NECallSystemIncomingCallParam *param = [[NECallSystemIncomingCallParam alloc] init];
    param.payload = payload.dictionaryPayload;

    if (@available(iOS 17.4, *)) {
        [[NECallEngine sharedInstance] reportIncomingCallWithParam:param
                                                  acceptCompletion:^(NSError * _Nullable error, NECallInfo * _Nullable callInfo) {
            (void)callInfo;
            if (error) {
                NSLog(@"lck accept failed %@", error.localizedDescription ?: @"");
            }
        } hangupCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"lck hangup error %@", error.localizedDescription ?: @"");
            }
        } muteCompletion:^(NSError * _Nullable error, BOOL mute) {
            (void)mute;
            if (error) {
                NSLog(@"lck mute error %@", error.localizedDescription ?: @"");
            }
        }];
    }

    if (completion) {
        completion();
    }
}

@end
