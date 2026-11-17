// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEInputMoreCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "NEChatUIConstant.h"

@implementation NEInputMoreCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.userInteractionEnabled = YES;
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarImageView.accessibilityIdentifier = @"id.actionIcon";
    }
    return _avatarImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = UIColor.ne_greyText;
        _titleLabel.font = [UIFont systemFontOfSize:10];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.accessibilityIdentifier = @"id.menuIcon";
    }
    return _titleLabel;
}

- (void)setupViews {
    CGSize imageSize = NEMoreCell_Image_Size();
    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.titleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:imageSize.width],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:imageSize.height],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor],
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [self.titleLabel.heightAnchor constraintEqualToConstant:NEMoreCell_Title_Height],
    ]];
}

- (void)config:(NEMoreItemModel *)itemModel {
    self.cellData = itemModel;
    self.avatarImageView.image = itemModel.customImage ?: itemModel.image;
    self.titleLabel.text = itemModel.title;
}

+ (CGSize)getSize {
    CGSize imageSize = NEMoreCell_Image_Size();
    return CGSizeMake(imageSize.width, imageSize.height + NEMoreCell_Title_Height);
}

@end
