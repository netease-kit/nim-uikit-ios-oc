// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETitleBarButtonItem.h"
#import "NEInvocation.h"

@interface NETitleBarButtonItem ()

@property (nonatomic, strong, nullable) UIButton *titleButton;
@property (nonatomic, strong, nullable) UIView *titleContainerView;

@end

@implementation NETitleBarButtonItem

- (instancetype)init {
  self = [super init];
  if (self) {
    [self setupTitleView];
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title {
  self = [super initWithTitle:nil style:UIBarButtonItemStylePlain target:nil action:nil];
  if (self) {
    [self setupTitleView];
    self.title = title;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupTitleView];
  }
  return self;
}

- (void)setupTitleView {
  if (self.titleButton) {
    return;
  }

  UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
  container.backgroundColor = UIColor.clearColor;

  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.enabled = NO;
  button.backgroundColor = UIColor.clearColor;
  button.titleLabel.numberOfLines = 3;
  button.titleLabel.textAlignment = NSTextAlignmentCenter;
  [button setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
  if (@available(iOS 13.0, *)) {
    [button setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
  } else {
    [button setTitleColor:[UIColor colorWithRed:0 green:0.5 blue:1 alpha:1] forState:UIControlStateNormal];
  }

  [container addSubview:button];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [button.topAnchor constraintEqualToAnchor:container.topAnchor],
    [button.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    [button.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
    [button.trailingAnchor constraintEqualToAnchor:container.trailingAnchor]
  ]];

  self.titleContainerView = container;
  self.titleButton = button;
  self.customView = container;
  self.titleFont = [UIFont systemFontOfSize:13.0];
}

- (void)setTitleFont:(UIFont *)titleFont {
  _titleFont = titleFont;
  self.titleButton.titleLabel.font = titleFont ?: [UIFont systemFontOfSize:13.0];
}

- (void)setTitle:(NSString *)title {
  [super setTitle:title];
  [self.titleButton setTitle:title forState:UIControlStateNormal];
}

- (void)setTitleColor:(UIColor *)titleColor {
  _titleColor = titleColor;
  [self.titleButton setTitleColor:titleColor ?: UIColor.lightGrayColor forState:UIControlStateDisabled];
}

- (void)setSelectableTitleColor:(UIColor *)selectableTitleColor {
  _selectableTitleColor = selectableTitleColor;
  UIColor *color = selectableTitleColor;
  if (!color) {
    if (@available(iOS 13.0, *)) {
      color = UIColor.systemBlueColor;
    } else {
      color = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
    }
  }
  [self.titleButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)setInvocation:(NEInvocation *)invocation {
  if (self.invocation == invocation) {
    return;
  }

  if (self.titleButton) {
    [self.titleButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
  }

  [super setInvocation:invocation];

  BOOL enabled = invocation.target != nil && invocation.action != NULL;
  self.enabled = enabled;
  self.titleButton.enabled = enabled;

  if (enabled) {
    [self.titleButton addTarget:invocation.target action:invocation.action forControlEvents:UIControlEventTouchUpInside];
  }
}

- (void)dealloc {
  [self.titleButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
  self.customView = nil;
}

@end
