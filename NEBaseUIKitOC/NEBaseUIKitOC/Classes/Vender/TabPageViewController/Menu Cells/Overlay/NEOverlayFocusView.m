// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEOverlayFocusView.h"

@interface NEOverlayFocusView ()

@property (nonatomic, strong) UIView *contentView;

@end

@implementation NEOverlayFocusView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self addConstraintsIfNeeded];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self addConstraintsIfNeeded];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.contentView.layer.cornerRadius = CGRectGetHeight(self.contentView.bounds) / 2.0;
}

- (UIColor *)contentBackgroundColor {
  return self.contentView.backgroundColor;
}

- (void)setContentBackgroundColor:(UIColor *)contentBackgroundColor {
  self.contentView.backgroundColor = contentBackgroundColor;
}

- (void)addConstraintsIfNeeded {
  self.contentView = [[UIView alloc] init];
  self.contentView.backgroundColor = UIColor.lightGrayColor;
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:self.contentView];

  NSLayoutConstraint *trailingConstraint =
      [self.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:8.0];
  NSLayoutConstraint *leadingConstraint =
      [self.contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8.0];
  NSLayoutConstraint *centerConstraint =
      [self.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor];
  NSLayoutConstraint *heightConstraint =
      [self.contentView.heightAnchor constraintEqualToConstant:32.0];

  [NSLayoutConstraint activateConstraints:@[
    centerConstraint,
    trailingConstraint,
    leadingConstraint,
    heightConstraint,
  ]];
}

@end
