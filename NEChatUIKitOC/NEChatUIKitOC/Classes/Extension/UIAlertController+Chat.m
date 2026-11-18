// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIAlertController+Chat.h"
#import "NEChatUIConstant.h"

@implementation UIAlertController (Chat)

+ (UIAlertController *)reconfirmAlertViewWithTitle:(NSString *)title
                                           message:(NSString *)message
                                           confirm:(void (^)(void))confirm {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:chatLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:chatLocalizable(@"ok")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
    if (confirm) {
      confirm();
    }
  }];

  [alert addAction:cancelAction];
  [alert addAction:okAction];
  return alert;
}

+ (UIAlertController *)singleAlertViewWithTitle:(NSString *)title
                                        message:(NSString *)message
                                        confirm:(void (^)(void))confirm {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *okAction = [UIAlertAction actionWithTitle:chatLocalizable(@"ok")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
    if (confirm) {
      confirm();
    }
  }];

  [alert addAction:okAction];
  return alert;
}

@end
