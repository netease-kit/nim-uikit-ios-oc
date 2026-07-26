// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BlackListCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface BlackListCell ()
@property(nonatomic, strong) UIView *bottomLine;
@end

@implementation BlackListCell

- (void)commonUI {
  [super commonUI];
  self.userHeaderView.layer.cornerRadius = 21;

  self.titleLabel.font = [UIFont systemFontOfSize:16];
  self.titleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];

  self.button.layer.borderColor = [UIColor colorWithRed:0.2 green:0.494 blue:1 alpha:1].CGColor;
  [self.button setTitleColor:[UIColor colorWithRed:0.2 green:0.494 blue:1 alpha:1] forState:UIControlStateNormal];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1],
  ]];
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = [UIColor ne_greyLine];
  }
  return _bottomLine;
}

@end
