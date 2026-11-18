// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactSectionView.h"
#import "ContactUIConfig.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation ContactSectionView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithReuseIdentifier:reuseIdentifier];
  if (self) {
    [self commonUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  self.backgroundColor = [UIColor clearColor];

  [self addSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0],
    [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.backView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0],
  ]];

  [self.backView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:20],
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
    [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:20],
  ]];

  [self.backView addSubview:self.line];
  [NSLayoutConstraint activateConstraints:@[
    [self.line.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.line.heightAnchor constraintEqualToConstant:1.0],
    [self.line.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor constant:0],
    [self.line.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor],
  ]];
}

#pragma mark - Lazy Init

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _backView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [ContactUIConfig shared].contactProperties.indexTitleColor ?: [UIColor colorWithRed:0.7 green:0.72 blue:0.74 alpha:1.0];
    _titleLabel.font = [UIFont systemFontOfSize:14.0];
  }
  return _titleLabel;
}

- (UIView *)line {
  if (!_line) {
    _line = [[UIView alloc] init];
    _line.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _line;
}

@end
