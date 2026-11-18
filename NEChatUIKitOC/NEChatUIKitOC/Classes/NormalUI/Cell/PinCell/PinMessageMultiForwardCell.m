// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PinMessageMultiForwardCell.h"

@implementation PinMessageMultiForwardCell

- (void)setupUI {
    [super setupUI];
    [self.backViewLeft addSubview:self.titleLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft1.leftAnchor constraintEqualToAnchor:self.backViewLeft.leftAnchor constant:16],
        [self.titleLabelLeft1.rightAnchor constraintLessThanOrEqualToAnchor:self.backViewLeft.rightAnchor constant:-84],
        [self.titleLabelLeft1.topAnchor constraintEqualToAnchor:self.backViewLeft.topAnchor constant:10],
        [self.titleLabelLeft1.heightAnchor constraintEqualToConstant:22],
    ]];

    [self.backViewLeft addSubview:self.titleLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft2.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.rightAnchor],
        [self.titleLabelLeft2.centerYAnchor constraintEqualToAnchor:self.titleLabelLeft1.centerYAnchor],
        [self.titleLabelLeft2.heightAnchor constraintEqualToConstant:22],
        [self.titleLabelLeft2.widthAnchor constraintEqualToConstant:74],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft1.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.leftAnchor],
        [self.contentLabelLeft1.topAnchor constraintEqualToAnchor:self.titleLabelLeft1.bottomAnchor constant:2],
        [self.contentLabelLeft1.widthAnchor constraintEqualToConstant:248.0],
        [self.contentLabelLeft1.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft2.leftAnchor constraintEqualToAnchor:self.contentLabelLeft1.leftAnchor],
        [self.contentLabelLeft2.topAnchor constraintEqualToAnchor:self.contentLabelLeft1.bottomAnchor],
        [self.contentLabelLeft2.widthAnchor constraintEqualToConstant:248.0],
        [self.contentLabelLeft2.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft3];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft3.leftAnchor constraintEqualToAnchor:self.contentLabelLeft2.leftAnchor],
        [self.contentLabelLeft3.topAnchor constraintEqualToAnchor:self.contentLabelLeft2.bottomAnchor],
        [self.contentLabelLeft3.widthAnchor constraintEqualToConstant:248.0],
        [self.contentLabelLeft3.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];
}

@end
