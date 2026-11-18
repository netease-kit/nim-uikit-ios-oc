// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseBlackListCell.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NEChatKit.h>

@interface NEBaseBlackListCell ()
@property (nonatomic, strong, nullable) NEUserWithFriend *currentUser;
@property (nonatomic, strong) UIView *bottomLine;
@end

@implementation NEBaseBlackListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];
  self.button.layer.borderWidth = 1;
  self.button.layer.cornerRadius = 4;
  self.button.titleLabel.font = [UIFont systemFontOfSize:14];
  self.button.translatesAutoresizingMaskIntoConstraints = NO;
  self.button.contentMode = UIViewContentModeCenter;
  self.button.clipsToBounds = YES;
  [self.button addTarget:self action:@selector(buttonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.button setTitle:contactLocalizable(@"remove_black") forState:UIControlStateNormal];
  self.button.accessibilityIdentifier = @"id.relieve";
  [self.contentView addSubview:self.button];
  [NSLayoutConstraint activateConstraints:@[
    [self.button.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.button.widthAnchor constraintEqualToConstant:60],
    [self.button.heightAnchor constraintEqualToConstant:32],
    [self.button.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1],
  ]];
  [self updateTitleLabelRightConstant:-80];
}

- (void)buttonEvent:(UIButton *)sender {
  [self.delegate removeUserWithAccount:self.currentUser.user.accountId index:self.index];
}

- (void)buttonEventWithSender:(UIButton *)sender {
  [self buttonEvent:sender];
}

- (void)setModel:(id)model {
  if (![model isKindOfClass:[NEUserWithFriend class]]) {
    return;
  }
  NEUserWithFriend *user = (NEUserWithFriend *)model;
  self.currentUser = user;

  // title
  self.titleLabel.text = [user showName];

  // avatar
  NSString *url = user.user.avatar;
  NSString *name = [user shortName:YES count:2] ?: @"";
  NSString *accountId = user.user.accountId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];
}

#pragma mark - Lazy Init

- (UIButton *)button {
  if (!_button) {
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
  }
  return _button;
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
