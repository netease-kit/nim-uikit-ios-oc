// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunUserSettingSelectCell.h"
#import <NEBaseUIKitOC/UIView+YXToast.h>

@implementation FunUserSettingSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.edgeInset = UIEdgeInsetsZero;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeLeft constant:16];
    [self.contentView updateLayoutConstraintFirstItem:self.dividerLine secondItem:self.contentView attribute:NSLayoutAttributeRight constant:0];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-84],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    ]];
}

@end
