// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "OperationCell.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

static const CGFloat kOperationLabelHeight = 32.0;
static const CGFloat kOperationCellWidth = 50.0;
static const CGFloat kOperationDefaultFontSize = 14.0;
static const CGFloat kOperationMinimumFontSize = 9.0;
static const CGFloat kOperationMinimumScaleFactor = 0.8;

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
    [self configureLabelText];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if ([self class] == [OperationCell class]) [self configureLabelText];
}

- (void)configureLabelText {
    BOOL isPlugin = self.model.type == OperationTypePlugin;
    CGFloat baseFontSize = isPlugin ? 11.0 : kOperationDefaultFontSize;
    CGFloat minimumScaleFactor = isPlugin ? 0.65 : kOperationMinimumScaleFactor;
    UIFont *baseFont = [UIFont systemFontOfSize:baseFontSize];
    CGFloat availableWidth = CGRectGetWidth(self.contentView.bounds);
    if (availableWidth <= 0) availableWidth = kOperationCellWidth;
    CGFloat availableHeight = CGRectGetHeight(self.label.bounds);
    if (availableHeight <= 0) availableHeight = kOperationLabelHeight;
    NSString *text = self.label.text ?: @"";
    CGFloat textWidth = [text sizeWithAttributes:@{NSFontAttributeName: baseFont}].width;

    // Keep short titles in the existing two-line cell, but scale titles that
    // only miss the fixed column by a few points instead of clipping them.
    if ((isPlugin || textWidth > availableWidth) && textWidth * minimumScaleFactor <= availableWidth) {
        self.label.font = baseFont;
        self.label.numberOfLines = 1;
        self.label.adjustsFontSizeToFitWidth = YES;
        self.label.minimumScaleFactor = minimumScaleFactor;
        self.label.lineBreakMode = NSLineBreakByClipping;
        return;
    }

    CGFloat fontSize = baseFontSize;
    UILabel *measureLabel = [[UILabel alloc] init];
    measureLabel.text = text;
    measureLabel.numberOfLines = 0;
    measureLabel.lineBreakMode = NSLineBreakByCharWrapping;
    while (fontSize > kOperationMinimumFontSize) {
        measureLabel.font = [UIFont systemFontOfSize:fontSize];
        CGSize measuredSize = [measureLabel sizeThatFits:CGSizeMake(availableWidth, CGFLOAT_MAX)];
        if (measuredSize.height <= MIN(availableHeight, measureLabel.font.lineHeight * 2)) break;
        fontSize -= 0.5;
    }

    self.label.font = [UIFont systemFontOfSize:fontSize];
    self.label.numberOfLines = 2;
    self.label.adjustsFontSizeToFitWidth = NO;
    self.label.minimumScaleFactor = 1.0;
    self.label.lineBreakMode = NSLineBreakByCharWrapping;
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
        [self.imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
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

    self.label.numberOfLines = 2;
    self.label.lineBreakMode = NSLineBreakByCharWrapping;
    [NSLayoutConstraint activateConstraints:@[
        [self.label.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:2],
        [self.label.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0],
        [self.label.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
        [self.label.heightAnchor constraintEqualToConstant:kOperationLabelHeight],
    ]];
}

@end
