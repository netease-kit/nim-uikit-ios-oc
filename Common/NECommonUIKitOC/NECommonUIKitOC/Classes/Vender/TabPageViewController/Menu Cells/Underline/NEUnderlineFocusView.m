// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUnderlineFocusView.h"
#import "Array+NSLayoutConstraint.h"
#import "NEPagingKitProxy.h"

@interface NEUnderlineFocusView ()

@property (nonatomic, strong) UIView *underlineView;
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@end

@implementation NEUnderlineFocusView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _underlineColor = NEPagingKitConfig.focusColor;
    _underlineHeight = 4.0;
    [self setup];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _underlineColor = NEPagingKitConfig.focusColor;
    _underlineHeight = 4.0;
    [self setup];
  }
  return self;
}

- (void)setup {
  self.underlineView = [[UIView alloc] init];
  self.underlineView.translatesAutoresizingMaskIntoConstraints = NO;
  self.underlineView.backgroundColor = self.underlineColor;
  [self addSubview:self.underlineView];

  self.widthConstraint = [self.underlineView.widthAnchor constraintEqualToConstant:self.underlineHeight];
  self.heightConstraint = [self.underlineView.heightAnchor constraintEqualToConstant:self.underlineHeight];
  self.widthConstraint.active = NO;
  self.heightConstraint.active = YES;

  NSArray<NSNumber *> *vertical = @[ @(NSLayoutAttributeBottom) ];
  NSArray<NSNumber *> *horizontal = @[ @(NSLayoutAttributeWidth), @(NSLayoutAttributeCenterX) ];
  NSArray<NSLayoutConstraint *> *constraintsA = [vertical ne_constraintsAnchorFromView:self.underlineView
                                                                                toView:self];
  NSArray<NSLayoutConstraint *> *constraintsB = [horizontal ne_constraintsAnchorFromView:self.underlineView
                                                                                   toView:self];
  for (NSLayoutConstraint *constraint in constraintsB) {
    constraint.priority = UILayoutPriorityDefaultHigh;
    constraint.active = YES;
  }
  [self addConstraints:constraintsA];
  for (NSLayoutConstraint *constraint in constraintsA) {
    constraint.active = YES;
  }
}

- (void)setUnderlineColor:(UIColor *)underlineColor {
  _underlineColor = underlineColor ?: NEPagingKitConfig.focusColor;
  self.underlineView.backgroundColor = _underlineColor;
}

- (void)setUnderlineHeight:(CGFloat)underlineHeight {
  _underlineHeight = underlineHeight;
  self.heightConstraint.constant = underlineHeight;
}

- (void)setUnderlineWidth:(NSNumber *)underlineWidth {
  _underlineWidth = underlineWidth;
  if (underlineWidth) {
    self.widthConstraint.active = YES;
    self.widthConstraint.constant = underlineWidth.doubleValue;
  } else {
    self.widthConstraint.active = NO;
  }
}

- (BOOL)masksToBounds {
  return self.underlineView.layer.masksToBounds;
}

- (void)setMasksToBounds:(BOOL)masksToBounds {
  self.underlineView.layer.masksToBounds = masksToBounds;
}

- (CGFloat)cornerRadius {
  return self.underlineView.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
  self.underlineView.layer.cornerRadius = cornerRadius;
}

@end
