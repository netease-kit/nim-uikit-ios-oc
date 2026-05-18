// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager (UITextFieldViewNotification)

@property (nonatomic, weak, nullable) UIView *textFieldView;
@property (nonatomic, assign) CGPoint topViewBeginOrigin;
@property (nonatomic, weak, nullable) UIViewController *rootViewController;
@property (nonatomic, weak, nullable) UIViewController *rootViewControllerWhilePopGestureRecognizerActive;
@property (nonatomic, assign) CGPoint topViewBeginOriginWhilePopGestureRecognizerActive;

- (void)textFieldViewDidBeginEditing:(NSNotification *)notification;
- (void)textFieldViewDidEndEditing:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
