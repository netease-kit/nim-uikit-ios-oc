// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseUserInfoHeaderView.h"
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "ContactConst.h"
#import <NEChatKit/NEChatKit.h>

@interface NEBaseUserInfoHeaderView ()
@property (nonatomic, strong, readwrite) UIView *lineView;
@end

@implementation NEBaseUserInfoHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _labelConstraints = [NSMutableArray array];
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  self.backgroundColor = [UIColor whiteColor];
  [self addSubview:self.userHeaderView];
  [self addSubview:self.titleLabel];
  [self addSubview:self.detailLabel];
  [self addSubview:self.lineView];

  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:20],
    [self.userHeaderView.widthAnchor constraintEqualToConstant:60],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:60],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0],
  ]];

  [self commonUIWithShowDetail:NO];
}

- (void)commonUIWithShowDetail:(BOOL)showDetail {
  [NSLayoutConstraint deactivateConstraints:self.labelConstraints];
  NSMutableArray *titleConstraint = [NSMutableArray array];
  NSMutableArray *detailConstraint = [NSMutableArray array];
  NSMutableArray *detail2Constraint = [NSMutableArray array];

  if (showDetail) {
    titleConstraint = [NSMutableArray arrayWithArray:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:20],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-35],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor constant:-2],
      [self.titleLabel.heightAnchor constraintEqualToConstant:22],
    ]];

    detailConstraint = [NSMutableArray arrayWithArray:@[
      [self.detailLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
      [self.detailLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
      [self.detailLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
      [self.detailLabel.heightAnchor constraintEqualToConstant:16],
    ]];

    [self addSubview:self.detailLabel2];
    detail2Constraint = [NSMutableArray arrayWithArray:@[
      [self.detailLabel2.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
      [self.detailLabel2.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
      [self.detailLabel2.topAnchor constraintEqualToAnchor:self.detailLabel.bottomAnchor],
      [self.detailLabel.heightAnchor constraintEqualToConstant:16],
    ]];
  } else {
    titleConstraint = [NSMutableArray arrayWithArray:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:16],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor constant:7],
      [self.titleLabel.heightAnchor constraintEqualToConstant:22],
    ]];

    detailConstraint = [NSMutableArray arrayWithArray:@[
      [self.detailLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
      [self.detailLabel.rightAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
      [self.detailLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
      [self.detailLabel.heightAnchor constraintEqualToConstant:16],
    ]];

    [self.detailLabel2 removeFromSuperview];
    detail2Constraint = [NSMutableArray array];
  }

  NSMutableArray *all = [NSMutableArray array];
  [all addObjectsFromArray:titleConstraint];
  [all addObjectsFromArray:detailConstraint];
  [all addObjectsFromArray:detail2Constraint];
  self.labelConstraints = all;
  [NSLayoutConstraint activateConstraints:self.labelConstraints];
  [self updateConstraintsIfNeeded];
}

- (void)setData:(NEUserWithFriend *)user {
  if (!user) return;

  // avatar
  NSString *url = user.user.avatar;
  NSString *name = [user shortName:YES count:2] ?: @"";
  NSString *accountId = user.user.accountId ?: @"";
  [self.userHeaderView configHeadData:url name:name uid:accountId];

  // title
  NSString *uid = user.user.accountId ?: @"";
  NSString *alias = user.friend.alias;
  if (alias && alias.length > 0) {
    [self commonUIWithShowDetail:YES];
    self.titleLabel.text = alias;
    self.detailLabel.text = [NSString stringWithFormat:@"%@:%@", contactLocalizable(@"nick"), user.user.name ?: uid];
    self.detailLabel.copyString = user.user.name ?: uid;
    self.detailLabel2.text = [NSString stringWithFormat:@"%@:%@", contactLocalizable(@"account"), uid];
    self.detailLabel2.copyString = uid;
  } else {
    [self commonUIWithShowDetail:NO];
    self.titleLabel.text = [user showName];
    self.detailLabel.text = [NSString stringWithFormat:@"%@:%@", contactLocalizable(@"account"), uid];
    self.detailLabel.copyString = uid;
    self.detailLabel2.copyString = nil;
  }
}

- (void)setDataWithUser:(NEUserWithFriend *)user {
  [self setData:user];
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

- (CopyableLabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[CopyableLabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont boldSystemFontOfSize:22];
    _titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
}

- (CopyableLabel *)detailLabel {
  if (!_detailLabel) {
    _detailLabel = [[CopyableLabel alloc] init];
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _detailLabel.font = [UIFont systemFontOfSize:16];
    _detailLabel.textColor = [UIColor ne_greyText];
    _detailLabel.accessibilityIdentifier = @"id.account";
  }
  return _detailLabel;
}

- (CopyableLabel *)detailLabel2 {
  if (!_detailLabel2) {
    _detailLabel2 = [[CopyableLabel alloc] init];
    _detailLabel2.translatesAutoresizingMaskIntoConstraints = NO;
    _detailLabel2.font = [UIFont systemFontOfSize:16];
    _detailLabel2.textColor = [UIColor ne_greyText];
    _detailLabel2.accessibilityIdentifier = @"id.commentName";
  }
  return _detailLabel2;
}

- (UIView *)lineView {
  if (!_lineView) {
    _lineView = [[UIView alloc] init];
    _lineView.backgroundColor = [UIColor ne_greyLine];
    _lineView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _lineView;
}

@end
