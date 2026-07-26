// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotListCell.h"
#import "NEAIRobotModel.h"
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseAIRobotListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupRobotListCellUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupRobotListCellUI];
  }
  return self;
}

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
  return -16.0;
}

- (CGFloat)nameRightMargin {
  return [self showArrow] ? [self arrowRightMargin] - 22.0 : -16.0;
}

- (void)setupRobotListCellUI {
  if ([self showArrow]) {
    [self.contentView addSubview:self.arrowView];
    [NSLayoutConstraint activateConstraints:@[
      [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:[self arrowRightMargin]],
      [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
  }

  [self.contentView addSubview:self.robotHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.robotHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:[self avatarLeading]],
    [self.robotHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.robotHeaderView.widthAnchor constraintEqualToConstant:[self avatarSize]],
    [self.robotHeaderView.heightAnchor constraintEqualToConstant:[self avatarSize]],
  ]];

  [self.contentView addSubview:self.robotNameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.robotNameLabel.leftAnchor constraintEqualToAnchor:self.robotHeaderView.rightAnchor constant:[self avatarNameSpacing]],
    [self.robotNameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.robotNameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:[self nameRightMargin]],
  ]];
}

- (void)configure:(NEAIRobotModel *)model {
  self.currentModel = model;

  NSString *accid = model.bot.accid ?: @"";
  NSString *displayName = model.bot.name.length > 0 ? model.bot.name : accid;
  NSString *shortName = [NEFriendUserCache getShortName:displayName length:2] ?: @"";
  [self.robotHeaderView configHeadData:model.bot.icon name:shortName uid:accid];
  self.robotNameLabel.text = displayName;
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)robotHeaderView {
  if (!_robotHeaderView) {
    _robotHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _robotHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _robotHeaderView.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _robotHeaderView.titleLabel.textColor = [UIColor whiteColor];
    _robotHeaderView.layer.cornerRadius = [self avatarCornerRadius];
    _robotHeaderView.clipsToBounds = YES;
  }
  return _robotHeaderView;
}

- (UILabel *)robotNameLabel {
  if (!_robotNameLabel) {
    _robotNameLabel = [[UILabel alloc] init];
    _robotNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _robotNameLabel.font = [UIFont systemFontOfSize:[self nameFont]];
    _robotNameLabel.textColor = [UIColor ne_darkText];
    _robotNameLabel.accessibilityIdentifier = @"id.robotName";
  }
  return _robotNameLabel;
}

- (UIImageView *)arrowView {
  if (!_arrowView) {
    _arrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    _arrowView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _arrowView;
}

@end
