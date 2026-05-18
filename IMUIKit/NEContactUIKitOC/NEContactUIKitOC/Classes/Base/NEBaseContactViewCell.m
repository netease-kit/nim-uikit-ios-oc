// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactViewCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/NEConstant.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseContactViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupCommonCircleHeader {
  [self.contentView addSubview:self.userHeaderView];
  self.leftConstraint = [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20];
  self.leftConstraint.active = YES;
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)userHeaderView {
  if (!_userHeaderView) {
    _userHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _userHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _userHeaderView.clipsToBounds = YES;
    _userHeaderView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _userHeaderView.userInteractionEnabled = YES;
  }
  return _userHeaderView;
}

- (RedAngleLabel *)redAngleView {
  if (!_redAngleView) {
    _redAngleView = [[RedAngleLabel alloc] init];
    _redAngleView.translatesAutoresizingMaskIntoConstraints = NO;
    _redAngleView.font = [NEConstant defaultTextFont:12];
    _redAngleView.textColor = [UIColor whiteColor];
    _redAngleView.text = @"99+";
    _redAngleView.backgroundColor = [NEConstant hexRGB:0xF24957];
    _redAngleView.textInsets = UIEdgeInsetsMake(3, 7, 3, 7);
    _redAngleView.layer.cornerRadius = 9;
    _redAngleView.clipsToBounds = YES;
    _redAngleView.hidden = YES;
    _redAngleView.accessibilityIdentifier = @"id.unread";
  }
  return _redAngleView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:14.0];
    _titleLabel.textColor = [UIColor ne_colorWithHexString:@"333333"];
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
}

- (UILabel *)optionLabel {
  if (!_optionLabel) {
    _optionLabel = [[UILabel alloc] init];
    _optionLabel.textAlignment = NSTextAlignmentLeft;
    _optionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _optionLabel.font = [UIFont systemFontOfSize:14.0];
    _optionLabel.textColor = [UIColor ne_colorWithHexString:@"333333"];
    _optionLabel.accessibilityIdentifier = @"id.action";
  }
  return _optionLabel;
}

@end
