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

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0));
- (BOOL)textView:(UITextView *)textView
    shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
                              inRange:(NSRange)characterRange
                          interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0));
- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange API_DEPRECATED("Use textView:shouldInteractWithURL:inRange:interaction:", ios(7.0, 10.0));
- (BOOL)textView:(UITextView *)textView
    shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
                              inRange:(NSRange)characterRange API_DEPRECATED("Use textView:shouldInteractWithTextAttachment:inRange:interaction:", ios(7.0, 10.0));

@end

NS_ASSUME_NONNULL_END
