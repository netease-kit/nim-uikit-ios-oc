// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserBaseTableViewCell.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation UserBaseTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.whiteColor;
        [self baseCommonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

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

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.accessibilityIdentifier = @"id.nickname";
    }
    return _titleLabel;
}

- (void)baseCommonUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview:self.userHeaderView];
    [self.contentView addSubview:self.titleLabel];
}

- (void)setModel:(NETeamMemberInfoModel *)model {
    self.userModel = model;
    self.titleLabel.text = [model atNameInTeam];

    NSString *url = model.nimUser.user.avatar;
    NSString *name = [NEFriendUserCache getShortName:[model showNickInTeam] ?: @"" length:2];
    NSString *accountId = model.teamMember.accountId ?: @"";
    [self.userHeaderView configHeadData:url name:name uid:accountId];
}

@end
