// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBrokenNetworkView.h"
#import "NECommonUIConstant.h"
#import <NEChatKitOC/NECommonLoader.h>

@implementation NEBrokenNetworkView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithRed:0xFE/255.0 green:0xE3/255.0 blue:0xE6/255.0 alpha:1];
    [self commonUI];
  }
  return self;
}

- (UIImageView *)errorIconView {
  if (!_errorIconView) {
    _errorIconView = [[UIImageView alloc] init];
    _errorIconView.translatesAutoresizingMaskIntoConstraints = NO;
    _errorIconView.image = [coreLoader() loadImage:@"error"];
    _errorIconView.hidden = YES;
  }
  return _errorIconView;
}

- (UILabel *)contentLabel {
  if (!_contentLabel) {
    _contentLabel = [[UILabel alloc] init];
    _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _contentLabel.font = [UIFont systemFontOfSize:14];
    _contentLabel.textColor = [UIColor colorWithRed:0xFC/255.0 green:0x59/255.0 blue:0x6A/255.0 alpha:1];
    _contentLabel.textAlignment = NSTextAlignmentLeft;
    _contentLabel.text = commonLocalizable(@"network_error");
  }
  return _contentLabel;
}

- (void)commonUI {
  [self addSubview:self.errorIconView];
  [NSLayoutConstraint activateConstraints:@[
    [self.errorIconView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:30],
    [self.errorIconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.errorIconView.widthAnchor constraintEqualToConstant:20],
    [self.errorIconView.heightAnchor constraintEqualToConstant:20],
  ]];

  [self addSubview:self.contentLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentLabel.leftAnchor constraintEqualToAnchor:self.errorIconView.rightAnchor constant:18],
    [self.contentLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.contentLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-15],
  ]];
}

@end
