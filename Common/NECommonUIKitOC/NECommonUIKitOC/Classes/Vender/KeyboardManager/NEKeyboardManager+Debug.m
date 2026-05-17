// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+OrientationNotification.h"
#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import <objc/runtime.h>

static void *NEEnableDebuggingKey = &NEEnableDebuggingKey;
static NSInteger NEKeyboardManagerIndentation = 0;

@implementation NEKeyboardManager (Debug)

- (BOOL)enableDebugging {
  return [objc_getAssociatedObject(self, NEEnableDebuggingKey) boolValue];
}

- (void)setEnableDebugging:(BOOL)enableDebugging {
  objc_setAssociatedObject(self, NEEnableDebuggingKey, @(enableDebugging), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)registerAllNotifications {
  NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
  [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [center addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
  [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [center addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

  [self registerTextFieldViewClass:UITextField.class
      didBeginEditingNotificationName:UITextFieldTextDidBeginEditingNotification
        didEndEditingNotificationName:UITextFieldTextDidEndEditingNotification];
  [self registerTextFieldViewClass:UITextView.class
      didBeginEditingNotificationName:UITextViewTextDidBeginEditingNotification
        didEndEditingNotificationName:UITextViewTextDidEndEditingNotification];

  [center addObserver:self
             selector:@selector(willChangeStatusBarOrientation:)
                 name:UIApplicationWillChangeStatusBarOrientationNotification
               object:UIApplication.sharedApplication];
}

- (void)unregisterAllNotifications {
  NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
  [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [center removeObserver:self name:UIKeyboardDidShowNotification object:nil];
  [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  [center removeObserver:self name:UIKeyboardDidHideNotification object:nil];

  [self unregisterTextFieldViewClass:UITextField.class
        didBeginEditingNotificationName:UITextFieldTextDidBeginEditingNotification
          didEndEditingNotificationName:UITextFieldTextDidEndEditingNotification];
  [self unregisterTextFieldViewClass:UITextView.class
        didBeginEditingNotificationName:UITextViewTextDidBeginEditingNotification
          didEndEditingNotificationName:UITextViewTextDidEndEditingNotification];

  [center removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:UIApplication.sharedApplication];
}

- (void)showLog:(NSString *)logString {
  [self showLog:logString indentation:0];
}

- (void)showLog:(NSString *)logString indentation:(NSInteger)indentation {
  if (!self.enableDebugging) {
    return;
  }

  if (indentation < 0) {
    NEKeyboardManagerIndentation = MAX(0, NEKeyboardManagerIndentation + indentation);
  }

  NSMutableString *prefix = [NSMutableString stringWithString:@"NEKeyboardManager"];
  for (NSInteger index = 0; index <= NEKeyboardManagerIndentation; index++) {
    [prefix appendString:@"|\t"];
  }
  NSLog(@"%@%@", prefix, logString);

  if (indentation > 0) {
    NEKeyboardManagerIndentation += indentation;
  }
}

@end
