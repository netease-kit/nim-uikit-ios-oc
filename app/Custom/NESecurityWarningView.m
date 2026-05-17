// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NESecurityWarningView.h"
#import "AppKey.h"

static UIColor *SecurityWarningColor(NSUInteger hex) {
  return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                         green:((hex >> 8) & 0xFF) / 255.0
                          blue:(hex & 0xFF) / 255.0
                         alpha:1.0];
}

@implementation NESecurityWarningView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self addSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.backView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
  ]];
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = SecurityWarningColor(0xFFF5E1);
    [_backView addSubview:self.warningLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.warningLabel.topAnchor constraintEqualToAnchor:_backView.topAnchor constant:8],
      [self.warningLabel.bottomAnchor constraintEqualToAnchor:_backView.bottomAnchor constant:-8],
      [self.warningLabel.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
      [self.warningLabel.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-16],
    ]];
  }
  return _backView;
}

- (UILabel *)warningLabel {
  if (!_warningLabel) {
    _warningLabel = [[UILabel alloc] init];
    _warningLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _warningLabel.textColor = SecurityWarningColor(0xEB9718);
    _warningLabel.font = [UIFont systemFontOfSize:14];
    _warningLabel.text = NELocalizable(@"security_warning");
    _warningLabel.textAlignment = NSTextAlignmentJustified;
    _warningLabel.numberOfLines = 0;
    _warningLabel.accessibilityIdentifier = @"id.securityWarning";
  }
  return _warningLabel;
}

@end
