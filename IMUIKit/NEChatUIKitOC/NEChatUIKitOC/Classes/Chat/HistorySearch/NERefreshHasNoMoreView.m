// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NERefreshHasNoMoreView.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/UIColor+NECommon.h>

@implementation NERefreshHasNoMoreView

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

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _tipLabel.text = chatLocalizable(@"search_message_has_no_more");
        _tipLabel.textColor = UIColor.ne_emptyTitleColor;
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

- (void)setupUI {
    [self addSubview:self.tipLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.tipLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tipLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.tipLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.tipLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

@end
