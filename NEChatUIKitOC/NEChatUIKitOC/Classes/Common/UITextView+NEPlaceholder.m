// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UITextView+NEPlaceholder.h"
#import <objc/runtime.h>

static const void *kNEPlaceholderLabelKey = &kNEPlaceholderLabelKey;

@implementation UITextView (NEPlaceholder)

#pragma mark - Swizzle

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Swizzle setText: to update placeholder visibility
    Method orig = class_getInstanceMethod(self, @selector(setText:));
    Method swiz = class_getInstanceMethod(self, @selector(ne_setText:));
    if (orig && swiz) method_exchangeImplementations(orig, swiz);

    // Swizzle setAttributedText:
    Method orig2 = class_getInstanceMethod(self, @selector(setAttributedText:));
    Method swiz2 = class_getInstanceMethod(self, @selector(ne_setAttributedText:));
    if (orig2 && swiz2) method_exchangeImplementations(orig2, swiz2);
  });
}

- (void)ne_setText:(NSString *)text {
  [self ne_setText:text]; // calls original
  [self ne_updatePlaceholderVisibility];
}

- (void)ne_setAttributedText:(NSAttributedString *)attributedText {
  [self ne_setAttributedText:attributedText]; // calls original
  [self ne_updatePlaceholderVisibility];
}

#pragma mark - Placeholder Label

- (UILabel *)ne_placeholderLabel {
  UILabel *label = objc_getAssociatedObject(self, kNEPlaceholderLabelKey);
  if (!label) {
    label = [[UILabel alloc] init];
    label.numberOfLines = 1;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.userInteractionEnabled = NO;
    [self addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
      [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:self.textContainerInset.left + self.textContainer.lineFragmentPadding],
      [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-(self.textContainerInset.right + self.textContainer.lineFragmentPadding)],
      [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.textContainerInset.top],
    ]];

    objc_setAssociatedObject(self, kNEPlaceholderLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ne_textDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
  }
  return label;
}

#pragma mark - Property

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
  UILabel *label = [self ne_placeholderLabel];
  label.attributedText = attributedPlaceholder;
  [self ne_updatePlaceholderVisibility];
}

- (NSAttributedString *)attributedPlaceholder {
  UILabel *label = objc_getAssociatedObject(self, kNEPlaceholderLabelKey);
  return label.attributedText;
}

#pragma mark - Visibility

- (void)ne_updatePlaceholderVisibility {
  UILabel *label = objc_getAssociatedObject(self, kNEPlaceholderLabelKey);
  label.hidden = (self.text.length > 0 || self.attributedText.length > 0);
}

- (void)ne_textDidChange:(NSNotification *)notification {
  [self ne_updatePlaceholderVisibility];
}

@end
