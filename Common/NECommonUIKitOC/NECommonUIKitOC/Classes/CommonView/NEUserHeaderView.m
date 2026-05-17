// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUserHeaderView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation NEUserHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.accessibilityIdentifier = @"id.avatar";
  self.contentMode = UIViewContentModeScaleAspectFill;
  self.userInteractionEnabled = YES;
  self.clipsToBounds = YES;
  self.backgroundColor = [UIColor clearColor];

  [self addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:2],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-2],
  ]];
}

- (void)configHeadData:(NSString *)headUrl name:(NSString *)name uid:(NSString *)uid {
  headUrl = [headUrl isKindOfClass:[NSString class]] ? headUrl : nil;
  name = [name isKindOfClass:[NSString class]] ? name : @"";
  uid = [uid isKindOfClass:[NSString class]] ? uid : @"";
  if (headUrl.length > 0) {
    [self setTitle:@""];
    [self sd_setImageWithURL:[NSURL URLWithString:headUrl] completed:nil];
    self.backgroundColor = [UIColor clearColor];
  } else {
    NSString *display = name.length > 0 ? name : uid;
    [self setTitle:display];
    [self sd_setImageWithURL:nil completed:nil];
    self.backgroundColor = [NEUserHeaderView colorWithUid:uid];
  }
}

- (void)setTitle:(NSString *)name {
  if (name.length == 0) {
    self.titleLabel.text = @"";
    return;
  }
  // 截取后两位，对齐 Swift: name[name.index(name.endIndex, offsetBy: -2)...]
  if (name.length > 2) {
    self.titleLabel.text = [name substringFromIndex:name.length - 2];
  } else {
    self.titleLabel.text = name;
  }
}

#pragma mark - 背景色：对齐 Swift UIColor.colorWithString(string: uid)

+ (UIColor *)colorWithUid:(NSString *)uid {
  uint64_t lastAscii = 0;
  if (uid.length > 0) {
    unichar last = [uid characterAtIndex:uid.length - 1];
    lastAscii = (uint64_t)last;
  }
  return [NEUserHeaderView colorWithNumber:lastAscii % 7];
}

+ (UIColor *)colorWithNumber:(uint64_t)mod {
  switch (mod) {
    case 0: return [UIColor colorWithRed:0.376 green:0.812 blue:0.655 alpha:1.0]; // #60CFA7
    case 1: return [UIColor colorWithRed:0.325 green:0.765 blue:0.953 alpha:1.0]; // #53C3F3
    case 2: return [UIColor colorWithRed:0.325 green:0.498 blue:0.957 alpha:1.0]; // #537FF4
    case 3: return [UIColor colorWithRed:0.522 green:0.310 blue:0.886 alpha:1.0]; // #854FE2
    case 4: return [UIColor colorWithRed:0.745 green:0.396 blue:0.851 alpha:1.0]; // #BE65D9
    case 5: return [UIColor colorWithRed:0.914 green:0.455 blue:0.616 alpha:1.0]; // #E9749D
    default: return [UIColor colorWithRed:0.976 green:0.718 blue:0.318 alpha:1.0]; // #F9B751
  }
}

#pragma mark - Lazy

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:14];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.accessibilityIdentifier = @"id.noAvatar";
  }
  return _titleLabel;
}

@end
