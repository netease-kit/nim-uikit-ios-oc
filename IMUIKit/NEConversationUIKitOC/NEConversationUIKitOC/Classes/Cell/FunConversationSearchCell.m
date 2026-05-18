// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunConversationSearchCell.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

static UIColor *NEFunConversationLineBorderColor(void) {
  return [UIColor ne_colorWithHexString:@"#E5E5E5"];
}

@interface FunConversationSearchCell ()
@property (nonatomic, strong) UIView *bottomLine;
@end

@implementation FunConversationSearchCell

- (void)setupSubviews {
  [super setupSubviews];
  self.headImageView.layer.cornerRadius = 4.0;
  [self.contentView updateLayoutConstraintFirstItem:self.headImageView secondItem:nil attribute:NSLayoutAttributeWidth constant:40.0];
  [self.contentView updateLayoutConstraintFirstItem:self.headImageView secondItem:nil attribute:NSLayoutAttributeHeight constant:40.0];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.headImageView.leftAnchor],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

- (UIColor *)getRangeTextColor {
  return UIColor.ne_funTheme;
}

- (UIView *)bottomLine {
  if (_bottomLine == nil) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = NEFunConversationLineBorderColor();
  }
  return _bottomLine;
}

@end
