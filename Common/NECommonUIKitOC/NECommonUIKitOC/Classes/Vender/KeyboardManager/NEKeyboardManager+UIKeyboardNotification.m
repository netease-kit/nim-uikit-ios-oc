// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+Position.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "Categories/NEUIView+Hierarchy.h"
#import "Categories/NEUIScrollView+Additions.h"
#import <objc/runtime.h>

static void *NEKeyboardShowingKey = &NEKeyboardShowingKey;
static void *NEKeyboardShowNotificationKey = &NEKeyboardShowNotificationKey;
static void *NEKeyboardFrameKey = &NEKeyboardFrameKey;
static void *NEAnimationDurationKey = &NEAnimationDurationKey;
static void *NEAnimationCurveKey = &NEAnimationCurveKey;

@implementation NEKeyboardManager (UIKeyboardNotification)

- (BOOL)keyboardShowing {
  return [objc_getAssociatedObject(self, NEKeyboardShowingKey) boolValue];
}

- (void)setKeyboardShowing:(BOOL)keyboardShowing {
  objc_setAssociatedObject(self, NEKeyboardShowingKey, @(keyboardShowing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNotification *)keyboardShowNotification {
  return objc_getAssociatedObject(self, NEKeyboardShowNotificationKey);
}

- (void)setKeyboardShowNotification:(NSNotification *)keyboardShowNotification {
  objc_setAssociatedObject(self, NEKeyboardShowNotificationKey, keyboardShowNotification, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)keyboardFrame {
  NSValue *value = objc_getAssociatedObject(self, NEKeyboardFrameKey);
  return value ? value.CGRectValue : CGRectZero;
}

- (void)setKeyboardFrame:(CGRect)keyboardFrame {
  objc_setAssociatedObject(self, NEKeyboardFrameKey, [NSValue valueWithCGRect:keyboardFrame], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)animationDuration {
  NSNumber *value = objc_getAssociatedObject(self, NEAnimationDurationKey);
  return value ? value.doubleValue : 0.25;
}

- (void)setAnimationDuration:(NSTimeInterval)animationDuration {
  objc_setAssociatedObject(self, NEAnimationDurationKey, @(animationDuration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewAnimationOptions)animationCurve {
  NSNumber *value = objc_getAssociatedObject(self, NEAnimationCurveKey);
  return value ? value.unsignedIntegerValue : UIViewAnimationOptionCurveEaseOut;
}

- (void)setAnimationCurve:(UIViewAnimationOptions)animationCurve {
  objc_setAssociatedObject(self, NEAnimationCurveKey, @(animationCurve), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)keyboardWillShow:(NSNotification *)notification {
  self.keyboardShowNotification = notification;
  self.keyboardShowing = YES;
  CGRect oldKBFrame = self.keyboardFrame;

  NSDictionary *info = notification.userInfo;
  if (info) {
    NSNumber *curve = info[UIKeyboardAnimationCurveUserInfoKey];
    if (curve) {
      self.animationCurve = (UIViewAnimationOptions)curve.unsignedIntegerValue | UIViewAnimationOptionBeginFromCurrentState;
    } else {
      self.animationCurve = UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState;
    }

    NSNumber *duration = info[UIKeyboardAnimationDurationUserInfoKey];
    self.animationDuration = duration ? duration.doubleValue : 0.25;

    NSValue *kbFrame = info[UIKeyboardFrameEndUserInfoKey];
    if (kbFrame) {
      self.keyboardFrame = kbFrame.CGRectValue;
      [self showLog:[NSString stringWithFormat:@"UIKeyboard Frame: %@", NSStringFromCGRect(self.keyboardFrame)]];
    }
  }

  if (![self privateIsEnabled]) {
    [self restorePosition];
    self.topViewBeginOrigin = NEKeyboardManagerCGPointInvalidValue();
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** keyboardWillShow: started ******" indentation:1];

  if (self.textFieldView &&
      CGPointEqualToPoint(self.topViewBeginOrigin, NEKeyboardManagerCGPointInvalidValue())) {
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

  if (!CGRectEqualToRect(self.keyboardFrame, oldKBFrame) &&
      self.keyboardShowing &&
      self.textFieldView &&
      ![self.textFieldView neIsAlertViewTextField]) {
    [self optimizedAdjustPosition];
  }

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** keyboardWillShow: ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)keyboardDidShow:(NSNotification *)notification {
  (void)notification;
  UIViewController *parentController = [self.textFieldView neParentContainerViewController];
  if (![self privateIsEnabled] ||
      !self.textFieldView ||
      !parentController ||
      !((parentController.modalPresentationStyle == UIModalPresentationFormSheet) ||
        (parentController.modalPresentationStyle == UIModalPresentationPageSheet)) ||
      [self.textFieldView neIsAlertViewTextField]) {
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** keyboardDidShow: started ******" indentation:1];
  [self optimizedAdjustPosition];
  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** keyboardDidShow: ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  if (notification) {
    self.keyboardShowNotification = nil;
  }
  self.keyboardShowing = NO;

  NSDictionary *info = notification.userInfo;
  if (info) {
    NSNumber *curve = info[UIKeyboardAnimationCurveUserInfoKey];
    if (curve) {
      self.animationCurve = (UIViewAnimationOptions)curve.unsignedIntegerValue | UIViewAnimationOptionBeginFromCurrentState;
    } else {
      self.animationCurve = UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState;
    }
    NSNumber *duration = info[UIKeyboardAnimationDurationUserInfoKey];
    self.animationDuration = duration ? duration.doubleValue : 0.25;
  }

  if (![self privateIsEnabled]) {
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** keyboardWillHide: started ******" indentation:1];

  if (self.lastScrollView) {
    UIScrollView *lastScrollView = self.lastScrollView;
    [UIView animateWithDuration:self.animationDuration
                          delay:0
                        options:self.animationCurve
                     animations:^{
      if (!UIEdgeInsetsEqualToEdgeInsets(lastScrollView.contentInset, self.startingContentInsets)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentInset to: %@", NSStringFromUIEdgeInsets(self.startingContentInsets)]];
        lastScrollView.contentInset = self.startingContentInsets;
        lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets;
      }

      if (lastScrollView.neShouldRestoreScrollViewContentOffset &&
          !CGPointEqualToPoint(lastScrollView.contentOffset, self.startingContentOffset)) {
        [self showLog:[NSString stringWithFormat:@"Restoring contentOffset to: %@", NSStringFromCGPoint(self.startingContentOffset)]];
        BOOL animatedContentOffset = [self.textFieldView neSuperviewOfClassType:UIStackView.class belowView:lastScrollView] != nil;
        if (animatedContentOffset) {
          [lastScrollView setContentOffset:self.startingContentOffset animated:UIView.areAnimationsEnabled];
        } else {
          lastScrollView.contentOffset = self.startingContentOffset;
        }
      }

      UIScrollView *superScrollView = lastScrollView;
      while (superScrollView) {
        CGSize contentSize = CGSizeMake(MAX(superScrollView.contentSize.width, CGRectGetWidth(superScrollView.frame)),
                                        MAX(superScrollView.contentSize.height, CGRectGetHeight(superScrollView.frame)));
        CGFloat minimumY = contentSize.height - CGRectGetHeight(superScrollView.frame);
        if (minimumY < superScrollView.contentOffset.y) {
          CGPoint newContentOffset = CGPointMake(superScrollView.contentOffset.x, minimumY);
          if (!CGPointEqualToPoint(superScrollView.contentOffset, newContentOffset)) {
            BOOL animatedContentOffset = [self.textFieldView neSuperviewOfClassType:UIStackView.class belowView:superScrollView] != nil;
            if (animatedContentOffset) {
              [superScrollView setContentOffset:newContentOffset animated:UIView.areAnimationsEnabled];
            } else {
              superScrollView.contentOffset = newContentOffset;
            }
            [self showLog:[NSString stringWithFormat:@"Restoring contentOffset to: %@", NSStringFromCGPoint(self.startingContentOffset)]];
          }
        }
        superScrollView = (UIScrollView *)[superScrollView neSuperviewOfClassType:UIScrollView.class];
      }
    } completion:nil];
  }

  [self restorePosition];
  self.lastScrollView = nil;
  self.keyboardFrame = CGRectZero;
  self.startingContentInsets = UIEdgeInsetsZero;
  self.startingScrollIndicatorInsets = UIEdgeInsetsZero;
  self.startingContentOffset = CGPointZero;

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** keyboardWillHide: ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)keyboardDidHide:(NSNotification *)notification {
  (void)notification;
  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** keyboardDidHide: started ******" indentation:1];

  self.topViewBeginOrigin = NEKeyboardManagerCGPointInvalidValue();
  self.keyboardFrame = CGRectZero;

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** keyboardDidHide: ended: %f seconds ******", elapsedTime] indentation:-1];
}

@end
