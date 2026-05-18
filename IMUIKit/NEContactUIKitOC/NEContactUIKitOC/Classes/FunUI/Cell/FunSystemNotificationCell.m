// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSystemNotificationCell.h"
#import "FunContactUIColor.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

static void NEFunContactUpdateConstraintConstant(UIView *containerView,
                                                 id firstItem,
                                                 NSLayoutAttribute firstAttribute,
                                                 id _Nullable secondItem,
                                                 CGFloat constant) {
  for (NSLayoutConstraint *constraint in containerView.constraints) {
    if (constraint.firstItem != firstItem || constraint.firstAttribute != firstAttribute) {
      continue;
    }
    if (constraint.secondItem != secondItem) {
      continue;
    }
    constraint.constant = constant;
    return;
  }
}

@implementation FunSystemNotificationCell

- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  self.userHeaderView.layer.cornerRadius = 4;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:40],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:40],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

- (void)setupUI {
  [super setupUI];
  NEFunContactUpdateConstraintConstant(self.contentView, self.line, NSLayoutAttributeRight, self.contentView, 0);
  [self.contentView layoutIfNeeded];

  self.line.backgroundColor = [UIColor funContactLineBorderColor];
  self.agreeButton.backgroundColor = [UIColor funContactThemeColor];
  [self.agreeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.agreeButton.layer.borderColor = [UIColor funContactThemeColor].CGColor;
}

@end
