// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEGrowingTextViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class NEInternalTextView;

@interface NEGrowingTextView : UIView

@property (nonatomic, weak, nullable) id<NEGrowingTextViewDelegate> delegate;
@property (nonatomic, strong, readonly) UITextView *internalTextView;

@property (nonatomic, assign) NSInteger maxNumberOfLines;
@property (nonatomic, assign) NSInteger minNumberOfLines;
@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign, getter=isGrowingAnimationEnabled) BOOL growingAnimationEnabled;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign, getter=isPlaceholderEnabled) BOOL placeholderEnabled;
@property (nonatomic, copy, nullable) NSAttributedString *placeholder;
@property (nonatomic, assign, getter=isCaretHidden) BOOL caretHidden;

@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *textColor;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign) NSRange selectedRange;
@property (nonatomic, assign) UIDataDetectorTypes dataDetectorTypes;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) BOOL enablesReturnKeyAutomatically;
@property (nonatomic, assign, readonly) BOOL hasText;

- (void)scrollRangeToVisible:(NSRange)range;
- (CGFloat)calculateHeight;
- (void)updateHeight;

@end

NS_ASSUME_NONNULL_END
