// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamTableViewCell.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NETeam.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/NIMExtension.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NEFriendUserCache.h>

@implementation NEBaseTeamTableViewCell

- (void)updateConstraintConstantForFirstItem:(id)firstItem
                              firstAttribute:(NSLayoutAttribute)firstAttribute
                                  secondItem:(nullable id)secondItem
                                    constant:(CGFloat)constant {
  for (NSLayoutConstraint *constraint in self.contentView.constraints) {
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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  [self.contentView addSubview:self.userHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [self.userHeaderView.widthAnchor constraintEqualToConstant:42],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:42],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-35],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.arrowImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.arrowImageView.widthAnchor constraintEqualToConstant:15],
    [self.arrowImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.arrowImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];
}

- (void)updateTitleLabelRightConstant:(CGFloat)constant {
  [self updateConstraintConstantForFirstItem:self.titleLabel
                              firstAttribute:NSLayoutAttributeRight
                                  secondItem:self.contentView
                                    constant:constant];
}

- (void)updateUserHeaderViewSize:(CGFloat)size {
  [self updateConstraintConstantForFirstItem:self.userHeaderView
                              firstAttribute:NSLayoutAttributeWidth
                                  secondItem:nil
                                    constant:size];
  [self updateConstraintConstantForFirstItem:self.userHeaderView
                              firstAttribute:NSLayoutAttributeHeight
                                  secondItem:nil
                                    constant:size];
}

- (void)setModel:(id)model {
  if (![model isKindOfClass:[NETeam class]]) {
    return;
  }
  NETeam *team = (NETeam *)model;

  self.titleLabel.text = team.teamName;

  NSString *url = team.avatarUrl;
  NSString *name = [team.v2Team ne_getShortName:2] ?: @"";
  NSString *accountId = team.teamId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)userHeaderView {
  if (!_userHeaderView) {
    _userHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _userHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _userHeaderView.clipsToBounds = YES;
    _userHeaderView.titleLabel.font = [NEConstant defaultTextFont:16.0];
    _userHeaderView.userInteractionEnabled = YES;
  }
  return _userHeaderView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
}

- (UIImageView *)arrowImageView {
  if (!_arrowImageView) {
    _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _arrowImageView.contentMode = UIViewContentModeCenter;
    _arrowImageView.hidden = YES;
  }
  return _arrowImageView;
}

@end
