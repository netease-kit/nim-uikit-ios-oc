// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager+Toolbar.h"
#import "NEToolbar/NEBarButtonItem.h"
#import "NEToolbar/NEInvocation.h"
#import "NEToolbar/NEToolbar.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "NEKeyboardManagerConstantsInternal.h"
#import "Categories/NEUIView+Hierarchy.h"
#import "NEToolbar/NEUIView+NEKeyboardToolbar.h"

static UIView *NEInputAccessoryViewForResponder(UIView *view) {
  if ([view isKindOfClass:[UITextField class]]) {
    return ((UITextField *)view).inputAccessoryView;
  }
  if ([view isKindOfClass:[UITextView class]]) {
    return ((UITextView *)view).inputAccessoryView;
  }
  return nil;
}

static void NESetInputAccessoryViewForResponder(UIView *view, UIView *accessoryView) {
  if ([view isKindOfClass:[UITextField class]]) {
    ((UITextField *)view).inputAccessoryView = accessoryView;
  } else if ([view isKindOfClass:[UITextView class]]) {
    ((UITextView *)view).inputAccessoryView = accessoryView;
  }
}

static UIKeyboardAppearance NEKeyboardAppearanceForResponder(UIView *view) {
  if ([view isKindOfClass:[UITextField class]]) {
    return ((UITextField *)view).keyboardAppearance;
  }
  if ([view isKindOfClass:[UITextView class]]) {
    return ((UITextView *)view).keyboardAppearance;
  }
  return UIKeyboardAppearanceDefault;
}

@implementation NEKeyboardManager (Toolbar)

- (void)addToolbarIfRequired {
  NSArray<UIView *> *siblings = [self responderViews];
  UIView *textField = self.textFieldView;
  UIView *accessoryView = NEInputAccessoryViewForResponder(textField);
  if (siblings.count == 0 ||
      !textField ||
      (![textField isKindOfClass:[UITextField class]] &&
       ![textField isKindOfClass:[UITextView class]])) {
    return;
  }
  if (accessoryView &&
      accessoryView.tag != kNEPreviousNextButtonToolbarTag &&
      accessoryView.tag != kNEDoneButtonToolbarTag) {
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** addToolbarIfRequired started ******" indentation:1];
  [self showLog:[NSString stringWithFormat:@"Found %lu responder sibling(s)", (unsigned long)siblings.count]];

  NEBarButtonItemConfiguration *rightConfiguration = nil;
  if (self.toolbarDoneBarButtonItemImage) {
    rightConfiguration = [[NEBarButtonItemConfiguration alloc] initWithImage:self.toolbarDoneBarButtonItemImage action:@selector(doneAction:)];
  } else if (self.toolbarDoneBarButtonItemText.length > 0) {
    rightConfiguration = [[NEBarButtonItemConfiguration alloc] initWithTitle:self.toolbarDoneBarButtonItemText action:@selector(doneAction:)];
  } else {
    rightConfiguration = [[NEBarButtonItemConfiguration alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone action:@selector(doneAction:)];
  }
  rightConfiguration.accessibilityLabel = self.toolbarDoneBarButtonItemAccessibilityLabel ?: @"Done";

  if ((siblings.count <= 1 && self.previousNextDisplayMode == NEPreviousNextDisplayModeDefault) ||
      self.previousNextDisplayMode == NEPreviousNextDisplayModeAlwaysHide) {
    [textField neAddKeyboardToolbarWithTarget:self
                                    titleText:self.shouldShowToolbarPlaceholder ? textField.neDrawingToolbarPlaceholder : nil
                  rightBarButtonConfiguration:rightConfiguration
               previousBarButtonConfiguration:nil
                   nextBarButtonConfiguration:nil];
    NEInputAccessoryViewForResponder(textField).tag = kNEDoneButtonToolbarTag;
  } else {
    NEBarButtonItemConfiguration *previousConfiguration = nil;
    if (self.toolbarPreviousBarButtonItemImage) {
      previousConfiguration = [[NEBarButtonItemConfiguration alloc] initWithImage:self.toolbarPreviousBarButtonItemImage action:@selector(previousAction:)];
    } else if (self.toolbarPreviousBarButtonItemText.length > 0) {
      previousConfiguration = [[NEBarButtonItemConfiguration alloc] initWithTitle:self.toolbarPreviousBarButtonItemText action:@selector(previousAction:)];
    } else {
      previousConfiguration = [[NEBarButtonItemConfiguration alloc] initWithImage:[UIImage neKeyboardPreviousImage] ?: [[UIImage alloc] init] action:@selector(previousAction:)];
    }
    previousConfiguration.accessibilityLabel = self.toolbarPreviousBarButtonItemAccessibilityLabel ?: @"Previous";

    NEBarButtonItemConfiguration *nextConfiguration = nil;
    if (self.toolbarNextBarButtonItemImage) {
      nextConfiguration = [[NEBarButtonItemConfiguration alloc] initWithImage:self.toolbarNextBarButtonItemImage action:@selector(nextAction:)];
    } else if (self.toolbarNextBarButtonItemText.length > 0) {
      nextConfiguration = [[NEBarButtonItemConfiguration alloc] initWithTitle:self.toolbarNextBarButtonItemText action:@selector(nextAction:)];
    } else {
      nextConfiguration = [[NEBarButtonItemConfiguration alloc] initWithImage:[UIImage neKeyboardNextImage] ?: [[UIImage alloc] init] action:@selector(nextAction:)];
    }
    nextConfiguration.accessibilityLabel = self.toolbarNextBarButtonItemAccessibilityLabel ?: @"Next";

    [textField neAddKeyboardToolbarWithTarget:self
                                    titleText:self.shouldShowToolbarPlaceholder ? textField.neDrawingToolbarPlaceholder : nil
                  rightBarButtonConfiguration:rightConfiguration
               previousBarButtonConfiguration:previousConfiguration
                   nextBarButtonConfiguration:nextConfiguration];
    NEInputAccessoryViewForResponder(textField).tag = kNEPreviousNextButtonToolbarTag;
  }

  NEToolbar *toolbar = textField.neKeyboardToolbar;
  toolbar.tintColor = self.shouldToolbarUsesTextFieldTintColor ? textField.tintColor : self.toolbarTintColor;
  if (NEKeyboardAppearanceForResponder(textField) == UIKeyboardAppearanceDark) {
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.barTintColor = nil;
  } else {
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.barTintColor = self.toolbarBarTintColor;
  }

  if (self.shouldShowToolbarPlaceholder && !textField.neShouldHideToolbarPlaceholder) {
    if (!toolbar.titleBarButton.title || ![toolbar.titleBarButton.title isEqualToString:textField.neDrawingToolbarPlaceholder]) {
      toolbar.titleBarButton.title = textField.neDrawingToolbarPlaceholder;
    }
    toolbar.titleBarButton.titleFont = self.placeholderFont;
    toolbar.titleBarButton.titleColor = self.placeholderColor;
    toolbar.titleBarButton.selectableTitleColor = self.placeholderButtonColor;
  } else {
    toolbar.titleBarButton.title = nil;
  }

  toolbar.previousBarButton.enabled = siblings.firstObject != textField;
  toolbar.nextBarButton.enabled = siblings.lastObject != textField;

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** addToolbarIfRequired ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)removeToolbarIfRequired {
  NSArray<UIView *> *siblings = [self responderViews];
  UIView *textField = self.textFieldView;
  UIView *accessoryView = NEInputAccessoryViewForResponder(textField);
  if (siblings.count == 0 || !textField) {
    return;
  }
  if (accessoryView &&
      accessoryView.tag != kNEPreviousNextButtonToolbarTag &&
      accessoryView.tag != kNEDoneButtonToolbarTag) {
    return;
  }

  CFTimeInterval startTime = CACurrentMediaTime();
  [self showLog:@"****** removeToolbarIfRequired started ******" indentation:1];
  [self showLog:[NSString stringWithFormat:@"Found %lu responder sibling(s)", (unsigned long)siblings.count]];

  for (UIView *view in siblings) {
    UIView *inputAccessoryView = NEInputAccessoryViewForResponder(view);
    if (![inputAccessoryView isKindOfClass:[NEToolbar class]]) {
      continue;
    }
    if (inputAccessoryView.tag == kNEDoneButtonToolbarTag ||
        inputAccessoryView.tag == kNEPreviousNextButtonToolbarTag) {
      NESetInputAccessoryViewForResponder(view, nil);
      [view reloadInputViews];
    }
  }

  CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
  [self showLog:[NSString stringWithFormat:@"****** removeToolbarIfRequired ended: %f seconds ******", elapsedTime] indentation:-1];
}

- (void)reloadInputViews {
  if ([self privateIsEnableAutoToolbar]) {
    [self addToolbarIfRequired];
  } else {
    [self removeToolbarIfRequired];
  }
}

- (BOOL)canGoPrevious {
  NSArray<UIView *> *textFields = [self responderViews];
  UIView *textFieldRetain = self.textFieldView;
  NSUInteger index = [textFields indexOfObject:textFieldRetain];
  return textFieldRetain && index != NSNotFound && index > 0;
}

- (BOOL)canGoNext {
  NSArray<UIView *> *textFields = [self responderViews];
  UIView *textFieldRetain = self.textFieldView;
  NSUInteger index = [textFields indexOfObject:textFieldRetain];
  return textFieldRetain && index != NSNotFound && index < textFields.count - 1;
}

- (BOOL)goPrevious {
  NSArray<UIView *> *textFields = [self responderViews];
  UIView *textFieldRetain = self.textFieldView;
  NSUInteger index = [textFields indexOfObject:textFieldRetain];
  if (!textFieldRetain || index == NSNotFound || index == 0) {
    return NO;
  }

  UIView *previousTextField = textFields[index - 1];
  BOOL accepted = [previousTextField becomeFirstResponder];
  if (!accepted) {
    [textFieldRetain becomeFirstResponder];
    [self showLog:[NSString stringWithFormat:@"Refuses to become first responder: %@", previousTextField]];
  }
  return accepted;
}

- (BOOL)goNext {
  NSArray<UIView *> *textFields = [self responderViews];
  UIView *textFieldRetain = self.textFieldView;
  NSUInteger index = [textFields indexOfObject:textFieldRetain];
  if (!textFieldRetain || index == NSNotFound || index >= textFields.count - 1) {
    return NO;
  }

  UIView *nextTextField = textFields[index + 1];
  BOOL accepted = [nextTextField becomeFirstResponder];
  if (!accepted) {
    [textFieldRetain becomeFirstResponder];
    [self showLog:[NSString stringWithFormat:@"Refuses to become first responder: %@", nextTextField]];
  }
  return accepted;
}

- (void)previousAction:(NEBarButtonItem *)barButton {
  if (self.shouldPlayInputClicks && [[UIDevice currentDevice] respondsToSelector:@selector(playInputClick)]) {
    [[UIDevice currentDevice] playInputClick];
  }

  if (![self canGoPrevious] || !self.textFieldView) {
    return;
  }

  UIView *textFieldRetain = self.textFieldView;
  BOOL accepted = [self goPrevious];
  NEInvocation *invocation = barButton.invocation;
  UIView *sender = textFieldRetain;
  UISearchBar *searchBar = [textFieldRetain neTextFieldSearchBar];
  if (searchBar) {
    invocation = searchBar.neKeyboardToolbar.previousBarButton.invocation;
    sender = searchBar;
  }
  if (accepted) {
    [invocation invokeFrom:sender];
  }
}

- (void)nextAction:(NEBarButtonItem *)barButton {
  if (self.shouldPlayInputClicks && [[UIDevice currentDevice] respondsToSelector:@selector(playInputClick)]) {
    [[UIDevice currentDevice] playInputClick];
  }

  if (![self canGoNext] || !self.textFieldView) {
    return;
  }

  UIView *textFieldRetain = self.textFieldView;
  BOOL accepted = [self goNext];
  NEInvocation *invocation = barButton.invocation;
  UIView *sender = textFieldRetain;
  UISearchBar *searchBar = [textFieldRetain neTextFieldSearchBar];
  if (searchBar) {
    invocation = searchBar.neKeyboardToolbar.nextBarButton.invocation;
    sender = searchBar;
  }
  if (accepted) {
    [invocation invokeFrom:sender];
  }
}

- (void)doneAction:(NEBarButtonItem *)barButton {
  if (self.shouldPlayInputClicks && [[UIDevice currentDevice] respondsToSelector:@selector(playInputClick)]) {
    [[UIDevice currentDevice] playInputClick];
  }

  if (!self.textFieldView) {
    return;
  }

  UIView *textFieldRetain = self.textFieldView;
  BOOL resigned = [self resignFirstResponder];
  NEInvocation *invocation = barButton.invocation;
  UIView *sender = textFieldRetain;
  UISearchBar *searchBar = [textFieldRetain neTextFieldSearchBar];
  if (searchBar) {
    invocation = searchBar.neKeyboardToolbar.doneBarButton.invocation;
    sender = searchBar;
  }
  if (resigned) {
    [invocation invokeFrom:sender];
  }
}

@end
