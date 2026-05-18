// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEInternalTextView.h"

@interface NEInternalTextView ()

@property (nonatomic, assign) BOOL scrollEnabledTemp;

@end

@implementation NEInternalTextView

- (void)setPlaceholder:(NSAttributedString *)placeholder {
  _placeholder = [placeholder copy];
  [self setNeedsDisplay];
}

- (void)setShouldDisplayPlaceholder:(BOOL)shouldDisplayPlaceholder {
  if (_shouldDisplayPlaceholder == shouldDisplayPlaceholder) {
    return;
  }
  _shouldDisplayPlaceholder = shouldDisplayPlaceholder;
  [self setNeedsDisplay];
}

- (void)setText:(NSString *)text {
  self.scrollEnabledTemp = self.isScrollEnabled;
  self.scrollEnabled = YES;
  [super setText:text];
  self.scrollEnabled = self.scrollEnabledTemp;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];

  if (!self.placeholder || !self.shouldDisplayPlaceholder) {
    return;
  }

  CGSize placeholderSize = [self sizeForAttributedString:self.placeholder];
  CGFloat xPosition = self.textContainer.lineFragmentPadding + self.textContainerInset.left;
  CGFloat yPosition = (self.textContainerInset.top - self.textContainerInset.bottom) / 2.0;
  CGRect placeholderRect = CGRectMake(xPosition, yPosition, placeholderSize.width, placeholderSize.height);
  [self.placeholder drawInRect:placeholderRect];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
  if (self.isCaretHidden) {
    return CGRectZero;
  }
  return [super caretRectForPosition:position];
}

- (id)copyWithZone:(NSZone *)zone {
  NEInternalTextView *textView = [[[self class] allocWithZone:zone] initWithFrame:self.frame];
  textView.scrollEnabled = self.isScrollEnabled;
  textView.shouldDisplayPlaceholder = self.shouldDisplayPlaceholder;
  textView.caretHidden = self.isCaretHidden;
  textView.placeholder = self.placeholder;
  textView.text = self.text;
  textView.font = self.font;
  textView.textColor = self.textColor;
  textView.textAlignment = self.textAlignment;
  textView.editable = self.isEditable;
  textView.selectedRange = self.selectedRange;
  textView.dataDetectorTypes = self.dataDetectorTypes;
  textView.returnKeyType = self.returnKeyType;
  textView.keyboardType = self.keyboardType;
  textView.enablesReturnKeyAutomatically = self.enablesReturnKeyAutomatically;
  textView.textContainerInset = self.textContainerInset;
  textView.textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding;
  textView.showsHorizontalScrollIndicator = self.showsHorizontalScrollIndicator;
  textView.contentInset = self.contentInset;
  textView.contentMode = self.contentMode;
  return textView;
}

- (CGSize)sizeForAttributedString:(NSAttributedString *)attributedString {
  CGSize size = [attributedString size];
  return CGRectIntegral((CGRect){CGPointZero, size}).size;
}

@end
