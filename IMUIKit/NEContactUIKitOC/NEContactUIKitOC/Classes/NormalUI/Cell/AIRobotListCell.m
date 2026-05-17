// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIRobotListCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation AIRobotListCell

- (CGFloat)avatarSize {
  return 36.0;
}

- (CGFloat)avatarCornerRadius {
  return 18.0;
}

- (CGFloat)avatarLeading {
  return 20.0;
}

- (CGFloat)avatarNameSpacing {
  return 12.0;
}

- (CGFloat)nameFont {
  return 14.0;
}

- (BOOL)showArrow {
  return YES;
}

- (CGFloat)arrowRightMargin {
  return -36.0;
}

- (void)setupRobotListCellUI {
  [super setupRobotListCellUI];

  [self.contentView addSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (UIView *)dividerLine {
  if (!_dividerLine) {
    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = [UIColor ne_greyLine];
  }
  return _dividerLine;
}

@end
