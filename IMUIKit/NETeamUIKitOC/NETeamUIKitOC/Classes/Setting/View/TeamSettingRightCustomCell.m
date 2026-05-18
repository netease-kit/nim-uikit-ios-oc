// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamSettingRightCustomCell.h"

@implementation TeamSettingRightCustomCell

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if (self.model.rightCustomViewIcon) {
    self.customRightView.hidden = NO;
    [self.customRightView setImage:self.model.rightCustomViewIcon forState:UIControlStateNormal];
    self.arrowView.hidden = YES;
  } else {
    self.customRightView.hidden = YES;
    self.arrowView.hidden = NO;
  }
}

- (void)setupUI {
  [super setupUI];

  [self.contentView addSubview:self.customRightView];
  [NSLayoutConstraint activateConstraints:@[
    [self.customRightView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.customRightView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
    [self.customRightView.widthAnchor constraintEqualToConstant:15.0],
    [self.customRightView.heightAnchor constraintEqualToConstant:15.0],
  ]];
  [self.customRightView addTarget:self action:@selector(customRightViewClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)customRightViewClick {
  if (self.model.customViewClick) {
    self.model.customViewClick();
  }
}

- (UIButton *)customRightView {
  if (!_customRightView) {
    _customRightView = [UIButton buttonWithType:UIButtonTypeCustom];
    _customRightView.translatesAutoresizingMaskIntoConstraints = NO;
    _customRightView.accessibilityIdentifier = @"id.accountCopy";
  }
  return _customRightView;
}

@end
