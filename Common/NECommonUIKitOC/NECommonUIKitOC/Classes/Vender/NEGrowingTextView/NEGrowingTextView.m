// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEGrowingTextView.h"
#import "NEInternalTextView.h"

@interface NEGrowingTextView () <UITextViewDelegate>

@property (nonatomic, strong) NEInternalTextView *textView;

@end

@implementation NEGrowingTextView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  _animationDuration = 0.1;
  _growingAnimationEnabled = YES;
  _contentInset = UIEdgeInsetsMake(8.0, 5.0, 8.0, 5.0);
  _placeholderEnabled = YES;
  _scrollEnabled = NO;
  _textView = [[NEInternalTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
  _textView.delegate = self;
  _textView.textContainerInset = UIEdgeInsetsZero;
  _textView.textContainer.lineFragmentPadding = 1.0;
  _textView.showsHorizontalScrollIndicator = NO;
  _textView.contentInset = UIEdgeInsetsZero;
  _textView.contentMode = UIViewContentModeRedraw;
  _textView.backgroundColor = self.backgroundColor;
  _minNumberOfLines = 1;
  [self addSubview:_textView];
}

- (UITextView *)internalTextView {
  return self.textView;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  self.textView.backgroundColor = backgroundColor;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  _contentInset = contentInset;
  [self updateTextViewFrame];
  [self updateMaxHeight];
  [self updateMinHeight];
}

- (void)setMaxNumberOfLines:(NSInteger)maxNumberOfLines {
  _maxNumberOfLines = maxNumberOfLines;
  [self updateMaxHeight];
}

- (void)setMinNumberOfLines:(NSInteger)minNumberOfLines {
  _minNumberOfLines = minNumberOfLines;
  [self updateMinHeight];
}

- (void)setMaxHeight:(CGFloat)maxHeight {
  _maxHeight = maxHeight;
  [self updateHeight];
}

- (void)setMinHeight:(CGFloat)minHeight {
  _minHeight = minHeight;
  [self updateHeight];
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
  _scrollEnabled = scrollEnabled;
  self.textView.scrollEnabled = scrollEnabled;
}

- (void)setPlaceholderEnabled:(BOOL)placeholderEnabled {
  _placeholderEnabled = placeholderEnabled;
  self.textView.shouldDisplayPlaceholder = self.textView.text.length == 0 && placeholderEnabled;
}

- (void)setPlaceholder:(NSAttributedString *)placeholder {
  self.textView.placeholder = placeholder;
}

- (NSAttributedString *)placeholder {
  return self.textView.placeholder;
}

- (void)setCaretHidden:(BOOL)caretHidden {
  self.textView.caretHidden = caretHidden;
}

- (BOOL)isCaretHidden {
  return self.textView.isCaretHidden;
}

- (void)setText:(NSString *)text {
  self.textView.text = text;
  [self updateHeight];
}

- (NSString *)text {
  return self.textView.text;
}

- (void)setFont:(UIFont *)font {
  self.textView.font = font;
  [self updateMaxHeight];
  [self updateMinHeight];
}

- (UIFont *)font {
  return self.textView.font;
}

- (void)setTextColor:(UIColor *)textColor {
  self.textView.textColor = textColor;
}

- (UIColor *)textColor {
  return self.textView.textColor;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
  self.textView.textAlignment = textAlignment;
}

- (NSTextAlignment)textAlignment {
  return self.textView.textAlignment;
}

- (void)setEditable:(BOOL)editable {
  self.textView.editable = editable;
}

- (BOOL)isEditable {
  return self.textView.isEditable;
}

- (void)setSelectedRange:(NSRange)selectedRange {
  self.textView.selectedRange = selectedRange;
}

- (NSRange)selectedRange {
  return self.textView.selectedRange;
}

- (void)setDataDetectorTypes:(UIDataDetectorTypes)dataDetectorTypes {
  self.textView.dataDetectorTypes = dataDetectorTypes;
}

- (UIDataDetectorTypes)dataDetectorTypes {
  return self.textView.dataDetectorTypes;
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType {
  self.textView.returnKeyType = returnKeyType;
}

- (UIReturnKeyType)returnKeyType {
  return self.textView.returnKeyType;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType {
  self.textView.keyboardType = keyboardType;
}

- (UIKeyboardType)keyboardType {
  return self.textView.keyboardType;
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enablesReturnKeyAutomatically {
  self.textView.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically;
}

- (BOOL)enablesReturnKeyAutomatically {
  return self.textView.enablesReturnKeyAutomatically;
}

- (BOOL)hasText {
  return self.textView.hasText;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self updateTextViewFrame];
  [self updateMaxHeight];
  [self updateMinHeight];
  [self updateHeight];
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGSize fittingSize = size;
  CGFloat lineFragmentPadding = self.textView.textContainer.lineFragmentPadding;
  CGSize textViewSize = size;
  textViewSize.width -= self.contentInset.left + self.contentInset.right - lineFragmentPadding * 2.0;
  textViewSize.height = CGFLOAT_MAX;
  textViewSize.width = MAX(0, textViewSize.width);
  CGFloat height = ceil([self.textView sizeThatFits:textViewSize].height + self.contentInset.top + self.contentInset.bottom);
  if (self.text.length == 0) {
    height = self.minHeight;
  }
  if (self.maxHeight > 0) {
    height = MIN(height, self.maxHeight);
  }
  fittingSize.height = height;
  return fittingSize;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [self.textView becomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
  [super becomeFirstResponder];
  return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  [super resignFirstResponder];
  return [self.textView resignFirstResponder];
}

- (BOOL)isFirstResponder {
  return self.textView.isFirstResponder;
}

- (void)scrollRangeToVisible:(NSRange)range {
  [self.textView scrollRangeToVisible:range];
}

- (CGFloat)calculateHeight {
  return ceil([self.textView sizeThatFits:self.textView.frame.size].height + self.contentInset.top + self.contentInset.bottom);
}

- (void)updateHeight {
  CGFloat newHeight = 0;
  CGFloat difference = 0;
  [self updatedHeight:&newHeight difference:&difference];

  if (difference != 0) {
    if (self.maxHeight > 0 && fabs(newHeight - self.maxHeight) < 0.5) {
      if (!self.textView.isScrollEnabled) {
        self.textView.scrollEnabled = YES;
        [self.textView flashScrollIndicators];
      }
    } else {
      self.textView.scrollEnabled = self.isScrollEnabled;
    }

    __weak typeof(self) weakSelf = self;
    void (^completionBlock)(void) = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if ([strongSelf.delegate respondsToSelector:@selector(growingTextView:didChangeHeight:difference:)]) {
        [strongSelf.delegate growingTextView:strongSelf didChangeHeight:newHeight difference:difference];
      }
    };

    if (self.isGrowingAnimationEnabled) {
      [UIView animateWithDuration:self.animationDuration
                            delay:0
                          options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                       animations:^{
        [weakSelf updateGrowingTextViewWithNewHeight:newHeight difference:difference];
      } completion:^(__unused BOOL finished) {
        completionBlock();
      }];
    } else {
      [self updateGrowingTextViewWithNewHeight:newHeight difference:difference];
      completionBlock();
    }
  }

  [self updateScrollPositionAnimated:NO];
  self.textView.shouldDisplayPlaceholder = self.textView.text.length == 0 && self.isPlaceholderEnabled;
}

- (void)updateTextViewFrame {
  CGFloat lineFragmentPadding = self.textView.textContainer.lineFragmentPadding;
  CGRect textViewFrame = self.bounds;
  textViewFrame.origin.x = self.contentInset.left - lineFragmentPadding;
  textViewFrame.origin.y = self.contentInset.top;
  textViewFrame.size.width -= self.contentInset.left + self.contentInset.right - lineFragmentPadding * 2.0;
  textViewFrame.size.height -= self.contentInset.top + self.contentInset.bottom;
  textViewFrame.size.width = MAX(0, textViewFrame.size.width);
  textViewFrame.size.height = MAX(0, textViewFrame.size.height);
  self.textView.frame = textViewFrame;
  [self.textView sizeThatFits:self.textView.frame.size];
}

- (void)updateGrowingTextViewWithNewHeight:(CGFloat)newHeight difference:(CGFloat)difference {
  if ([self.delegate respondsToSelector:@selector(growingTextView:willChangeHeight:difference:)]) {
    [self.delegate growingTextView:self willChangeHeight:newHeight difference:difference];
  }
  CGRect frame = self.frame;
  frame.size.height = newHeight;
  self.frame = frame;
  [self updateTextViewFrame];
}

- (void)updatedHeight:(CGFloat *)newHeight difference:(CGFloat *)difference {
  CGFloat updatedHeight = [self calculateHeight];
  if (updatedHeight < self.minHeight || !self.hasText) {
    updatedHeight = self.minHeight;
  }
  if (self.maxHeight > 0 && updatedHeight > self.maxHeight) {
    updatedHeight = self.maxHeight;
  }

  if (newHeight) {
    *newHeight = updatedHeight;
  }
  if (difference) {
    *difference = updatedHeight - CGRectGetHeight(self.frame);
  }
}

- (CGFloat)heightForNumberOfLines:(NSInteger)numberOfLines {
  NSMutableString *text = [NSMutableString stringWithString:@"-"];
  if (numberOfLines > 0) {
    for (NSInteger index = 1; index < numberOfLines; index++) {
      [text appendString:@"\n|W|"];
    }
  }
  NEInternalTextView *textViewCopy = [self.textView copy];
  textViewCopy.text = text;
  return ceil([textViewCopy sizeThatFits:textViewCopy.frame.size].height + self.contentInset.top + self.contentInset.bottom);
}

- (void)updateMaxHeight {
  if (self.maxNumberOfLines > 0) {
    _maxHeight = [self heightForNumberOfLines:self.maxNumberOfLines];
  }
}

- (void)updateMinHeight {
  if (self.minNumberOfLines > 0) {
    _minHeight = [self heightForNumberOfLines:self.minNumberOfLines];
  }
}

- (void)updateScrollPositionAnimated:(BOOL)animated {
  UITextRange *selectedTextRange = self.textView.selectedTextRange;
  if (!selectedTextRange) {
    return;
  }

  CGRect caretRect = [self.textView caretRectForPosition:selectedTextRange.end];
  CGFloat caretY = MAX(CGRectGetMinY(caretRect) + CGRectGetHeight(caretRect) - CGRectGetHeight(self.textView.frame), 0);
  if (!isfinite(caretY) || caretY == CGFLOAT_MAX) {
    return;
  }

  CGPoint contentOffset = CGPointMake(0, caretY);
  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.textView setContentOffset:contentOffset animated:NO];
    [UIView commitAnimations];
  } else {
    [self.textView setContentOffset:contentOffset animated:NO];
  }
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  if ([self.delegate respondsToSelector:@selector(growingTextViewShouldBeginEditing:)]) {
    return [self.delegate growingTextViewShouldBeginEditing:self];
  }
  return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
  if ([self.delegate respondsToSelector:@selector(growingTextViewShouldEndEditing:)]) {
    return [self.delegate growingTextViewShouldEndEditing:self];
  }
  return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
  if ([self.delegate respondsToSelector:@selector(growingTextViewDidBeginEditing:)]) {
    [self.delegate growingTextViewDidBeginEditing:self];
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  if ([self.delegate respondsToSelector:@selector(growingTextViewDidEndEditing:)]) {
    [self.delegate growingTextViewDidEndEditing:self];
  }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if (!self.hasText && [text isEqualToString:@""]) {
    return NO;
  }
  if ([self.delegate respondsToSelector:@selector(growingTextView:shouldChangeTextInRange:replacementText:)]) {
    return [self.delegate growingTextView:self shouldChangeTextInRange:range replacementText:text];
  }

  if ([text isEqualToString:@"\n"]) {
    if ([self.delegate respondsToSelector:@selector(growingTextViewShouldReturn:)]) {
      return [self.delegate growingTextViewShouldReturn:self];
    }
    [textView resignFirstResponder];
    return NO;
  }
  return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
  [self updateHeight];
  if ([self.delegate respondsToSelector:@selector(growingTextViewDidChange:)]) {
    [self.delegate growingTextViewDidChange:self];
  }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  CGFloat newHeight = 0;
  CGFloat difference = 0;
  [self updatedHeight:&newHeight difference:&difference];
  if (difference == 0) {
    [self updateScrollPositionAnimated:YES];
  }
  if ([self.delegate respondsToSelector:@selector(growingTextViewDidChangeSelection:)]) {
    [self.delegate growingTextViewDidChangeSelection:self];
  }
}

@end
