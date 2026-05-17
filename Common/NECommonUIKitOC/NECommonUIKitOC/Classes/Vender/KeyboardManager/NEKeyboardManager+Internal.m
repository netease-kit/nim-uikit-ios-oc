// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "Categories/NENSArray+Sort.h"
#import "Categories/NEUITextFieldView+Additions.h"
#import "Categories/NEUIView+Hierarchy.h"

@implementation NEWeakObjectContainer

- (instancetype)initWithObject:(id)object {
  self = [super init];
  if (self) {
    _object = object;
  }
  return self;
}

@end

@implementation NEKeyboardManager (Internal)

- (NSArray<UIView *> *)responderViews {
  UIView *superConsideredView = nil;
  for (Class disabledClass in self.toolbarPreviousNextAllowedClasses) {
    superConsideredView = [self.textFieldView neSuperviewOfClassType:disabledClass];
    if (superConsideredView) {
      break;
    }
  }

  if (superConsideredView) {
    return [superConsideredView neDeepResponderViews];
  }

  NSArray<UIView *> *textFields = [self.textFieldView neResponderSiblings];
  switch (self.toolbarManageBehaviour) {
    case NEAutoToolbarManageBehaviourByTag:
      return [textFields neSortedArrayByTag];
    case NEAutoToolbarManageBehaviourByPosition:
      return [textFields neSortedArrayByPosition];
    case NEAutoToolbarManageBehaviourBySubviews:
    default:
      return textFields;
  }
}

- (BOOL)privateIsEnabled {
  BOOL isEnabled = self.enable;
  NEEnableMode enableMode = self.textFieldView.neEnableMode;
  if (enableMode == NEEnableModeEnabled) {
    isEnabled = YES;
  } else if (enableMode == NEEnableModeDisabled) {
    isEnabled = NO;
  } else {
    UIViewController *textFieldViewController = [self.textFieldView neViewContainingController];
    if ([self.textFieldView neTextFieldSearchBar] &&
        [textFieldViewController isKindOfClass:[UINavigationController class]] &&
        ((UINavigationController *)textFieldViewController).topViewController) {
      textFieldViewController = ((UINavigationController *)textFieldViewController).topViewController;
    }

    if (!isEnabled) {
      for (Class clazz in self.enabledDistanceHandlingClasses) {
        if ([textFieldViewController isKindOfClass:clazz]) {
          isEnabled = YES;
          break;
        }
      }
    }

    if (isEnabled) {
      for (Class clazz in self.disabledDistanceHandlingClasses) {
        if ([textFieldViewController isKindOfClass:clazz]) {
          isEnabled = NO;
          break;
        }
      }

      if (isEnabled) {
        NSString *classNameString = NSStringFromClass(textFieldViewController.class);
        if ([classNameString containsString:@"UIAlertController"] &&
            [classNameString hasSuffix:@"TextFieldViewController"]) {
          isEnabled = NO;
        }
      }
    }
  }
  return isEnabled;
}

- (BOOL)privateIsEnableAutoToolbar {
  UIViewController *textFieldViewController = [self.textFieldView neViewContainingController];
  if (!textFieldViewController) {
    return self.enableAutoToolbar;
  }

  if ([self.textFieldView neTextFieldSearchBar] &&
      [textFieldViewController isKindOfClass:[UINavigationController class]] &&
      ((UINavigationController *)textFieldViewController).topViewController) {
    textFieldViewController = ((UINavigationController *)textFieldViewController).topViewController;
  }

  BOOL enableToolbar = self.enableAutoToolbar;
  if (!enableToolbar) {
    for (Class clazz in self.enabledToolbarClasses) {
      if ([textFieldViewController isKindOfClass:clazz]) {
        enableToolbar = YES;
        break;
      }
    }
  }

  if (enableToolbar) {
    for (Class clazz in self.disabledToolbarClasses) {
      if ([textFieldViewController isKindOfClass:clazz]) {
        enableToolbar = NO;
        break;
      }
    }

    if (enableToolbar) {
      NSString *classNameString = NSStringFromClass(textFieldViewController.class);
      if ([classNameString containsString:@"UIAlertController"] &&
          [classNameString hasSuffix:@"TextFieldViewController"]) {
        enableToolbar = NO;
      }
    }
  }
  return enableToolbar;
}

- (BOOL)privateShouldResignOnTouchOutside {
  BOOL shouldResign = self.shouldResignOnTouchOutside;
  NEEnableMode enableMode = self.textFieldView.neShouldResignOnTouchOutsideMode;
  if (enableMode == NEEnableModeEnabled) {
    shouldResign = YES;
  } else if (enableMode == NEEnableModeDisabled) {
    shouldResign = NO;
  } else {
    UIViewController *textFieldViewController = [self.textFieldView neViewContainingController];
    if ([self.textFieldView neTextFieldSearchBar] &&
        [textFieldViewController isKindOfClass:[UINavigationController class]] &&
        ((UINavigationController *)textFieldViewController).topViewController) {
      textFieldViewController = ((UINavigationController *)textFieldViewController).topViewController;
    }

    if (!shouldResign) {
      for (Class clazz in self.enabledTouchResignedClasses) {
        if ([textFieldViewController isKindOfClass:clazz]) {
          shouldResign = YES;
          break;
        }
      }
    }

    if (shouldResign) {
      for (Class clazz in self.disabledTouchResignedClasses) {
        if ([textFieldViewController isKindOfClass:clazz]) {
          shouldResign = NO;
          break;
        }
      }

      if (shouldResign) {
        NSString *classNameString = NSStringFromClass(textFieldViewController.class);
        if ([classNameString containsString:@"UIAlertController"] &&
            [classNameString hasSuffix:@"TextFieldViewController"]) {
          shouldResign = NO;
        }
      }
    }
  }
  return shouldResign;
}

- (UIWindow *)keyWindow {
  if (self.textFieldView.window) {
    return self.textFieldView.window;
  }

  static __weak UIWindow *cachedKeyWindow;
  UIWindow *originalKeyWindow = nil;
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (![scene isKindOfClass:[UIWindowScene class]]) {
        continue;
      }
      for (UIWindow *window in ((UIWindowScene *)scene).windows) {
        if (window.isKeyWindow) {
          originalKeyWindow = window;
          break;
        }
      }
      if (originalKeyWindow) {
        break;
      }
    }
  } else {
    originalKeyWindow = UIApplication.sharedApplication.keyWindow;
  }

  if (originalKeyWindow) {
    cachedKeyWindow = originalKeyWindow;
  }
  return cachedKeyWindow;
}

@end
