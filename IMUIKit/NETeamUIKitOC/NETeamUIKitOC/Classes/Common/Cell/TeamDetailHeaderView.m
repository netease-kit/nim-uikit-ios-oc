// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDetailHeaderView.h"
#import "TeamConstant.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKit/NIMExtension.h>
#import <NECommonUIKitOC/CopyableLabel.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/NEALog.h>

@interface TeamDetailHeaderView ()
@property (nonatomic, strong) UIView *lineView;
@end

@implementation TeamDetailHeaderView

- (instancetype)initWithAvatarWH:(CGFloat)avatarWH {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _avatarWH = avatarWH;
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _avatarWH = 60.0;
    [self commonUI];
  }
  return self;
}

- (void)commonUI {
  self.backgroundColor = UIColor.whiteColor;
  [self addSubview:self.teamHeaderView];
  [self addSubview:self.teamNameLabel];
  [self addSubview:self.teamIdLabel];
  [self addSubview:self.lineView];

  [NSLayoutConstraint activateConstraints:@[
    [self.teamHeaderView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.teamHeaderView.widthAnchor constraintEqualToConstant:self.avatarWH],
    [self.teamHeaderView.heightAnchor constraintEqualToConstant:self.avatarWH],
    [self.teamHeaderView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.lineView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.lineView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.lineView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.lineView.heightAnchor constraintEqualToConstant:1.0],
  ]];

  [self commonUIWithShowOwner:NO];
}

- (void)commonUIWithShowOwner:(BOOL)showOwner {
  [NSLayoutConstraint deactivateConstraints:self.labelConstraints];
  [self.labelConstraints removeAllObjects];

  if (showOwner) {
    if (!self.teamOwnerLabel.superview) {
      [self addSubview:self.teamOwnerLabel];
    }
    [self.labelConstraints addObjectsFromArray:@[
      [self.teamNameLabel.leftAnchor constraintEqualToAnchor:self.teamHeaderView.rightAnchor constant:20.0],
      [self.teamNameLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor],
      [self.teamNameLabel.topAnchor constraintEqualToAnchor:self.teamHeaderView.topAnchor constant:-2.0],
      [self.teamNameLabel.heightAnchor constraintEqualToConstant:22.0],
      [self.teamIdLabel.leftAnchor constraintEqualToAnchor:self.teamNameLabel.leftAnchor],
      [self.teamIdLabel.rightAnchor constraintEqualToAnchor:self.teamNameLabel.rightAnchor],
      [self.teamIdLabel.topAnchor constraintEqualToAnchor:self.teamNameLabel.bottomAnchor constant:6.0],
      [self.teamIdLabel.heightAnchor constraintEqualToConstant:16.0],
      [self.teamOwnerLabel.leftAnchor constraintEqualToAnchor:self.teamNameLabel.leftAnchor],
      [self.teamOwnerLabel.rightAnchor constraintEqualToAnchor:self.teamNameLabel.rightAnchor],
      [self.teamOwnerLabel.topAnchor constraintEqualToAnchor:self.teamIdLabel.bottomAnchor],
      [self.teamOwnerLabel.heightAnchor constraintEqualToConstant:16.0],
    ]];
  } else {
    [self.teamOwnerLabel removeFromSuperview];
    [self.labelConstraints addObjectsFromArray:@[
      [self.teamNameLabel.leftAnchor constraintEqualToAnchor:self.teamHeaderView.rightAnchor constant:16.0],
      [self.teamNameLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20.0],
      [self.teamNameLabel.topAnchor constraintEqualToAnchor:self.teamHeaderView.topAnchor],
      [self.teamNameLabel.heightAnchor constraintEqualToConstant:22.0],
      [self.teamIdLabel.leftAnchor constraintEqualToAnchor:self.teamNameLabel.leftAnchor],
      [self.teamIdLabel.rightAnchor constraintEqualToAnchor:self.teamNameLabel.rightAnchor],
      [self.teamIdLabel.bottomAnchor constraintEqualToAnchor:self.teamHeaderView.bottomAnchor constant:-2.0],
      [self.teamIdLabel.heightAnchor constraintEqualToConstant:16.0],
    ]];
  }

  [NSLayoutConstraint activateConstraints:self.labelConstraints];
  [self updateConstraintsIfNeeded];
}

- (void)resetAvatarWH:(CGFloat)wh {
  [self updateLayoutConstraintFirstItem:self.teamHeaderView secondItem:self.teamHeaderView attribute:NSLayoutAttributeWidth constant:wh];
  [self updateLayoutConstraintFirstItem:self.teamHeaderView secondItem:self.teamHeaderView attribute:NSLayoutAttributeHeight constant:wh];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
  self.teamHeaderView.layer.cornerRadius = cornerRadius;
}

- (void)setData:(V2NIMTeam *)team showOwner:(BOOL)showOwner {
  NSString *url = team.avatar;
  NSString *name = team.name ?: @"";
  NSString *teamId = team.teamId ?: @"";

  [self.teamHeaderView configHeadData:url name:name uid:teamId];
  [self commonUIWithShowOwner:showOwner];
  self.teamNameLabel.text = name;
  self.teamIdLabel.text = [NSString stringWithFormat:@"%@: %@", NETeamUIKitLocalizable(@"team_id"), teamId];
  self.teamIdLabel.copyString = teamId;

  if (showOwner) {
    __weak typeof(self) weakSelf = self;
    [self getOwnerName:team completion:^(NSString *ownerName) {
      weakSelf.teamOwnerLabel.text = [NSString stringWithFormat:@"%@: %@", NETeamUIKitLocalizable(@"team_owner"), ownerName ?: @""];
      weakSelf.teamOwnerLabel.copyString = ownerName;
    }];
  }
}

- (void)getOwnerName:(V2NIMTeam *)team completion:(void (^)(NSString *))completion {
  NSString *teamId = team.teamId ?: @"";
  NSString *ownerAccountId = team.ownerAccountId ?: @"";
  if (teamId.length == 0 || ownerAccountId.length == 0) {
    if (completion) {
      completion(ownerAccountId);
    }
    return;
  }

  __block NSString *ownerName = ownerAccountId;
  [[TeamRepo shared] getTeamMember:teamId teamType:V2NIM_TEAM_TYPE_NORMAL accId:ownerAccountId completion:^(V2NIMTeamMember * _Nullable member, NSError * _Nullable error) {
    if (error) {
      [NEALog errorLog:[self.class className] desc:[NSString stringWithFormat:@"%@ getTeamMember %@ error: %@", NSStringFromSelector(_cmd), ownerAccountId, error.localizedDescription ?: @""]];
      if (completion) {
        completion(ownerName);
      }
      return;
    }

    NEUserWithFriend *friend = [[NEFriendUserCache shared] getFriendInfo:ownerAccountId];
    if (friend) {
      ownerName = [friend showName] ?: ownerAccountId;
      if (completion) {
        completion(ownerName);
      }
      return;
    }

    if (member.teamNick.length > 0) {
      ownerName = member.teamNick;
      if (completion) {
        completion(ownerName);
      }
      return;
    }

    [[ContactRepo shared] getUserListFromCloud:@[ ownerAccountId ] completion:^(NSArray<NEUserWithFriend *> * _Nullable users, NSError * _Nullable loadError) {
      if (users.firstObject) {
        ownerName = [users.firstObject showName] ?: ownerAccountId;
      }
      if (loadError) {
        [NEALog errorLog:[self.class className] desc:[NSString stringWithFormat:@"%@ getUserListFromCloud %@ error: %@", NSStringFromSelector(_cmd), ownerAccountId, loadError.localizedDescription ?: @""]];
      }
      if (completion) {
        completion(ownerName);
      }
    }];
  }];
}

- (NSMutableArray<NSLayoutConstraint *> *)labelConstraints {
  if (!_labelConstraints) {
    _labelConstraints = [NSMutableArray array];
  }
  return _labelConstraints;
}

- (NEUserHeaderView *)teamHeaderView {
  if (!_teamHeaderView) {
    _teamHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _teamHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _teamHeaderView.clipsToBounds = YES;
    _teamHeaderView.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _teamHeaderView.userInteractionEnabled = YES;
  }
  return _teamHeaderView;
}

- (CopyableLabel *)teamNameLabel {
  if (!_teamNameLabel) {
    _teamNameLabel = [[CopyableLabel alloc] init];
    _teamNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _teamNameLabel.font = [UIFont boldSystemFontOfSize:22.0];
    _teamNameLabel.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    _teamNameLabel.accessibilityIdentifier = @"id.teamName";
  }
  return _teamNameLabel;
}

- (CopyableLabel *)teamIdLabel {
  if (!_teamIdLabel) {
    _teamIdLabel = [[CopyableLabel alloc] init];
    _teamIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _teamIdLabel.font = [UIFont systemFontOfSize:16.0];
    _teamIdLabel.textColor = UIColor.ne_greyText;
    _teamIdLabel.accessibilityIdentifier = @"id.teamId";
  }
  return _teamIdLabel;
}

- (CopyableLabel *)teamOwnerLabel {
  if (!_teamOwnerLabel) {
    _teamOwnerLabel = [[CopyableLabel alloc] init];
    _teamOwnerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _teamOwnerLabel.font = [UIFont systemFontOfSize:16.0];
    _teamOwnerLabel.textColor = UIColor.ne_greyText;
    _teamOwnerLabel.accessibilityIdentifier = @"id.teamOwner";
  }
  return _teamOwnerLabel;
}

- (UIView *)lineView {
  if (!_lineView) {
    _lineView = [[UIView alloc] init];
    _lineView.translatesAutoresizingMaskIntoConstraints = NO;
    _lineView.backgroundColor = UIColor.ne_greyLine;
  }
  return _lineView;
}

@end
