// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseValidationCell.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseValidationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [self setupCommonCircleHeader];

  [self.contentView addSubview:self.redAngleView];
  [NSLayoutConstraint activateConstraints:@[
    [self.redAngleView.centerXAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:-8],
    [self.redAngleView.centerYAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor constant:8],
    [self.redAngleView.heightAnchor constraintEqualToConstant:18],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:10],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor],
  ]];
  self.titleLabelRightMargin = [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-10];
  self.titleLabelRightMargin.active = YES;

  [self.contentView addSubview:self.optionLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.optionLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:10],
    [self.optionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor],
    [self.optionLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-180],
  ]];

  [self.contentView addSubview:self.line];
  self.line.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.line.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [self.line.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.line.heightAnchor constraintEqualToConstant:1],
    [self.line.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];
  self.line.backgroundColor = [UIColor ne_colorWithHexString:@"#F5F8FC"];
}

- (void)configeWithApplication:(NEAddApplication *)application {
  // 设置头像
  NSString *url = application.displayUserWithFriend.user.avatar;
  NSString *name = [application.displayUserWithFriend shortName:YES count:2] ?: application.displayUserId ?: @"";
  NSString *accountId = application.displayUserWithFriend.user.accountId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];

  // 设置未读状态（未读数角标+底色）
  self.redAngleView.hidden = YES;
  self.contentView.backgroundColor = [UIColor whiteColor];
  if (application.unreadCount > 0) {
    self.contentView.backgroundColor = [UIColor ne_colorWithHexString:@"0xF3F5F7"];
    if (application.unreadCount > 1) {
      self.redAngleView.hidden = NO;
      self.redAngleView.text = application.unreadCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)application.unreadCount];
    }
  }

  self.titleLabel.text = [application.displayUserWithFriend showName] ?: application.displayUserId;
  self.optionLabel.text = application.detail;
}

- (void)configeWithTeamJoinAction:(NETeamJoinAction *)teamJoinAction {
  // 设置头像
  NSString *url = teamJoinAction.displayUserWithFriend.user.avatar;
  NSString *name = [teamJoinAction.displayUserWithFriend shortName:YES count:2] ?: teamJoinAction.displayUserId;
  NSString *accountId = teamJoinAction.displayUserWithFriend.user.accountId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];

  // 设置未读状态（未读数角标+底色）
  self.redAngleView.hidden = YES;
  self.contentView.backgroundColor = [UIColor whiteColor];
  if (teamJoinAction.unreadCount > 0) {
    self.contentView.backgroundColor = [UIColor ne_colorWithHexString:@"0xF3F5F7"];
    if (teamJoinAction.unreadCount > 1) {
      self.redAngleView.hidden = NO;
      self.redAngleView.text = teamJoinAction.unreadCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)teamJoinAction.unreadCount];
    }
  }

  self.titleLabel.text = [teamJoinAction.displayUserWithFriend showName] ?: teamJoinAction.displayUserId;
  self.optionLabel.text = teamJoinAction.detail;
}

#pragma mark - Lazy Init

- (UIView *)line {
  if (!_line) {
    _line = [[UIView alloc] init];
  }
  return _line;
}

@end
