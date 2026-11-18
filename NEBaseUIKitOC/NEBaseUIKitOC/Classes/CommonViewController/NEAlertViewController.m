// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAlertViewController.h"

#import "UIWindow+NEActiveKeyWindow.h"

static UIWindow *_alertWindow = nil;
/// 弹窗出现前的宿主窗口；收起时恢复它，而不是取应用级 keyWindow（多 scene 下可能属于其他场景）。
static __weak UIWindow *_ne_presentingWindow = nil;

@implementation NEAlertViewController

+ (void)presentAlertWithTitle:(nullable NSString *)title
               messageContent:(nullable NSString *)messageContent
                  cancelTitle:(nullable NSString *)cancelTitle
                 confirmTitle:(nullable NSString *)confirmTitle
               cancelComplete:(nullable void (^)(void))cancelComplete
              confirmComplete:(nullable void (^)(void))confirmComplete {
  UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title
                                                                   message:messageContent
                                                            preferredStyle:UIAlertControllerStyleAlert];
  if (cancelTitle) {
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *_) {
      [_alertWindow resignKeyWindow];
      _alertWindow = nil;
      [self ne_restoreHostWindow];
      if (cancelComplete) cancelComplete();
    }];
    [alertVC addAction:cancelAction];
  }
  if (confirmTitle) {
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmTitle
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_) {
      [_alertWindow resignKeyWindow];
      _alertWindow = nil;
      [self ne_restoreHostWindow];
      if (confirmComplete) confirmComplete();
    }];
    [alertVC addAction:confirmAction];
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    UIWindow *hostWindow = [UIWindow ne_activeKeyWindow];
    _ne_presentingWindow = hostWindow;
    if (hostWindow.windowScene) {
      _alertWindow = [[UIWindow alloc] initWithWindowScene:hostWindow.windowScene];
      _alertWindow.frame = hostWindow.windowScene.coordinateSpace.bounds;
    } else {
      _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    _alertWindow.rootViewController = [[UIViewController alloc] init];
    _alertWindow.windowLevel = UIWindowLevelNormal;
    [_alertWindow makeKeyAndVisible];
    [_alertWindow.rootViewController presentViewController:alertVC animated:YES completion:nil];
  });
}

+ (void)removePresentAlertViewController {
  [_alertWindow resignKeyWindow];
  _alertWindow = nil;
  [self ne_restoreHostWindow];
}

+ (void)ne_restoreHostWindow {
  if (_ne_presentingWindow) {
    [_ne_presentingWindow makeKeyAndVisible];
  } else {
    [[UIWindow ne_activeKeyWindow] makeKeyAndVisible];
  }
  _ne_presentingWindow = nil;
}

@end
