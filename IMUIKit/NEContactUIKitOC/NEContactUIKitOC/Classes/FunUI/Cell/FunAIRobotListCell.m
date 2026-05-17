// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotListCell.h"
#import "FunContactUIColor.h"

@implementation FunAIRobotListCell

- (CGFloat)avatarSize {
  return 40.0;
}

- (CGFloat)avatarCornerRadius {
  return 4.0;
}

- (CGFloat)avatarLeading {
  return 16.0;
}

- (CGFloat)avatarNameSpacing {
  return 11.0;
}

- (CGFloat)nameFont {
  return 17.0;
}

- (BOOL)showArrow {
  return YES;
}

- (void)setupRobotListCellUI {
  [super setupRobotListCellUI];

  [self.contentView addSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (UIView *)dividerLine {
  if (!_dividerLine) {
    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = [UIColor funContactLineBorderColor];
  }
  return _dividerLine;
}

@end
