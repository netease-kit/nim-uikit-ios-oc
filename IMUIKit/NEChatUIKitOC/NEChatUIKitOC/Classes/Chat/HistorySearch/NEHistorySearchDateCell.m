// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistorySearchDateCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NormalChatUIColor.h"

@implementation NEHistorySearchDateCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg;
    }
    return self;
}

- (UILabel *)dayLabel {
    if (!_dayLabel) {
        _dayLabel = [[UILabel alloc] init];
        _dayLabel.textAlignment = NSTextAlignmentCenter;
        _dayLabel.textColor = UIColor.ne_darkText;
        _dayLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    }
    return _dayLabel;
}

- (UILabel *)todayLabel {
    if (!_todayLabel) {
        _todayLabel = [[UILabel alloc] init];
        _todayLabel.text = commonLocalizable(@"weekday_today");
        _todayLabel.textAlignment = NSTextAlignmentCenter;
        _todayLabel.textColor = UIColor.ne_darkText;
        _todayLabel.font = [UIFont systemFontOfSize:10];
        _todayLabel.hidden = YES;
    }
    return _todayLabel;
}

- (UIView *)selectionView {
    if (!_selectionView) {
        _selectionView = [[UIView alloc] init];
        _selectionView.backgroundColor = self.selectButtonBackgroundColor;
        _selectionView.layer.cornerRadius = 20;
        _selectionView.hidden = YES;
    }
    return _selectionView;
}

- (void)setupUI {
    for (UIView *item in @[self.selectionView, self.dayLabel, self.todayLabel]) {
        item.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:item];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.selectionView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.selectionView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
        [self.selectionView.widthAnchor constraintEqualToConstant:40],
        [self.selectionView.heightAnchor constraintEqualToConstant:40],

        [self.dayLabel.centerXAnchor constraintEqualToAnchor:self.selectionView.centerXAnchor],
        [self.dayLabel.centerYAnchor constraintEqualToAnchor:self.selectionView.centerYAnchor],

        [self.todayLabel.topAnchor constraintEqualToAnchor:self.selectionView.bottomAnchor constant:2],
        [self.todayLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    ]];
}

- (void)configureWithDay:(nullable NSNumber *)day
                 isToday:(BOOL)isToday
              isSelected:(BOOL)isSelected
                isFuture:(BOOL)isFuture {
    if (day != nil) {
        self.dayLabel.text = [NSString stringWithFormat:@"%ld", (long)day.integerValue];
        self.dayLabel.hidden = NO;

        if (isFuture) {
            self.dayLabel.textColor = UIColor.clearColor;
            self.selectionView.hidden = YES;
            self.todayLabel.hidden = YES;
            self.userInteractionEnabled = NO;
        } else if (isSelected) {
            self.dayLabel.textColor = UIColor.whiteColor;
            self.selectionView.hidden = NO;
            self.selectionView.backgroundColor = self.selectButtonBackgroundColor;
            self.todayLabel.hidden = !isToday;
            self.todayLabel.textColor = self.selectButtonBackgroundColor;
            self.userInteractionEnabled = YES;
        } else {
            self.dayLabel.textColor = UIColor.blackColor;
            self.selectionView.hidden = YES;
            self.todayLabel.hidden = !isToday;
            self.todayLabel.textColor = UIColor.ne_darkText;
            self.userInteractionEnabled = YES;
        }
    } else {
        self.dayLabel.text = nil;
        self.dayLabel.hidden = YES;
        self.selectionView.hidden = YES;
        self.todayLabel.hidden = YES;
        self.userInteractionEnabled = NO;
    }
}

@end
