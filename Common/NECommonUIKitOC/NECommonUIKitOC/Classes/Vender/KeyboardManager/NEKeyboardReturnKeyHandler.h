// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardReturnKeyHandler : NSObject <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak, nullable) id<UITextFieldDelegate, UITextViewDelegate> delegate;
@property (nonatomic, assign) UIReturnKeyType lastTextFieldReturnKeyType;

- (instancetype)initWithController:(UIViewController *)controller;
- (void)addTextFieldView:(UIView *)view;
- (void)removeTextFieldView:(UIView *)view;
- (void)addResponderFromView:(UIView *)view;
- (void)removeResponderFromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
