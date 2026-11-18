// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserTableViewCell.h"

@implementation UserTableViewCell

- (void)baseCommonUI {
    [super baseCommonUI];
    self.userHeaderView.layer.cornerRadius = 21;
    [NSLayoutConstraint activateConstraints:@[
        [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.userHeaderView.widthAnchor constraintEqualToConstant:42],
        [self.userHeaderView.heightAnchor constraintEqualToConstant:42],
        [self.userHeaderView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
    ]];
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.textColor = [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-35],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
}

@end
