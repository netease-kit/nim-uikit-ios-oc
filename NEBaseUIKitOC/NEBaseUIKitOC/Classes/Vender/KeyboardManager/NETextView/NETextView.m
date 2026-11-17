// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETextView.h"
#import <objc/runtime.h>

@interface NETextView ()
@property (nonatomic, strong, readwrite) UILabel *placeholderLabel;
@end

@implementation NETextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
  self = [super initWithFrame:frame textContainer:textContainer];
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

- (void)awakeFromNib {
  [super awakeFromNib];
  [self commonInit];
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [_placeholderLabel removeFromSuperview];
}

- (void)commonInit {
  static void *kNETextViewDidInit = &kNETextViewDidInit;
  if (objc_getAssociatedObject(self, kNETextViewDidInit)) {
    return;
  }
  objc_setAssociatedObject(self, kNETextViewDidInit, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(refreshPlaceholder)
                                             name:UITextViewTextDidChangeNotification
                                           object:self];

  _placeholderLabel = [[UILabel alloc] init];
  _placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
  _placeholderLabel.numberOfLines = 0;
  _placeholderLabel.font = self.font;
  _placeholderLabel.textAlignment = self.textAlignment;
  _placeholderLabel.backgroundColor = UIColor.clearColor;
  _placeholderLabel.isAccessibilityElement = NO;
  if (@available(iOS 13.0, *)) {
    _placeholderLabel.textColor = UIColor.systemGrayColor;
  } else {
    _placeholderLabel.textColor = UIColor.lightTextColor;
  }
  _placeholderLabel.alpha = 0;
  [self addSubview:_placeholderLabel];
  [self refreshPlaceholder];
}

- (UIEdgeInsets)placeholderInsets {
  return UIEdgeInsetsMake(self.textContainerInset.top,
                          self.textContainerInset.left + self.textContainer.lineFragmentPadding,
                          self.textContainerInset.bottom,
                          self.textContainerInset.right + self.textContainer.lineFragmentPadding);
}

- (CGRect)placeholderExpectedFrame {
  UIEdgeInsets insets = [self placeholderInsets];
  CGFloat maxWidth = CGRectGetWidth(self.frame) - insets.left - insets.right;
  CGSize expectedSize = [self.placeholderLabel sizeThatFits:CGSizeMake(maxWidth, CGRectGetHeight(self.frame) - insets.top - insets.bottom)];
  return CGRectMake(insets.left, insets.top, maxWidth, expectedSize.height);
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.placeholderLabel.frame = [self placeholderExpectedFrame];
}

- (void)refreshPlaceholder {
  BOOL hasText = self.text.length > 0 || self.attributedText.string.length > 0;
  self.placeholderLabel.alpha = hasText ? 0 : 1;
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
  self.placeholderLabel.textColor = placeholderTextColor;
}

- (UIColor *)placeholderTextColor {
  return self.placeholderLabel.textColor;
}

- (void)setPlaceholder:(NSString *)placeholder {
  self.placeholderLabel.text = placeholder;
  [self refreshPlaceholder];
}

- (NSString *)placeholder {
  return self.placeholderLabel.text;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
  self.placeholderLabel.attributedText = attributedPlaceholder;
  [self refreshPlaceholder];
}

- (NSAttributedString *)attributedPlaceholder {
  return self.placeholderLabel.attributedText;
}

- (void)setText:(NSString *)text {
  [super setText:text];
  [self refreshPlaceholder];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
  [super setAttributedText:attributedText];
  [self refreshPlaceholder];
}

- (void)setFont:(UIFont *)font {
  [super setFont:font];
  self.placeholderLabel.font = font ?: [UIFont systemFontOfSize:12.0];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
  [super setTextAlignment:textAlignment];
  self.placeholderLabel.textAlignment = textAlignment;
}

- (CGSize)intrinsicContentSize {
  if (self.hasText) {
    return [super intrinsicContentSize];
  }
  CGSize size = [super intrinsicContentSize];
  UIEdgeInsets insets = [self placeholderInsets];
  size.height = CGRectGetHeight([self placeholderExpectedFrame]) + insets.top + insets.bottom;
  return size;
}

- (void)removeAllAutoLayout {
  NSArray<NSLayoutConstraint *> *selfConstraints = self.constraints.copy;
  if (selfConstraints.count > 0) {
    [NSLayoutConstraint deactivateConstraints:selfConstraints];
    [self removeConstraints:selfConstraints];
  }

  UIView *container = self.superview;
  while (container) {
    NSMutableArray<NSLayoutConstraint *> *relatedConstraints = [NSMutableArray array];
    for (NSLayoutConstraint *constraint in container.constraints.copy) {
      if (constraint.firstItem == self || constraint.secondItem == self) {
        [relatedConstraints addObject:constraint];
      }
    }
    if (relatedConstraints.count > 0) {
      [NSLayoutConstraint deactivateConstraints:relatedConstraints];
      [container removeConstraints:relatedConstraints];
    }
    container = container.superview;
  }
}

@end
