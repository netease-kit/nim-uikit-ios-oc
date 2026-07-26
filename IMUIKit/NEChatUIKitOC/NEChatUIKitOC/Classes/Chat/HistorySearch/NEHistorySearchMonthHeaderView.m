// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistorySearchMonthHeaderView.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "FunChatUIColor.h"

@implementation NEHistorySearchMonthHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = UIColor.ne_lightText;
    }
    return _titleLabel;
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = UIColor.funChatLineBorderColor;
    }
    return _separatorView;
}

- (void)setupUI {
    for (UIView *item in @[self.separatorView, self.titleLabel]) {
        item.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:item];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.separatorView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:0.5],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
    ]];
}

- (void)configureWithTitle:(NSString *)title {
    self.titleLabel.text = title;
}

@end
