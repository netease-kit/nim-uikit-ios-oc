// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatBrokenNetworkView.h"
#import "NEChatUIConstant.h"
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@implementation ChatBrokenNetworkView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.font = DefaultTextFont(14);
        _contentLabel.textColor = HexRGB(0xFC596A);
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.text = commonLocalizable(@"network_error");
    }
    return _contentLabel;
}

- (void)commonUI {
    self.backgroundColor = HexRGB(0xFEE3E6);
    [self addSubview:self.contentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:15],
        [self.contentLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.contentLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-15],
    ]];
}

@end
