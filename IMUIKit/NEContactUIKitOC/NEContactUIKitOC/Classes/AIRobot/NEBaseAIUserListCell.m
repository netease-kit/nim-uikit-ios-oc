// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIUserListCell.h"
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/NEAIUserModel.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseAIUserListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupAIUserListCellUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupAIUserListCellUI];
  }
  return self;
}

- (void)setupAIUserListCellUI {
  [self.contentView addSubview:self.aiUserHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21.0],
    [self.aiUserHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.aiUserHeaderView.widthAnchor constraintEqualToConstant:42.0],
    [self.aiUserHeaderView.heightAnchor constraintEqualToConstant:42.0],
  ]];

  [self.contentView addSubview:self.aiUserNameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserNameLabel.leftAnchor constraintEqualToAnchor:self.aiUserHeaderView.rightAnchor constant:14.0],
    [self.aiUserNameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.aiUserNameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-116.0],
  ]];
}

- (void)configure:(NEAIUserModel *)model {
  self.currentModel = model;

  NSString *accountId = model.aiUser.accountId ?: @"";
  NSString *displayName = [model.aiUser ne_showName] ?: accountId;
  NSString *shortName = [model.aiUser ne_shortName:2] ?: @"";
  [self.aiUserHeaderView configHeadData:model.aiUser.avatar name:shortName uid:accountId];
  self.aiUserNameLabel.text = displayName;
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)aiUserHeaderView {
  if (!_aiUserHeaderView) {
    _aiUserHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _aiUserHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _aiUserHeaderView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _aiUserHeaderView.titleLabel.textColor = [UIColor whiteColor];
    _aiUserHeaderView.layer.cornerRadius = 21.0;
    _aiUserHeaderView.clipsToBounds = YES;
  }
  return _aiUserHeaderView;
}

- (UILabel *)aiUserNameLabel {
  if (!_aiUserNameLabel) {
    _aiUserNameLabel = [[UILabel alloc] init];
    _aiUserNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _aiUserNameLabel.font = [NEConstant defaultTextFont:16.0];
    _aiUserNameLabel.textColor = [UIColor ne_darkText];
    _aiUserNameLabel.accessibilityIdentifier = @"id.userName";
  }
  return _aiUserNameLabel;
}

@end
