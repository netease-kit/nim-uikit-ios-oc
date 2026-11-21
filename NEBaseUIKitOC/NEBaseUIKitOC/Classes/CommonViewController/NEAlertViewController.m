// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAlertViewController.h"

#import "UIWindow+NEActiveKeyWindow.h"

static UIWindow *_alertWindow = nil;
/// 弹窗出现前的宿主窗口；收起时恢复它，而不是取应用级 keyWindow（多 scene 下可能属于其他场景）。
static __weak UIWindow *_ne_presentingWindow = nil;

/// 弹窗窗口的根控制器：只负责让窗口跟随 scene 尺寸。
///
/// 与登录窗口同因：scene 附加窗口在真机上不会被系统自动改尺寸（模拟器会强制吸附），
/// 折叠/展开期间弹出的 alert 会停在旧尺寸。这里在 trait/appear/layout 三处兜底同步。
@interface NEAlertWindowRootViewController : UIViewController
@end

@implementation NEAlertWindowRootViewController

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self ne_syncWindowFrameToScene];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self ne_syncWindowFrameToScene];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  // 折叠/展开会改变 size class；即使窗口没有重新布局也能收到这个回调。
  [self ne_syncWindowFrameToScene];
}

- (void)ne_syncWindowFrameToScene {
  UIWindow *window = self.view.window;
  UIWindowScene *scene = window.windowScene;
  if (!window || !scene) {
    return;
  }
  CGRect target = scene.coordinateSpace.bounds;
  if (target.size.width <= 0.5 || target.size.height <= 0.5) {
    return;
  }
  CGRect current = window.frame;
  if (fabs(current.size.width - target.size.width) <= 0.5 &&
      fabs(current.size.height - target.size.height) <= 0.5) {
    return;
  }
  window.frame = target;
}

@end

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
    _alertWindow.rootViewController = [[NEAlertWindowRootViewController alloc] init];
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
