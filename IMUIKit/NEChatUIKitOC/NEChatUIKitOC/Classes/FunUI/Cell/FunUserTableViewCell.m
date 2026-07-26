// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunUserTableViewCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "FunChatUIColor.h"

@implementation FunUserTableViewCell

- (void)baseCommonUI {
    [super baseCommonUI];
    self.userHeaderView.layer.cornerRadius = 4;
    [NSLayoutConstraint activateConstraints:@[
        [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.userHeaderView.widthAnchor constraintEqualToConstant:40],
        [self.userHeaderView.heightAnchor constraintEqualToConstant:40],
        [self.userHeaderView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
    ]];

    self.titleLabel.textColor = [UIColor ne_darkText];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:11],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-29],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];

    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor funChatLineBorderColor];
    [self.contentView addSubview:line];
    [NSLayoutConstraint activateConstraints:@[
        [line.leftAnchor constraintEqualToAnchor:self.userHeaderView.leftAnchor],
        [line.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [line.heightAnchor constraintEqualToConstant:0.6],
        [line.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
}

@end
