#import <UIKit/UIKit.h>

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic, nullable) UIWindow *window;

- (void)startWithInitialNotificationUserInfo:(nullable NSDictionary<NSString *, id> *)initialNotificationUserInfo;

@end
