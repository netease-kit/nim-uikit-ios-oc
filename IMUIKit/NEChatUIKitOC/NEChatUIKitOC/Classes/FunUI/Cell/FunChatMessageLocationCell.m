// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageLocationCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageLocationModel.h"
#import "NEChatUIConstant.h"

@implementation FunChatMessageLocationCell

- (void)commonUILeft {
    [super commonUILeft];
    self.bubbleImageLeft.hidden = YES;
    [self.contentView addSubview:self.backgroundViewLeft];

    UILongPressGestureRecognizer *messageLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.backgroundViewLeft addGestureRecognizer:messageLongPress];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor],
        [self.backgroundViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.backgroundViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor],
        [self.backgroundViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor],
    ]];

    UITapGestureRecognizer *messageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    messageTap.cancelsTouchesInView = YES;
    [self.backgroundViewLeft addGestureRecognizer:messageTap];

    [self.backgroundViewLeft addSubview:self.titleLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft.leftAnchor constraintEqualToAnchor:self.backgroundViewLeft.leftAnchor constant:16],
        [self.titleLabelLeft.rightAnchor constraintEqualToAnchor:self.backgroundViewLeft.rightAnchor constant:-16],
        [self.titleLabelLeft.topAnchor constraintEqualToAnchor:self.backgroundViewLeft.topAnchor constant:10],
    ]];

    [self.backgroundViewLeft addSubview:self.subTitleLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.subTitleLabelLeft.leftAnchor constraintEqualToAnchor:self.titleLabelLeft.leftAnchor],
        [self.subTitleLabelLeft.rightAnchor constraintEqualToAnchor:self.titleLabelLeft.rightAnchor],
        [self.subTitleLabelLeft.topAnchor constraintEqualToAnchor:self.titleLabelLeft.bottomAnchor constant:4],
    ]];

    [self.backgroundViewLeft addSubview:self.mapImageViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapImageViewLeft.leftAnchor constraintEqualToAnchor:self.backgroundViewLeft.leftAnchor],
        [self.mapImageViewLeft.bottomAnchor constraintEqualToAnchor:self.backgroundViewLeft.bottomAnchor],
        [self.mapImageViewLeft.rightAnchor constraintEqualToAnchor:self.backgroundViewLeft.rightAnchor],
        [self.mapImageViewLeft.heightAnchor constraintEqualToConstant:86],
    ]];

    [self.mapImageViewLeft addSubview:self.pointImageLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.pointImageLeft.centerXAnchor constraintEqualToAnchor:self.mapImageViewLeft.centerXAnchor],
        [self.pointImageLeft.bottomAnchor constraintEqualToAnchor:self.mapImageViewLeft.bottomAnchor constant:-30],
    ]];

    [self.backgroundViewLeft addSubview:self.emptyLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabelLeft.leftAnchor constraintEqualToAnchor:self.backgroundViewLeft.leftAnchor],
        [self.emptyLabelLeft.rightAnchor constraintEqualToAnchor:self.backgroundViewLeft.rightAnchor],
        [self.emptyLabelLeft.bottomAnchor constraintEqualToAnchor:self.backgroundViewLeft.bottomAnchor constant:-40],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    self.bubbleImageRight.hidden = YES;
    [self.contentView addSubview:self.backgroundViewRight];

    UILongPressGestureRecognizer *messageLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.backgroundViewRight addGestureRecognizer:messageLongPress];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor],
        [self.backgroundViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor],
        [self.backgroundViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor],
        [self.backgroundViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor],
    ]];

    UITapGestureRecognizer *messageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    messageTap.cancelsTouchesInView = YES;
    [self.backgroundViewRight addGestureRecognizer:messageTap];

    [self.backgroundViewRight addSubview:self.titleLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelRight.leftAnchor constraintEqualToAnchor:self.backgroundViewRight.leftAnchor constant:16],
        [self.titleLabelRight.rightAnchor constraintEqualToAnchor:self.backgroundViewRight.rightAnchor constant:-16],
        [self.titleLabelRight.topAnchor constraintEqualToAnchor:self.backgroundViewRight.topAnchor constant:10],
    ]];

    [self.backgroundViewRight addSubview:self.subTitleLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.subTitleLabelRight.leftAnchor constraintEqualToAnchor:self.titleLabelRight.leftAnchor],
        [self.subTitleLabelRight.rightAnchor constraintEqualToAnchor:self.titleLabelRight.rightAnchor],
        [self.subTitleLabelRight.topAnchor constraintEqualToAnchor:self.titleLabelRight.bottomAnchor constant:4],
    ]];

    [self.backgroundViewRight addSubview:self.mapImageViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapImageViewRight.leftAnchor constraintEqualToAnchor:self.backgroundViewRight.leftAnchor],
        [self.mapImageViewRight.bottomAnchor constraintEqualToAnchor:self.backgroundViewRight.bottomAnchor],
        [self.mapImageViewRight.rightAnchor constraintEqualToAnchor:self.backgroundViewRight.rightAnchor],
        [self.mapImageViewRight.heightAnchor constraintEqualToConstant:86],
    ]];

    [self.mapImageViewRight addSubview:self.pointImageRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.pointImageRight.centerXAnchor constraintEqualToAnchor:self.mapImageViewRight.centerXAnchor],
        [self.pointImageRight.bottomAnchor constraintEqualToAnchor:self.mapImageViewRight.bottomAnchor constant:-30],
    ]];

    [self.backgroundViewRight addSubview:self.emptyLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabelRight.leftAnchor constraintEqualToAnchor:self.backgroundViewRight.leftAnchor],
        [self.emptyLabelRight.rightAnchor constraintEqualToAnchor:self.backgroundViewRight.rightAnchor],
        [self.emptyLabelRight.bottomAnchor constraintEqualToAnchor:self.backgroundViewRight.bottomAnchor constant:-40],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.backgroundViewLeft.hidden = showRight;
    self.backgroundViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UILabel *titleLabel = isSend ? self.titleLabelRight : self.titleLabelLeft;
    UILabel *subTitleLabel = isSend ? self.subTitleLabelRight : self.subTitleLabelLeft;
    UIImageView *mapImageView = isSend ? self.mapImageViewRight : self.mapImageViewLeft;
    UILabel *emptyLabel = isSend ? self.emptyLabelRight : self.emptyLabelLeft;
    UIImageView *pointImage = isSend ? self.pointImageRight : self.pointImageLeft;

    if ([model isKindOfClass:[MessageLocationModel class]]) {
        MessageLocationModel *m = (MessageLocationModel *)model;
        titleLabel.text = m.title;
        subTitleLabel.text = m.subTitle;
        if (m.lat && m.lng) {
            NSString *mapUrl = nil;
            if ([[NEChatKitClient instance].delegate respondsToSelector:@selector(getMapImageUrl:lng:)]) {
                mapUrl = [[NEChatKitClient instance].delegate getMapImageUrl:m.lat.doubleValue lng:m.lng.doubleValue];
            }
            if (mapUrl) {
                [mapImageView sd_setImageWithURL:[NSURL URLWithString:mapUrl]
                               placeholderImage:[UIImage ne_imageNamed:@"map_placeholder_image"]
                                        options:SDWebImageRetryFailed];
                emptyLabel.hidden = YES;
                pointImage.hidden = NO;
            } else {
                mapImageView.image = [UIImage ne_imageNamed:@"map_placeholder_image"];
                emptyLabel.hidden = NO;
                pointImage.hidden = YES;
            }
        }
    }
}

#pragma mark - Lazy Load

- (UILabel *)titleLabelLeft {
    if (!_titleLabelLeft) {
        _titleLabelLeft = [[UILabel alloc] init];
        _titleLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft.textColor = [UIColor ne_darkText];
        _titleLabelLeft.font = [UIFont systemFontOfSize:16.0];
        _titleLabelLeft.accessibilityIdentifier = @"id.locationItemTitle";
    }
    return _titleLabelLeft;
}

- (UILabel *)subTitleLabelLeft {
    if (!_subTitleLabelLeft) {
        _subTitleLabelLeft = [[UILabel alloc] init];
        _subTitleLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _subTitleLabelLeft.textColor = [UIColor ne_lightText];
        _subTitleLabelLeft.font = [UIFont systemFontOfSize:12.0];
        _subTitleLabelLeft.accessibilityIdentifier = @"id.locationItemAddress";
    }
    return _subTitleLabelLeft;
}

- (UILabel *)emptyLabelLeft {
    if (!_emptyLabelLeft) {
        _emptyLabelLeft = [[UILabel alloc] init];
        _emptyLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _emptyLabelLeft.font = [UIFont systemFontOfSize:16];
        _emptyLabelLeft.text = chatLocalizable(@"no_map_plugin");
        _emptyLabelLeft.textAlignment = NSTextAlignmentCenter;
        _emptyLabelLeft.textColor = [UIColor ne_greyText];
    }
    return _emptyLabelLeft;
}

- (UIImageView *)mapImageViewLeft {
    if (!_mapImageViewLeft) {
        _mapImageViewLeft = [[UIImageView alloc] init];
        _mapImageViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _mapImageViewLeft.contentMode = UIViewContentModeScaleAspectFill;
        _mapImageViewLeft.clipsToBounds = YES;
    }
    return _mapImageViewLeft;
}

- (UIView *)backgroundViewLeft {
    if (!_backgroundViewLeft) {
        _backgroundViewLeft = [[UIView alloc] init];
        _backgroundViewLeft.backgroundColor = [UIColor whiteColor];
        _backgroundViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundViewLeft.clipsToBounds = YES;
        _backgroundViewLeft.layer.cornerRadius = 4;
        _backgroundViewLeft.layer.borderWidth = 1;
        _backgroundViewLeft.layer.borderColor = [UIColor ne_outlineColor].CGColor;
        _backgroundViewLeft.accessibilityIdentifier = @"id.mapView";
    }
    return _backgroundViewLeft;
}

- (UIImageView *)pointImageLeft {
    if (!_pointImageLeft) {
        _pointImageLeft = [[UIImageView alloc] init];
        _pointImageLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _pointImageLeft.image = chatLoadImage(@"location_point");
    }
    return _pointImageLeft;
}

- (UILabel *)titleLabelRight {
    if (!_titleLabelRight) {
        _titleLabelRight = [[UILabel alloc] init];
        _titleLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelRight.textColor = [UIColor ne_darkText];
        _titleLabelRight.font = [UIFont systemFontOfSize:16.0];
        _titleLabelRight.accessibilityIdentifier = @"id.locationItemTitle";
    }
    return _titleLabelRight;
}

- (UILabel *)subTitleLabelRight {
    if (!_subTitleLabelRight) {
        _subTitleLabelRight = [[UILabel alloc] init];
        _subTitleLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _subTitleLabelRight.textColor = [UIColor ne_lightText];
        _subTitleLabelRight.font = [UIFont systemFontOfSize:12.0];
        _subTitleLabelRight.accessibilityIdentifier = @"id.locationItemAddress";
    }
    return _subTitleLabelRight;
}

- (UILabel *)emptyLabelRight {
    if (!_emptyLabelRight) {
        _emptyLabelRight = [[UILabel alloc] init];
        _emptyLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _emptyLabelRight.font = [UIFont systemFontOfSize:16];
        _emptyLabelRight.text = chatLocalizable(@"no_map_plugin");
        _emptyLabelRight.textAlignment = NSTextAlignmentCenter;
        _emptyLabelRight.textColor = [UIColor ne_greyText];
    }
    return _emptyLabelRight;
}

- (UIImageView *)mapImageViewRight {
    if (!_mapImageViewRight) {
        _mapImageViewRight = [[UIImageView alloc] init];
        _mapImageViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _mapImageViewRight.contentMode = UIViewContentModeScaleAspectFill;
        _mapImageViewRight.clipsToBounds = YES;
    }
    return _mapImageViewRight;
}

- (UIView *)backgroundViewRight {
    if (!_backgroundViewRight) {
        _backgroundViewRight = [[UIView alloc] init];
        _backgroundViewRight.backgroundColor = [UIColor whiteColor];
        _backgroundViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundViewRight.clipsToBounds = YES;
        _backgroundViewRight.layer.cornerRadius = 4;
        _backgroundViewRight.layer.borderWidth = 1;
        _backgroundViewRight.layer.borderColor = [UIColor ne_outlineColor].CGColor;
        _backgroundViewRight.accessibilityIdentifier = @"id.mapView";
    }
    return _backgroundViewRight;
}

- (UIImageView *)pointImageRight {
    if (!_pointImageRight) {
        _pointImageRight = [[UIImageView alloc] init];
        _pointImageRight.translatesAutoresizingMaskIntoConstraints = NO;
        _pointImageRight.image = chatLoadImage(@"location_point");
    }
    return _pointImageRight;
}

@end
