// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIColor+NEUIKitDefault.h"
#import "ViewControllerExtension.h"
#import "NECustomActionSheetController.h"
#import "NEAdaptiveBottomSheetController.h"
#import "NEAdaptiveDeviceGate.h"
#import "ExpandButton.h"
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import "UIAlertController.h"
#import "NEViewExtension.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <NEChatKit/NEAuthManager.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <objc/runtime.h>
#import "NECommonUIConstant.h"

static void *NERightNavButtonKey = &NERightNavButtonKey;
static void *NELeftNavButtonKey = &NELeftNavButtonKey;

static UIWindow *NEBaseUIKitKeyWindow(void) {
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (![scene isKindOfClass:[UIWindowScene class]]) {
        continue;
      }
      UIWindowScene *windowScene = (UIWindowScene *)scene;
      if (windowScene.activationState != UISceneActivationStateForegroundActive) {
        continue;
      }
      for (UIWindow *window in windowScene.windows) {
        if (window.isKeyWindow) {
          return window;
        }
      }
    }
  }
  return UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.delegate.window;
}

@implementation UIViewController (NEViewControllerExtension)

- (ExpandButton *)rightNavButton {
  ExpandButton *button = objc_getAssociatedObject(self, NERightNavButtonKey);
  if (!button) {
    button = [[ExpandButton alloc] initWithFrame:CGRectMake(0, 0, 60.0, 44.0)];
    [button setTitleColor:UIColor.ne_defaultPrimaryColor forState:UIControlStateNormal];
    button.titleLabel.font = [NEConstant defaultTextFont:16.0];
    self.rightNavButton = button;
  }
  return button;
}

- (void)setRightNavButton:(ExpandButton *)rightNavButton {
  objc_setAssociatedObject(self, NERightNavButtonKey, rightNavButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ExpandButton *)leftNavButton {
  ExpandButton *button = objc_getAssociatedObject(self, NELeftNavButtonKey);
  if (!button) {
    button = [[ExpandButton alloc] initWithFrame:CGRectMake(0, 0, 60.0, 44.0)];
    [button setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
    button.titleLabel.font = [NEConstant defaultTextFont:16.0];
    self.leftNavButton = button;
  }
  return button;
}

- (void)setLeftNavButton:(ExpandButton *)leftNavButton {
  objc_setAssociatedObject(self, NELeftNavButtonKey, leftNavButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addLeftImageAction:(UIImage *)image
                  selector:(SEL)selector
                    target:(id)target
                 tintColor:(UIColor *)tintColor {
  UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:target
                                                              action:selector];
  leftItem.tintColor = tintColor ?: UIColor.ne_greyText;
  self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)addLeftTitleAction:(NSString *)title
                  selector:(SEL)selector
                    target:(id)target
                 tintColor:(UIColor *)tintColor {
  [[self leftNavButton] removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
  [[self leftNavButton] addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
  [[self leftNavButton] setTitle:title forState:UIControlStateNormal];
  UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftNavButton];
  leftItem.tintColor = tintColor ?: UIColor.ne_defaultPrimaryColor;
  self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)addRightImageAction:(UIImage *)image
                   selector:(SEL)selector
                     target:(id)target
                  tintColor:(UIColor *)tintColor {
  UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                 style:UIBarButtonItemStylePlain
                                                                target:target
                                                                action:selector];
  rightItem.tintColor = tintColor ?: UIColor.ne_greyText;
  self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)addRightTitleAction:(NSString *)title
                   selector:(SEL)selector
                     target:(id)target
                  tintColor:(UIColor *)tintColor {
  [[self rightNavButton] removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
  [[self rightNavButton] addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
  [[self rightNavButton] setTitle:title forState:UIControlStateNormal];
  UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightNavButton];
  rightItem.tintColor = tintColor ?: UIColor.ne_defaultPrimaryColor;
  self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)showAlert:(NSString *)title
          message:(NSString *)message
         sureText:(NSString *)sureText
       cancelText:(NSString *)cancelText
    sureTextColor:(UIColor *)sureTextColor
  cancelTextColor:(UIColor *)cancelTextColor
         sureBack:(AlertCallBack)sureBack
       cancelBack:(AlertCallBack)cancelBack {
  NSString *resolvedTitle = title ?: commonLocalizable(@"tip");
  NSString *resolvedSureText = sureText ?: commonLocalizable(@"sure");
  NSString *resolvedCancelText = cancelText ?: commonLocalizable(@"cancel");

  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:resolvedTitle
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [[alertController.view findLabelWithString:resolvedTitle] setAccessibilityIdentifier:@"id.dialogTitle"];
  [[alertController.view findLabelWithString:message] setAccessibilityIdentifier:@"id.dialogContent"];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:resolvedCancelText
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(__unused UIAlertAction *action) {
    if (cancelBack) {
      cancelBack();
    }
  }];
  cancelAction.accessibilityIdentifier = @"id.dialogNegative";
  [alertController addAction:cancelAction];

  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:resolvedSureText
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    if (sureBack) {
      sureBack();
    }
  }];
  sureAction.accessibilityIdentifier = @"id.dialogPositive";
  [alertController addAction:sureAction];

  if (sureTextColor) {
    [sureAction setValue:sureTextColor forKey:@"titleTextColor"];
  }
  if (cancelTextColor) {
    [cancelAction setValue:cancelTextColor forKey:@"titleTextColor"];
  }

  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showAlert:(NSString *)title
          message:(NSString *)message
             sure:(void(^)(UIAlertAction *action))sureBlock {
  [self ne_showAlert:title message:message sure:sureBlock];
}

- (void)ne_showAlert:(NSString *)title
             message:(NSString *)message
                sure:(void(^)(UIAlertAction *action))sureBlock {
  NSString *resolvedTitle = title ?: commonLocalizable(@"tip");
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:resolvedTitle
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [[alertController.view findLabelWithString:resolvedTitle] setAccessibilityIdentifier:@"id.dialogTitle"];
  [[alertController.view findLabelWithString:message] setAccessibilityIdentifier:@"id.dialogContent"];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
  cancelAction.accessibilityIdentifier = @"id.dialogNegative";
  [alertController addAction:cancelAction];

  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:commonLocalizable(@"sure")
                                                       style:UIAlertActionStyleDefault
                                                     handler:sureBlock];
  sureAction.accessibilityIdentifier = @"id.dialogPositive";
  [alertController addAction:sureAction];

  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSingleAlert:(NSString *)title
                message:(NSString *)message
               sureText:(NSString *)sureText
               sureBack:(AlertCallBack)sureBack {
  NSString *resolvedTitle = title ?: commonLocalizable(@"tip");
  NSString *resolvedSureText = sureText ?: commonLocalizable(@"sure");

  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:resolvedTitle
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [[alertController.view findLabelWithString:resolvedTitle] setAccessibilityIdentifier:@"id.dialogTitle"];
  [[alertController.view findLabelWithString:message] setAccessibilityIdentifier:@"id.dialogContent"];

  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:resolvedSureText
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    if (sureBack) {
      sureBack();
    }
  }];
  sureAction.accessibilityIdentifier = @"id.dialogPositive";
  [alertController addAction:sureAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSingleAlert:(NSString *)title
                message:(NSString *)message
                handler:(void (^)(void))handler {
  [self ne_showSingleAlert:title message:message handler:handler];
}

- (void)ne_showSingleAlert:(NSString *)title
                   message:(NSString *)message
                   handler:(void (^)(void))handler {
  [self showSingleAlert:title
                message:message
               sureText:commonLocalizable(@"sure")
               sureBack:^{
    if (handler) {
      handler();
    }
  }];
}

- (void)showToast:(NSString *)message {
  [self ne_showToast:message];
}

- (void)ne_showToast:(NSString *)message {
  UIWindow *window = NEBaseUIKitKeyWindow();
  [window endEditing:YES];
  [self.view ne_makeToast:message ?: @""
                 duration:2.0
                 position:NEToastPositionCenter];
}

- (void)showToastInWindow:(NSString *)message {
  UIWindow *window = NEBaseUIKitKeyWindow();
  [window endEditing:YES];
  [window ne_makeToast:message ?: @""
              duration:2.0
              position:NEToastPositionCenter];
}

- (void)showActionSheet:(NSArray<UIAlertAction *> *)actions {
  [self ne_showActionSheet:actions];
}

- (void)ne_showActionSheet:(NSArray<UIAlertAction *> *)actions {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

  [actions enumerateObjectsUsingBlock:^(UIAlertAction *action, NSUInteger idx, __unused BOOL *stop) {
    [action setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
    action.accessibilityIdentifier = [NSString stringWithFormat:@"id.action%lu", (unsigned long)(idx + 1)];
    [alertController addAction:action];
  }];

  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions {
  [self ne_showCustomActionSheet:actions];
}

- (void)ne_showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions {
  NECustomActionSheetController *alertController = [[NECustomActionSheetController alloc] init];
  [actions enumerateObjectsUsingBlock:^(NECustomAlertAction *action, NSUInteger idx, __unused BOOL *stop) {
    action.contentText.accessibilityIdentifier = [NSString stringWithFormat:@"id.action%lu", (unsigned long)(idx + 1)];
  }];

  for (NECustomAlertAction *action in [actions reverseObjectEnumerator]) {
    [alertController addAction:action actionHeight:51.0];
  }
  alertController.cancelAction.contentText.text = commonLocalizable(@"cancel");
  alertController.cancelAction.contentText.accessibilityIdentifier =
      [NSString stringWithFormat:@"id.action%lu", (unsigned long)(actions.count + 1)];
  [self showBottomSheetInDetailColumn:alertController animated:YES completion:nil];
}

- (BOOL)ne_isHostedInDetailColumn {
  UIView *host = self.isViewLoaded ? self.view : nil;
  UIWindow *window = host.window;
  if (!host || !window) {
    return NO;
  }
  CGRect frameInWindow = [host convertRect:host.bounds toView:window];
  return [NEAdaptiveColumnGeometry isDetailColumnWithFrameInWindow:frameInWindow
                                                      windowWidth:CGRectGetWidth(window.bounds)
                                                  safeAreaInsets:window.safeAreaInsets];
}

- (void)showBottomSheetInDetailColumn:(UIViewController *)controller
                             animated:(BOOL)animated
                           completion:(void (^)(void))completion {
  NEAdaptiveBottomSheetController *sheet =
      [controller isKindOfClass:[NEAdaptiveBottomSheetController class]]
          ? (NEAdaptiveBottomSheetController *)controller
          : nil;
  UIView *host = self.isViewLoaded ? self.view : nil;
  UIWindow *window = host.window;
  if (NEAdaptiveDeviceGate.adaptiveHostActive && sheet && host && window) {
    // 弹窗宽度要扣掉这块；已在右列时列宽本身就是正确宽度。
    BOOL isFullWindow = CGRectGetWidth(host.bounds) >= CGRectGetWidth(window.bounds) - 1;
    CGFloat railInset = isFullWindow ? MAX(0, window.safeAreaInsets.right) : 0;
    CGFloat width = MAX(0, CGRectGetWidth(host.bounds) - railInset);
    if (width > 0) {
      [sheet loadViewIfNeeded];
      UIViewController *owner = window.rootViewController ?: self;
      [owner addChildViewController:sheet];
      [owner.view addSubview:sheet.view];
      [sheet didMoveToParentViewController:owner];
      [sheet embedInColumnWithPresenter:self container:owner.view];

      __weak NEAdaptiveBottomSheetController *weakSheet = sheet;
      void (^dismissSheet)(void) = ^{
        NEAdaptiveBottomSheetController *strongSheet = weakSheet;
        if (!strongSheet) {
          return;
        }
        [strongSheet willMoveToParentViewController:nil];
        [strongSheet beginAppearanceTransition:NO animated:NO];
        [strongSheet.view removeFromSuperview];
        [strongSheet endAppearanceTransition];
        [strongSheet removeFromParentViewController];
        [strongSheet detachFromColumn];
        strongSheet.columnDismissHandler = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidDismiss"
                                                            object:nil];
      };
      sheet.columnDismissHandler = dismissSheet;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidPresent"
                                                          object:nil
                                                        userInfo:@{@"dismiss": dismissSheet}];
      if (completion) {
        completion();
      }
      return;
    }
  }
  if ([self ne_isHostedInDetailColumn]) {
    // 与列内子页面保持一致：呈现上下文取当前右列，遮罩和卡片都只在右列范围内排版。
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.definesPresentationContext = YES;
  }
  [self presentViewController:controller animated:animated completion:completion];
}

- (void)showBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                      editing:(BOOL)editing {
  [self ne_showBottomVideoAction:delegate editing:editing];
}

- (void)ne_showBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                         editing:(BOOL)editing {
  __weak typeof(self) weakSelf = self;
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  UIAlertAction *takingPicturesAction = [UIAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(__unused UIAlertAction *action) {
    [weakSelf ne_goCamera:delegate editing:editing isVideo:NO];
  }];
  [takingPicturesAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  takingPicturesAction.accessibilityIdentifier = @"id.action1";

  UIAlertAction *localPhotoAction = [UIAlertAction actionWithTitle:commonLocalizable(@"camera")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(__unused UIAlertAction *action) {
    [weakSelf ne_goCamera:delegate editing:editing isVideo:YES];
  }];
  [localPhotoAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  localPhotoAction.accessibilityIdentifier = @"id.action2";

  [alertController addAction:cancelAction];
  [alertController addAction:takingPicturesAction];
  [alertController addAction:localPhotoAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCustomBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                            editing:(BOOL)editing {
  [self ne_showCustomBottomVideoAction:delegate editing:editing];
}

- (void)ne_showCustomBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                               editing:(BOOL)editing {
  __weak typeof(self) weakSelf = self;
  NECustomAlertAction *takingPicturesAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"camera")
                                                                            handler:^{
    [weakSelf ne_goCamera:delegate editing:editing isVideo:YES];
  }];
  NECustomAlertAction *localPhotoAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                        handler:^{
    [weakSelf ne_goCamera:delegate editing:editing isVideo:NO];
  }];
  [self ne_showCustomActionSheet:@[ localPhotoAction, takingPicturesAction ]];
}

- (void)showBottomFileAction:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIDocumentPickerDelegate>)delegate {
  [self ne_showBottomFileAction:delegate];
}

- (void)ne_showBottomFileAction:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIDocumentPickerDelegate>)delegate {
  __weak typeof(self) weakSelf = self;
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  UIAlertAction *selectAlbumAction = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(__unused UIAlertAction *action) {
    [weakSelf goPhotoAlbumWithVideo:delegate completion:nil];
  }];
  [selectAlbumAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  selectAlbumAction.accessibilityIdentifier = @"id.action2";

  UIAlertAction *selectICloudAction = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_icloud")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(__unused UIAlertAction *action) {
    [weakSelf goICloudDocument:delegate];
  }];
  [selectICloudAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  selectICloudAction.accessibilityIdentifier = @"id.action1";

  [alertController addAction:cancelAction];
  [alertController addAction:selectICloudAction];
  [alertController addAction:selectAlbumAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCustomBottomFileAction:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIDocumentPickerDelegate>)delegate {
  [self ne_showCustomBottomFileAction:delegate];
}

- (void)ne_showCustomBottomFileAction:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIDocumentPickerDelegate>)delegate {
  __weak typeof(self) weakSelf = self;
  NECustomAlertAction *selectAlbumAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                                        handler:^{
    [weakSelf goPhotoAlbumWithVideo:delegate completion:nil];
  }];
  NECustomAlertAction *selectICloudAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"select_from_icloud")
                                                                         handler:^{
    [weakSelf goICloudDocument:delegate];
  }];
  [self ne_showCustomActionSheet:@[ selectICloudAction, selectAlbumAction ]];
}

- (void)showBottomTelAction:(NSURL *)url {
  [self ne_showBottomTelAction:url];
}

- (void)ne_showBottomTelAction:(NSURL *)url {
  NSString *tel = [url.absoluteString stringByReplacingOccurrencesOfString:@"tel:" withString:@""];
  NSString *title = [NSString stringWithFormat:commonLocalizable(@"detect_tel_title"), tel];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  UIAlertAction *callAction = [UIAlertAction actionWithTitle:commonLocalizable(@"detect_tel_call")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  }];
  [callAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  callAction.accessibilityIdentifier = @"id.action2";

  __weak typeof(self) weakSelf = self;
  UIAlertAction *copyAction = [UIAlertAction actionWithTitle:commonLocalizable(@"detect_tel_copy")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    UIPasteboard.generalPasteboard.string = tel;
    [weakSelf ne_showToast:commonLocalizable(@"copy_success")];
  }];
  [copyAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  copyAction.accessibilityIdentifier = @"id.action1";

  [alertController addAction:cancelAction];
  [alertController addAction:callAction];
  [alertController addAction:copyAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCustomBottomTelAction:(NSURL *)url {
  [self ne_showCustomBottomTelAction:url];
}

- (void)ne_showCustomBottomTelAction:(NSURL *)url {
  NSString *tel = [url.absoluteString stringByReplacingOccurrencesOfString:@"tel:" withString:@""];
  __weak typeof(self) weakSelf = self;

  NECustomAlertAction *titleAction = [NECustomAlertAction actionWithTitle:[NSString stringWithFormat:commonLocalizable(@"detect_tel_title"), tel]
                                                                  handler:nil];
  titleAction.contentText.font = [UIFont systemFontOfSize:13.0];
  titleAction.contentText.textColor = UIColor.ne_lightText;

  NECustomAlertAction *callAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"detect_tel_call")
                                                                 handler:^{
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  }];
  NECustomAlertAction *copyAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"detect_tel_copy")
                                                                 handler:^{
    UIPasteboard.generalPasteboard.string = tel;
    [weakSelf ne_showToast:commonLocalizable(@"copy_success")];
  }];
  [self ne_showCustomActionSheet:@[ titleAction, callAction, copyAction ]];
}

- (void)showBottomMailAction:(NSURL *)url {
  [self ne_showBottomMailAction:url];
}

- (void)ne_showBottomMailAction:(NSURL *)url {
  NSString *mail = [url.absoluteString stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
  NSString *title = [NSString stringWithFormat:commonLocalizable(@"detect_mailto_title"), mail];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  UIAlertAction *sendAction = [UIAlertAction actionWithTitle:commonLocalizable(@"detect_mailto_send")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  }];
  [sendAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  sendAction.accessibilityIdentifier = @"id.action2";

  __weak typeof(self) weakSelf = self;
  UIAlertAction *copyAction = [UIAlertAction actionWithTitle:commonLocalizable(@"detect_mailto_copy")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    UIPasteboard.generalPasteboard.string = mail;
    [weakSelf ne_showToast:commonLocalizable(@"copy_success")];
  }];
  [copyAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  copyAction.accessibilityIdentifier = @"id.action1";

  [alertController addAction:cancelAction];
  [alertController addAction:sendAction];
  [alertController addAction:copyAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCustomBottomMailAction:(NSURL *)url {
  [self ne_showCustomBottomMailAction:url];
}

- (void)ne_showCustomBottomMailAction:(NSURL *)url {
  NSString *mail = [url.absoluteString stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
  __weak typeof(self) weakSelf = self;

  NECustomAlertAction *titleAction = [NECustomAlertAction actionWithTitle:[NSString stringWithFormat:commonLocalizable(@"detect_mailto_title"), mail]
                                                                  handler:nil];
  titleAction.contentText.font = [UIFont systemFontOfSize:13.0];
  titleAction.contentText.textColor = UIColor.ne_lightText;

  NECustomAlertAction *sendAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"detect_mailto_send")
                                                                 handler:^{
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  }];
  NECustomAlertAction *copyAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"detect_mailto_copy")
                                                                 handler:^{
    UIPasteboard.generalPasteboard.string = mail;
    [weakSelf ne_showToast:commonLocalizable(@"copy_success")];
  }];
  [self ne_showCustomActionSheet:@[ titleAction, sendAction, copyAction ]];
}

- (void)fixAlertOnIpad:(UIAlertController *)alertViewController {
  [alertViewController fixIpadAction];
}

- (void)showBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                editing:(BOOL)editing
           checkNetwork:(BOOL)checkNetwork
          clickedAction:(void (^)(void))clickedAction
      presentCompletion:(void (^)(void))presentCompletion {
  [self ne_showBottomAlert:delegate
                   editing:editing
              checkNetwork:checkNetwork
             clickedAction:clickedAction
         presentCompletion:presentCompletion];
}

- (void)ne_showBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                   editing:(BOOL)editing
              checkNetwork:(BOOL)checkNetwork
             clickedAction:(void (^)(void))clickedAction
         presentCompletion:(void (^)(void))presentCompletion {
  if (checkNetwork && [[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self ne_showToast:commonLocalizable(@"network_error")];
    return;
  }

  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
  __weak typeof(self) weakSelf = self;

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  UIAlertAction *takingPicturesAction = [UIAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(__unused UIAlertAction *action) {
    [weakSelf ne_goCamera:delegate editing:editing isVideo:NO];
    if (clickedAction) {
      clickedAction();
    }
  }];
  [takingPicturesAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  takingPicturesAction.accessibilityIdentifier = @"id.action1";

  UIAlertAction *localPhotoAction = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(__unused UIAlertAction *action) {
    [weakSelf ne_goPhotoAlbum:delegate editing:editing isVideo:NO];
    if (clickedAction) {
      clickedAction();
    }
  }];
  [localPhotoAction setValue:UIColor.ne_darkText forKey:@"_titleTextColor"];
  localPhotoAction.accessibilityIdentifier = @"id.action2";

  [alertController addAction:cancelAction];
  [alertController addAction:takingPicturesAction];
  [alertController addAction:localPhotoAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:presentCompletion];
}

- (void)showCustomBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                      editing:(BOOL)editing
                 checkNetwork:(BOOL)checkNetwork {
  [self ne_showCustomBottomAlert:delegate editing:editing checkNetwork:checkNetwork];
}

- (void)ne_showCustomBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                         editing:(BOOL)editing
                    checkNetwork:(BOOL)checkNetwork {
  if (checkNetwork && [[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self ne_showToast:commonLocalizable(@"network_error")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  NECustomAlertAction *takingPicturesAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                            handler:^{
    [weakSelf ne_goCamera:delegate editing:editing isVideo:NO];
  }];
  NECustomAlertAction *localPhotoAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                                        handler:^{
    [weakSelf ne_goPhotoAlbum:delegate editing:editing isVideo:NO];
  }];
  [self ne_showCustomActionSheet:@[ takingPicturesAction, localPhotoAction ]];
}

- (void)showBottomSelectAlert:(NSString *)firstContent
                secondContent:(NSString *)secondContent
                  selectValue:(void(^)(NSInteger value))selectValue {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  alert.modalPresentationStyle = UIModalPresentationPopover;

  UIAlertAction *first = [UIAlertAction actionWithTitle:firstContent
                                                  style:UIAlertActionStyleDefault
                                                handler:^(__unused UIAlertAction *action) {
    if (selectValue) {
      selectValue(0);
    }
  }];
  [first setValue:[UIColor ne_colorWithHexString:@"0x333333"] forKey:@"_titleTextColor"];
  first.accessibilityIdentifier = @"id.action1";

  UIAlertAction *second = [UIAlertAction actionWithTitle:secondContent
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(__unused UIAlertAction *action) {
    if (selectValue) {
      selectValue(1);
    }
  }];
  [second setValue:[UIColor ne_colorWithHexString:@"0x333333"] forKey:@"_titleTextColor"];
  second.accessibilityIdentifier = @"id.action2";

  UIAlertAction *cancel = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
  [cancel setValue:[UIColor ne_colorWithHexString:@"0x333333"] forKey:@"_titleTextColor"];
  cancel.accessibilityIdentifier = @"id.action3";

  [alert addAction:first];
  [alert addAction:second];
  [alert addAction:cancel];
  [self fixAlertOnIpad:alert];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)goCamera:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
         editing:(BOOL)editing
         isVideo:(BOOL)isVideo {
  [self ne_goCamera:delegate editing:editing isVideo:isVideo];
}

- (void)ne_goCamera:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
            editing:(BOOL)editing
            isVideo:(BOOL)isVideo {
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  UIImagePickerController *cameraPicker = [[UIImagePickerController alloc] init];
  cameraPicker.delegate = delegate;
  cameraPicker.allowsEditing = editing;
  cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  if (isVideo) {
    cameraPicker.mediaTypes = @[ @"public.movie" ];
  }

  void (^presentCamera)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf presentViewController:cameraPicker animated:YES completion:nil];
    });
  };

  if (authStatus == AVAuthorizationStatusAuthorized) {
    presentCamera();
  } else if (authStatus == AVAuthorizationStatusDenied) {
    [self ne_showSingleAlert:nil message:commonLocalizable(@"jump_camera_setting") handler:nil];
  } else if (authStatus == AVAuthorizationStatusRestricted) {
    [self ne_showSingleAlert:nil
                     message:[NSString stringWithFormat:@"%@\n%@", commonLocalizable(@"camera_limit"), commonLocalizable(@"jump_camera_setting")]
                     handler:nil];
  } else if (authStatus == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
      if (granted) {
        presentCamera();
      }
    }];
  }
}

- (void)goPhotoAlbum:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
             editing:(BOOL)editing
             isVideo:(BOOL)isVideo {
  [self ne_goPhotoAlbum:delegate editing:editing isVideo:isVideo];
}

- (void)ne_goPhotoAlbum:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                editing:(BOOL)editing
                isVideo:(BOOL)isVideo {
  __weak typeof(self) weakSelf = self;
  void (^showSettingAlert)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf ne_showSingleAlert:nil message:commonLocalizable(@"jump_photo_setting") handler:nil];
    });
  };

  if (@available(iOS 14.0, *)) {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
      showSettingAlert();
      return;
    }
    if (status == PHAuthorizationStatusNotDetermined) {
      [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus authorizationStatus) {
        if (authorizationStatus == PHAuthorizationStatusDenied ||
            authorizationStatus == PHAuthorizationStatusRestricted) {
          showSettingAlert();
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showPicker:delegate isVideo:isVideo editing:editing];
          });
        }
      }];
      return;
    }
  } else {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
      showSettingAlert();
      return;
    }
    if (status == PHAuthorizationStatusNotDetermined) {
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
        if (authorizationStatus == PHAuthorizationStatusDenied ||
            authorizationStatus == PHAuthorizationStatusRestricted) {
          showSettingAlert();
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showPicker:delegate isVideo:isVideo editing:editing];
          });
        }
      }];
      return;
    }
  }

  [self showPicker:delegate isVideo:isVideo editing:editing];
}

- (void)showPicker:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
           isVideo:(BOOL)isVideo
           editing:(BOOL)editing {
  UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
  photoPicker.delegate = delegate;
  photoPicker.allowsEditing = editing;
  photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  if (isVideo) {
    photoPicker.mediaTypes = @[ @"public.movie" ];
  }
  photoPicker.modalPresentationStyle = UIModalPresentationOverFullScreen;
  [self presentViewController:photoPicker animated:YES completion:nil];
}

- (void)goPhotoAlbumWithVideo:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate>)delegate
                    completion:(void (^)(void))completion {
  [self.view neMakeToastActivity:NEToastPositionCenter];
  __weak typeof(self) weakSelf = self;
  [NEAuthManager requestPhotoAuthorization:^(BOOL granted) {
    [weakSelf.view neHideToastActivity];
    if (!granted) {
      [weakSelf ne_showSingleAlert:nil message:commonLocalizable(@"jump_photo_setting") handler:nil];
      return;
    }

    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.delegate = delegate;
    photoPicker.mediaTypes = @[ @"public.movie", @"public.image" ];
    photoPicker.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [weakSelf presentViewController:photoPicker animated:YES completion:completion];
  }];
}

- (void)goICloudDocument:(id<UINavigationControllerDelegate,UIDocumentPickerDelegate>)delegate {
  NSArray<NSString *> *documentTypes = @[
    @"public.text",
    @"public.plain-text",
    @"public.archive",
    @"public.image",
    @"public.movie",
    @"public.data",
    @"public.content",
    @"public.text",
    @"public.source-code",
    @"public.audiovisual-content",
    @"com.adobe.pdf",
    @"com.apple.keynote.key",
    @"com.microsoft.word.doc",
    @"com.microsoft.excel.xls",
    @"com.microsoft.powerpoint.ppt",
  ];

  UIDocumentPickerViewController *documentPicker =
      [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes
                                                             inMode:UIDocumentPickerModeOpen];
  documentPicker.delegate = delegate;
  [self presentViewController:documentPicker animated:YES completion:nil];
}

@end
