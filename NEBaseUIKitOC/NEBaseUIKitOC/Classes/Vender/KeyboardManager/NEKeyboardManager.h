// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEKeyboardManagerConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager : NSObject

@property (class, nonatomic, strong, readonly) NEKeyboardManager *shared;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, assign) CGFloat keyboardDistanceFromTextField;
@property (nonatomic, assign) BOOL enableAutoToolbar;
@property (nonatomic, assign) BOOL shouldResignOnTouchOutside;
@property (nonatomic, assign) BOOL shouldToolbarUsesTextFieldTintColor;
@property (nonatomic, strong, nullable) UIColor *toolbarTintColor;
@property (nonatomic, strong, nullable) UIColor *toolbarBarTintColor;
@property (nonatomic, assign) NEAutoToolbarManageBehaviour toolbarManageBehaviour;
@property (nonatomic, assign) NEPreviousNextDisplayMode previousNextDisplayMode;
@property (nonatomic, strong, nullable) UIImage *toolbarPreviousBarButtonItemImage;
@property (nonatomic, strong, nullable) UIImage *toolbarNextBarButtonItemImage;
@property (nonatomic, strong, nullable) UIImage *toolbarDoneBarButtonItemImage;
@property (nonatomic, copy, nullable) NSString *toolbarPreviousBarButtonItemText;
@property (nonatomic, copy, nullable) NSString *toolbarPreviousBarButtonItemAccessibilityLabel;
@property (nonatomic, copy, nullable) NSString *toolbarNextBarButtonItemText;
@property (nonatomic, copy, nullable) NSString *toolbarNextBarButtonItemAccessibilityLabel;
@property (nonatomic, copy, nullable) NSString *toolbarDoneBarButtonItemText;
@property (nonatomic, copy, nullable) NSString *toolbarDoneBarButtonItemAccessibilityLabel;
@property (nonatomic, assign) BOOL shouldShowToolbarPlaceholder;
@property (nonatomic, strong, nullable) UIFont *placeholderFont;
@property (nonatomic, strong, nullable) UIColor *placeholderColor;
@property (nonatomic, strong, nullable) UIColor *placeholderButtonColor;
@property (nonatomic, assign) BOOL overrideKeyboardAppearance;
@property (nonatomic, assign) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *resignFirstResponderGesture;
@property (nonatomic, assign) BOOL shouldPlayInputClicks;
@property (nonatomic, assign) BOOL layoutIfNeededOnUpdate;
@property (nonatomic, strong) NSMutableArray<Class> *disabledDistanceHandlingClasses;
@property (nonatomic, strong) NSMutableArray<Class> *enabledDistanceHandlingClasses;
@property (nonatomic, strong) NSMutableArray<Class> *disabledToolbarClasses;
@property (nonatomic, strong) NSMutableArray<Class> *enabledToolbarClasses;
@property (nonatomic, strong) NSMutableArray<Class> *toolbarPreviousNextAllowedClasses;
@property (nonatomic, strong) NSMutableArray<Class> *disabledTouchResignedClasses;
@property (nonatomic, strong) NSMutableArray<Class> *enabledTouchResignedClasses;
@property (nonatomic, strong) NSMutableArray<Class> *touchResignedGestureIgnoreClasses;
@property (nonatomic, assign, readonly) BOOL keyboardShowing;
@property (nonatomic, assign, readonly) CGFloat movedDistance;
@property (nonatomic, copy, nullable) void (^movedDistanceChanged)(CGFloat movedDistance);
- (BOOL)resignFirstResponder;
- (void)reloadLayoutIfNeeded;
- (void)registerTextFieldViewClass:(Class)aClass
    didBeginEditingNotificationName:(NSString *)didBeginEditingNotificationName
      didEndEditingNotificationName:(NSString *)didEndEditingNotificationName;
- (void)unregisterTextFieldViewClass:(Class)aClass
      didBeginEditingNotificationName:(NSString *)didBeginEditingNotificationName
        didEndEditingNotificationName:(NSString *)didEndEditingNotificationName;
@end

NS_ASSUME_NONNULL_END

#import "NEKeyboardManager+Debug.h"
#import "NEKeyboardManager+Toolbar.h"
