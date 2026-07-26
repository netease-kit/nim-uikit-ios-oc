// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "OperationCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation OperationCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (void)setModel:(OperationItem *)model {
    _model = model;
    if (model.imageName.length > 0) {
        UIImage *image = [UIImage ne_imageNamed:model.imageName];
        if (image) {
            self.imageView.image = image;
        } else {
            self.imageView.image = model.image;
        }
    } else {
        self.imageView.image = model.image;
    }
    self.label.text = model.text;
}

- (void)commonUI {
    self.contentView.accessibilityIdentifier = @"id.menuCell";

    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.imageView];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.accessibilityIdentifier = @"id.menuIcon";
    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor constant:0],
        [self.imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.imageView.widthAnchor constraintEqualToConstant:18],
        [self.imageView.heightAnchor constraintEqualToConstant:18],
    ]];

    self.label = [[UILabel alloc] init];
    self.label.font = [UIFont systemFontOfSize:14];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.textColor = UIColor.ne_darkText;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 2;
    self.label.accessibilityIdentifier = @"id.menuTitle";
    [self.contentView addSubview:self.label];

    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    CGFloat topConstant = isEnglish ? 2 : 8;
    CGFloat heightConstant = isEnglish ? 36 : 18;
    [NSLayoutConstraint activateConstraints:@[
        [self.label.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:topConstant],
        [self.label.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0],
        [self.label.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
        [self.label.heightAnchor constraintEqualToConstant:heightConstant],
    ]];
}

@end
