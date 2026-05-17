// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+OrientationNotification.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+Position.h"
#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"

@implementation NEKeyboardManager (OrientationNotification)

- (void)willChangeStatusBarOrientation:(NSNotification *)notification {
  UIInterfaceOrientation currentStatusBarOrientation = UIInterfaceOrientationUnknown;
  if (@available(iOS 13.0, *)) {
    currentStatusBarOrientation = [self keyWindow].windowScene.interfaceOrientation;
  } else {
    currentStatusBarOrientation = UIApplication.sharedApplication.statusBarOrientation;
  }

  NSNumber *statusBarOrientationNumber = notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
  if (!statusBarOrientationNumber ||
      currentStatusBarOrientation == statusBarOrientationNumber.integerValue) {
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** willChangeStatusBarOrientation: started ******" indentation:1];

  if ([self.textFieldView isKindOfClass:[UITextView class]] &&
      self.isTextViewContentInsetChanged) {
    self.isTextViewContentInsetChanged = NO;
    UITextView *textView = (UITextView *)self.textFieldView;
    if (!UIEdgeInsetsEqualToEdgeInsets(textView.contentInset, self.startingTextViewContentInsets)) {
      [UIView animateWithDuration:self.animationDuration
                            delay:0
                          options:self.animationCurve
                       animations:^{
        [self showLog:[NSString stringWithFormat:@"Restoring textView.contentInset to: %@", NSStringFromUIEdgeInsets(self.startingTextViewContentInsets)]];
        textView.contentInset = self.startingTextViewContentInsets;
        textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets;
      } completion:nil];
    }
  }

  [self restorePosition];

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** willChangeStatusBarOrientation: ended: %f seconds ******", elapsedTime] indentation:-1];
}

@end
