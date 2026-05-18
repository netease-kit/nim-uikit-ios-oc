// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager (UIKeyboardNotification)

@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, strong, nullable) NSNotification *keyboardShowNotification;
@property (nonatomic, assign) CGRect keyboardFrame;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) UIViewAnimationOptions animationCurve;

- (void)keyboardWillShow:(nullable NSNotification *)notification;
- (void)keyboardDidShow:(nullable NSNotification *)notification;
- (void)keyboardWillHide:(nullable NSNotification *)notification;
- (void)keyboardDidHide:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
