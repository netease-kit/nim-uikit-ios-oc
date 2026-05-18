// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "LanguageCell.h"

@implementation LanguageCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupLanguageCellUI {
    [super setupLanguageCellUI];
    [self.contentView addSubview:self.languageLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.languageLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
        [self.languageLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
        [self.languageLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.languageLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
    [self.contentView addSubview:self.selectedImageView];
    [NSLayoutConstraint activateConstraints:@[
        [self.selectedImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
        [self.selectedImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.selectedImageView.widthAnchor constraintEqualToConstant:20],
        [self.selectedImageView.heightAnchor constraintEqualToConstant:16],
    ]];
}

@end
