// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatTeamMemberCell.h"
#import <NEChatKitOC/NEConstant.h>

@implementation ChatTeamMemberCell

- (void)setupUI {
    [super setupUI];
    self.headerView.layer.cornerRadius = 21;
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21],
        [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.headerView.widthAnchor constraintEqualToConstant:42],
        [self.headerView.heightAnchor constraintEqualToConstant:42],
    ]];
    self.nameLabel.font = [NEConstant defaultTextFont:16.0];
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:14.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.nameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-70],
    ]];
}

@end
