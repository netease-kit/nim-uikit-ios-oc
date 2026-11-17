// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"
#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Internal.h"
#import "NEKeyboardManager+Position.h"
#import "NEKeyboardManager+Toolbar.h"
#import "NEKeyboardManager+UIKeyboardNotification.h"
#import "NEKeyboardManager+UITextFieldViewNotification.h"
#import "NEToolbar/NEPreviousNextView.h"
#import "NEToolbar/NEUIView+NEKeyboardToolbar.h"
#import "Categories/NEUIView+Hierarchy.h"

@interface NEKeyboardManager () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UITapGestureRecognizer *resignFirstResponderGesture;

@end

@implementation NEKeyboardManager

+ (NEKeyboardManager *)shared {
  static NEKeyboardManager *manager;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    manager = [[NEKeyboardManager alloc] init];
  });
  return manager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _enable = NO;
    _keyboardDistanceFromTextField = 10.0;
    _enableAutoToolbar = YES;
    _shouldToolbarUsesTextFieldTintColor = NO;
    _previousNextDisplayMode = NEPreviousNextDisplayModeDefault;
    _shouldShowToolbarPlaceholder = YES;
    _overrideKeyboardAppearance = NO;
    _keyboardAppearance = UIKeyboardAppearanceDefault;
    _shouldResignOnTouchOutside = NO;
    _shouldPlayInputClicks = YES;
    _layoutIfNeededOnUpdate = NO;
    _disabledDistanceHandlingClasses = [NSMutableArray array];
    _enabledDistanceHandlingClasses = [NSMutableArray array];
    _disabledToolbarClasses = [NSMutableArray array];
    _enabledToolbarClasses = [NSMutableArray array];
    _toolbarPreviousNextAllowedClasses = [NSMutableArray array];
    _disabledTouchResignedClasses = [NSMutableArray array];
    _enabledTouchResignedClasses = [NSMutableArray array];
    _touchResignedGestureIgnoreClasses = [NSMutableArray array];
    _toolbarManageBehaviour = NEAutoToolbarManageBehaviourBySubviews;
    _resignFirstResponderGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    _resignFirstResponderGesture.cancelsTouchesInView = NO;
    _resignFirstResponderGesture.delegate = self;
    _resignFirstResponderGesture.enabled = _shouldResignOnTouchOutside;

    [self registerAllNotifications];

    UITextField *textField = [[UITextField alloc] init];
    [textField neAddDoneOnKeyboardWithTarget:nil action:@selector(doneAction:)];
    [textField neAddPreviousNextDoneOnKeyboardWithTarget:nil
                                          previousAction:@selector(previousAction:)
                                              nextAction:@selector(nextAction:)
                                              doneAction:@selector(doneAction:)];

    [self.disabledDistanceHandlingClasses addObject:UITableViewController.class];
    [self.disabledDistanceHandlingClasses addObject:UIAlertController.class];
    [self.disabledToolbarClasses addObject:UIAlertController.class];
    [self.disabledTouchResignedClasses addObject:UIAlertController.class];
    [self.toolbarPreviousNextAllowedClasses addObject:UITableView.class];
    [self.toolbarPreviousNextAllowedClasses addObject:UICollectionView.class];
    [self.toolbarPreviousNextAllowedClasses addObject:NEPreviousNextView.class];
    [self.touchResignedGestureIgnoreClasses addObject:UIControl.class];
    [self.touchResignedGestureIgnoreClasses addObject:UINavigationBar.class];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAllNotifications];
}

- (void)setEnable:(BOOL)enable {
  BOOL oldValue = _enable;
  _enable = enable;
  if (enable && !oldValue) {
    if (self.keyboardShowNotification) {
      [self keyboardWillShow:self.keyboardShowNotification];
    }
    [self showLog:@"Enabled"];
  } else if (!enable && oldValue) {
    [self keyboardWillHide:nil];
    [self showLog:@"Disabled"];
  }
}

- (void)setEnableAutoToolbar:(BOOL)enableAutoToolbar {
  _enableAutoToolbar = enableAutoToolbar;
  if ([self privateIsEnableAutoToolbar]) {
    [self addToolbarIfRequired];
  } else {
    [self removeToolbarIfRequired];
  }
  [self showLog:[NSString stringWithFormat:@"enableAutoToolbar: %@", enableAutoToolbar ? @"Yes" : @"NO"]];
}

- (void)setShouldResignOnTouchOutside:(BOOL)shouldResignOnTouchOutside {
  _shouldResignOnTouchOutside = shouldResignOnTouchOutside;
  self.resignFirstResponderGesture.enabled = [self privateShouldResignOnTouchOutside];
  [self showLog:[NSString stringWithFormat:@"shouldResignOnTouchOutside: %@", shouldResignOnTouchOutside ? @"Yes" : @"NO"]];
}

- (BOOL)resignFirstResponder {
  UIView *textFieldRetain = self.textFieldView;
  if (!textFieldRetain) {
    return NO;
  }

  BOOL resigned = [textFieldRetain resignFirstResponder];
  if (!resigned) {
    [self showLog:[NSString stringWithFormat:@"Refuses to resign first responder: %@", textFieldRetain]];
    [textFieldRetain becomeFirstResponder];
    return NO;
  }
  return YES;
}

- (void)registerTextFieldViewClass:(Class)aClass
    didBeginEditingNotificationName:(NSString *)didBeginEditingNotificationName
      didEndEditingNotificationName:(NSString *)didEndEditingNotificationName {
  (void)aClass;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldViewDidBeginEditing:)
                                               name:didBeginEditingNotificationName
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldViewDidEndEditing:)
                                               name:didEndEditingNotificationName
                                             object:nil];
}

- (void)unregisterTextFieldViewClass:(Class)aClass
      didBeginEditingNotificationName:(NSString *)didBeginEditingNotificationName
        didEndEditingNotificationName:(NSString *)didEndEditingNotificationName {
  (void)aClass;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:didBeginEditingNotificationName object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:didEndEditingNotificationName object:nil];
}

- (void)reloadLayoutIfNeeded {
  if (![self privateIsEnabled] ||
      !self.keyboardShowing ||
      CGPointEqualToPoint(self.topViewBeginOrigin, NEKeyboardManagerCGPointInvalidValue()) ||
      !self.textFieldView ||
      [self.textFieldView neIsAlertViewTextField]) {
    return;
  }
  [self optimizedAdjustPosition];
}

- (void)tapRecognized:(UITapGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateEnded) {
    [self resignFirstResponder];
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  (void)gestureRecognizer;
  (void)otherGestureRecognizer;
  return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  (void)gestureRecognizer;
  for (Class ignoreClass in self.touchResignedGestureIgnoreClasses) {
    if ([touch.view isKindOfClass:ignoreClass]) {
      return NO;
    }
  }
  return YES;
}

@end
