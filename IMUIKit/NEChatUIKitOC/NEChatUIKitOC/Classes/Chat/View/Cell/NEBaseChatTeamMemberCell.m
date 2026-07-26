// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatTeamMemberCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKit/NEConstant.h>
#import "ChatCellConstantValue.h"

@implementation NEBaseChatTeamMemberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (NEUserHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _headerView.titleLabel.font = [NEConstant defaultTextFont:14];
        _headerView.titleLabel.textColor = UIColor.whiteColor;
        _headerView.clipsToBounds = YES;
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
        _headerView.accessibilityIdentifier = @"id.atCellHeaderView";
    }
    return _headerView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.textColor = UIColor.ne_darkText;
        _nameLabel.accessibilityIdentifier = @"id.atCellName";
    }
    return _nameLabel;
}

- (void)setupUI {
    [self.contentView addSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21],
        [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.headerView.widthAnchor constraintEqualToConstant:fun_chat_min_h],
        [self.headerView.heightAnchor constraintEqualToConstant:fun_chat_min_h],
    ]];

    [self.contentView addSubview:self.nameLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:14.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.nameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-70],
    ]];
}

- (void)configure:(NETeamMemberInfoModel *)model {
    NSString *url = model.nimUser.user.avatar;
    NSString *name = [model getShortName:[model showNickInTeam] ?: @"" length:2];
    NSString *accountId = model.nimUser.user.accountId ?: @"";
    [self.headerView configHeadData:url name:name uid:accountId];
    self.nameLabel.text = [model atNameInTeam];
}

@end
