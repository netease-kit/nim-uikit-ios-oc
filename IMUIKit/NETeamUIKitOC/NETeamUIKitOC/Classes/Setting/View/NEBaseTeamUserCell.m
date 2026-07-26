// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamUserCell.h"
#import <NEChatKit/NEConstant.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEChatKit/NEUserWithFriend.h>
#import <NIMSDK/V2NIMUserServiceProtocol.h>

@implementation NEBaseTeamUserCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setUser:(NETeamMemberInfoModel *)user {
  _user = user;
  NSString *userId = user.nimUser.user.accountId ?: @"";
  if (userId.length == 0) {
    return;
  }

  NEUserWithFriend *friendUser = [[NEFriendUserCache shared] getFriendInfo:userId];
  NSString *name = [user getShortName:[user showNickInTeam] ?: @"" length:2] ?: @"";
  if (friendUser) {
    [self.userHeaderView configHeadData:friendUser.user.avatar name:name uid:friendUser.user.accountId ?: @""];
  } else {
    [self.userHeaderView configHeadData:user.nimUser.user.avatar name:name uid:user.nimUser.user.accountId ?: @""];
  }
}

- (void)setupUI {
  [self.contentView addSubview:self.userHeaderView];
}

- (NEUserHeaderView *)userHeaderView {
  if (!_userHeaderView) {
    _userHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _userHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _userHeaderView.titleLabel.font = [NEConstant defaultTextFont:11.0];
    _userHeaderView.clipsToBounds = YES;
  }
  return _userHeaderView;
}

@end
