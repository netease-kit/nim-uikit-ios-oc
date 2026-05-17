// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomView.h"

@implementation CustomView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.translatesAutoresizingMaskIntoConstraints = NO;
    [_button addTarget:self action:@selector(tapView) forControlEvents:UIControlEventTouchUpInside];
    [_button setTitle:@"按钮" forState:UIControlStateNormal];
    _button.backgroundColor = UIColor.redColor;
    [self addSubview:_button];
    [NSLayoutConstraint activateConstraints:@[
      [_button.topAnchor constraintEqualToAnchor:self.topAnchor],
      [_button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
      [_button.widthAnchor constraintEqualToConstant:200],
      [_button.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    ]];
  }
  return self;
}

- (void)tapView {
  NSLog(@"点击了自定义按钮");
}

@end
