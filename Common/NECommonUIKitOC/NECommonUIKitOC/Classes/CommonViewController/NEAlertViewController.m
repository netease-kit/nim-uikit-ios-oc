// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAlertViewController.h"

static UIWindow *_alertWindow = nil;

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
      [[UIApplication sharedApplication].keyWindow makeKeyAndVisible];
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
      [[UIApplication sharedApplication].keyWindow makeKeyAndVisible];
      if (confirmComplete) confirmComplete();
    }];
    [alertVC addAction:confirmAction];
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _alertWindow.rootViewController = [[UIViewController alloc] init];
    _alertWindow.windowLevel = UIWindowLevelNormal;
    [_alertWindow makeKeyAndVisible];
    [_alertWindow.rootViewController presentViewController:alertVC animated:YES completion:nil];
  });
}

+ (void)removePresentAlertViewController {
  [_alertWindow resignKeyWindow];
  _alertWindow = nil;
  [[UIApplication sharedApplication].keyWindow makeKeyAndVisible];
}

@end
