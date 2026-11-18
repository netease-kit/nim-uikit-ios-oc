// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+Position.h"
#import "NEKeyboardManager+Toolbar.h"
#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "Categories/NEUIView+Hierarchy.h"
#import <objc/runtime.h>

static void *NETextFieldViewKey = &NETextFieldViewKey;
static void *NETopViewBeginOriginKey = &NETopViewBeginOriginKey;
static void *NERootViewControllerKey = &NERootViewControllerKey;
static void *NERootViewControllerWhilePopGestureRecognizerActiveKey = &NERootViewControllerWhilePopGestureRecognizerActiveKey;
static void *NETopViewBeginOriginWhilePopGestureRecognizerActiveKey = &NETopViewBeginOriginWhilePopGestureRecognizerActiveKey;

@implementation NEKeyboardManager (UITextFieldViewNotification)

- (UIView *)textFieldView {
  return ((NEWeakObjectContainer *)objc_getAssociatedObject(self, NETextFieldViewKey)).object;
}

- (void)setTextFieldView:(UIView *)textFieldView {
  objc_setAssociatedObject(self, NETextFieldViewKey, [[NEWeakObjectContainer alloc] initWithObject:textFieldView], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGPoint)topViewBeginOrigin {
  NSValue *value = objc_getAssociatedObject(self, NETopViewBeginOriginKey);
  return value ? value.CGPointValue : NEKeyboardManagerCGPointInvalidValue();
}

- (void)setTopViewBeginOrigin:(CGPoint)topViewBeginOrigin {
  objc_setAssociatedObject(self, NETopViewBeginOriginKey, [NSValue valueWithCGPoint:topViewBeginOrigin], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)rootViewController {
  return ((NEWeakObjectContainer *)objc_getAssociatedObject(self, NERootViewControllerKey)).object;
}

- (void)setRootViewController:(UIViewController *)rootViewController {
  objc_setAssociatedObject(self, NERootViewControllerKey, [[NEWeakObjectContainer alloc] initWithObject:rootViewController], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)rootViewControllerWhilePopGestureRecognizerActive {
  return ((NEWeakObjectContainer *)objc_getAssociatedObject(self, NERootViewControllerWhilePopGestureRecognizerActiveKey)).object;
}

- (void)setRootViewControllerWhilePopGestureRecognizerActive:(UIViewController *)rootViewControllerWhilePopGestureRecognizerActive {
  objc_setAssociatedObject(self, NERootViewControllerWhilePopGestureRecognizerActiveKey, [[NEWeakObjectContainer alloc] initWithObject:rootViewControllerWhilePopGestureRecognizerActive], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGPoint)topViewBeginOriginWhilePopGestureRecognizerActive {
  NSValue *value = objc_getAssociatedObject(self, NETopViewBeginOriginWhilePopGestureRecognizerActiveKey);
  return value ? value.CGPointValue : NEKeyboardManagerCGPointInvalidValue();
}

- (void)setTopViewBeginOriginWhilePopGestureRecognizerActive:(CGPoint)topViewBeginOriginWhilePopGestureRecognizerActive {
  objc_setAssociatedObject(self, NETopViewBeginOriginWhilePopGestureRecognizerActiveKey, [NSValue valueWithCGPoint:topViewBeginOriginWhilePopGestureRecognizerActive], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)textFieldViewDidBeginEditing:(NSNotification *)notification {
  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** textFieldViewDidBeginEditing: started ******" indentation:1];

  self.textFieldView = [notification.object isKindOfClass:[UIView class]] ? notification.object : nil;

  if (self.overrideKeyboardAppearance && self.textFieldView) {
    if ([self.textFieldView isKindOfClass:[UITextField class]]) {
      UITextField *textField = (UITextField *)self.textFieldView;
      if (textField.keyboardAppearance != self.keyboardAppearance) {
        textField.keyboardAppearance = self.keyboardAppearance;
        [textField reloadInputViews];
      }
    } else if ([self.textFieldView isKindOfClass:[UITextView class]]) {
      UITextView *textView = (UITextView *)self.textFieldView;
      if (textView.keyboardAppearance != self.keyboardAppearance) {
        textView.keyboardAppearance = self.keyboardAppearance;
        [textView reloadInputViews];
      }
    }
  }

  if ([self privateIsEnableAutoToolbar]) {
    if ([self.textFieldView isKindOfClass:[UIScrollView class]] &&
        [self.textFieldView respondsToSelector:@selector(isEditable)] &&
        !((UITextView *)self.textFieldView).inputAccessoryView) {
      UIScrollView *textView = (UIScrollView *)self.textFieldView;
      [UIView animateWithDuration:0.00001
                            delay:0
                          options:self.animationCurve
                       animations:^{
        [self addToolbarIfRequired];
      } completion:^(__unused BOOL finished) {
        [textView reloadInputViews];
      }];
    } else {
      [self addToolbarIfRequired];
    }
  } else {
    [self removeToolbarIfRequired];
  }

  self.resignFirstResponderGesture.enabled = [self privateShouldResignOnTouchOutside];
  [self.textFieldView.window addGestureRecognizer:self.resignFirstResponderGesture];

  if (![self privateIsEnabled]) {
    [self restorePosition];
    self.topViewBeginOrigin = NEKeyboardManagerCGPointInvalidValue();
  } else {
    if (CGPointEqualToPoint(self.topViewBeginOrigin, NEKeyboardManagerCGPointInvalidValue())) {
      self.rootViewController = [self.textFieldView neParentContainerViewController];
      if (self.rootViewController) {
        if (self.rootViewControllerWhilePopGestureRecognizerActive == self.rootViewController) {
          self.topViewBeginOrigin = self.topViewBeginOriginWhilePopGestureRecognizerActive;
        } else {
          self.topViewBeginOrigin = self.rootViewController.view.frame.origin;
        }

        self.rootViewControllerWhilePopGestureRecognizerActive = nil;
        self.topViewBeginOriginWhilePopGestureRecognizerActive = NEKeyboardManagerCGPointInvalidValue();
        [self showLog:[NSString stringWithFormat:@"Saving %@ beginning origin: %@", self.rootViewController, NSStringFromCGPoint(self.topViewBeginOrigin)]];
      }
    }

    if (self.keyboardShowing &&
        self.textFieldView &&
        ![self.textFieldView neIsAlertViewTextField]) {
      [self optimizedAdjustPosition];
    }
  }

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** textFieldViewDidBeginEditing: ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)textFieldViewDidEndEditing:(NSNotification *)notification {
  (void)notification;
  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** textFieldViewDidEndEditing: started ******" indentation:1];

  [self.textFieldView.window removeGestureRecognizer:self.resignFirstResponderGesture];

  if ([self.textFieldView isKindOfClass:[UITextView class]] &&
      self.isTextViewContentInsetChanged) {
    self.isTextViewContentInsetChanged = NO;
    UITextView *textView = (UITextView *)self.textFieldView;
    if (!UIEdgeInsetsEqualToEdgeInsets(textView.contentInset, self.startingTextViewContentInsets)) {
      [self showLog:[NSString stringWithFormat:@"Restoring textView.contentInset to: %@", NSStringFromUIEdgeInsets(self.startingTextViewContentInsets)]];
      [UIView animateWithDuration:self.animationDuration
                            delay:0
                          options:self.animationCurve
                       animations:^{
        textView.contentInset = self.startingTextViewContentInsets;
        textView.scrollIndicatorInsets = self.startingTextViewScrollIndicatorInsets;
      } completion:nil];
    }
  }

  self.textFieldView = nil;

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** textFieldViewDidEndEditing: ended: %f seconds ******", elapsedTime] indentation:-1];
}

@end
