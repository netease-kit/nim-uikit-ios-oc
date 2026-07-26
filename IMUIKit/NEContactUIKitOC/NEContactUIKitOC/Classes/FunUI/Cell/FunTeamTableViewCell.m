// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamTableViewCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "FunContactUIColor.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface FunTeamTableViewCell ()
@property(nonatomic, strong) UIView *bottomLine;
@end

@implementation FunTeamTableViewCell

- (void)commonUI {
  [super commonUI];
  self.userHeaderView.layer.cornerRadius = 4;
  [self updateUserHeaderViewSize:40];

  self.titleLabel.textColor = [UIColor ne_darkText];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.userHeaderView.leftAnchor],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1],
  ]];
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = [UIColor funContactLineBorderColor];
  }
  return _bottomLine;
}

@end
