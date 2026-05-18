// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ReplyView.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation ReplyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = HexRGB(0xF2F4F5);

        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[coreLoader() loadImage:@"remove"] forState:UIControlStateNormal];
        _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        _closeButton.accessibilityIdentifier = @"id.replyClose";
        [self addSubview:_closeButton];
        [NSLayoutConstraint activateConstraints:@[
            [_closeButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0],
            [_closeButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:0],
            [_closeButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0],
            [_closeButton.widthAnchor constraintEqualToConstant:34],
        ]];

        _line = [[UIView alloc] init];
        _line.backgroundColor = HexRGB(0xD8DAE4);
        _line.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_line];
        [NSLayoutConstraint activateConstraints:@[
            [_line.leadingAnchor constraintEqualToAnchor:_closeButton.trailingAnchor constant:-3],
            [_line.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [_line.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
            [_line.widthAnchor constraintEqualToConstant:1],
        ]];

        _textLabel = [[UILabel alloc] init];
        _textLabel.font = [UIFont systemFontOfSize:12];
        _textLabel.textColor = HexRGB(0x929299);
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _textLabel.accessibilityIdentifier = @"id.replyContent";
        [self addSubview:_textLabel];
        [NSLayoutConstraint activateConstraints:@[
            [_textLabel.leadingAnchor constraintEqualToAnchor:_closeButton.trailingAnchor constant:8],
            [_textLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [_textLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
            [_textLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        ]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

@end
