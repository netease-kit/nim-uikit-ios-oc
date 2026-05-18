// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserSettingSwitchCell.h"

@implementation UserSettingSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupUI {
    [super setupUI];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.tSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.tSwitch.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
    ]];
}

@end
