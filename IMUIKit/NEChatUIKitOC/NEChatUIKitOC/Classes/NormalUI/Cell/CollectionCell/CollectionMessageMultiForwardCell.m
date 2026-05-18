// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CollectionMessageMultiForwardCell.h"

@implementation CollectionMessageMultiForwardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupCommonUI {
    [super setupCommonUI];
    const CGFloat contentWidth = 248;
    [self.backImageViewLeft addSubview:self.titleLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft1.leftAnchor constraintEqualToAnchor:self.backImageViewLeft.leftAnchor constant:16],
        [self.titleLabelLeft1.rightAnchor constraintLessThanOrEqualToAnchor:self.backImageViewLeft.rightAnchor constant:-84],
        [self.titleLabelLeft1.topAnchor constraintEqualToAnchor:self.backImageViewLeft.topAnchor constant:10],
        [self.titleLabelLeft1.heightAnchor constraintEqualToConstant:22],
    ]];

    [self.backImageViewLeft addSubview:self.titleLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft2.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.rightAnchor],
        [self.titleLabelLeft2.centerYAnchor constraintEqualToAnchor:self.titleLabelLeft1.centerYAnchor],
        [self.titleLabelLeft2.heightAnchor constraintEqualToConstant:22],
        [self.titleLabelLeft2.widthAnchor constraintEqualToConstant:74],
    ]];

    [self.backImageViewLeft addSubview:self.contentLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft1.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.leftAnchor],
        [self.contentLabelLeft1.topAnchor constraintEqualToAnchor:self.titleLabelLeft1.bottomAnchor constant:2],
        [self.contentLabelLeft1.widthAnchor constraintEqualToConstant:contentWidth],
        [self.contentLabelLeft1.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backImageViewLeft addSubview:self.contentLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft2.leftAnchor constraintEqualToAnchor:self.contentLabelLeft1.leftAnchor],
        [self.contentLabelLeft2.topAnchor constraintEqualToAnchor:self.contentLabelLeft1.bottomAnchor],
        [self.contentLabelLeft2.widthAnchor constraintEqualToConstant:contentWidth],
        [self.contentLabelLeft2.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backImageViewLeft addSubview:self.contentLabelLeft3];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft3.leftAnchor constraintEqualToAnchor:self.contentLabelLeft2.leftAnchor],
        [self.contentLabelLeft3.topAnchor constraintEqualToAnchor:self.contentLabelLeft2.bottomAnchor],
        [self.contentLabelLeft3.widthAnchor constraintEqualToConstant:contentWidth],
        [self.contentLabelLeft3.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];
}

@end
