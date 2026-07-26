// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ToastImageView.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>

@interface ToastImageView ()

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) UILabel *contentLabel;

@end

@implementation ToastImageView

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

- (void)setupUI {
  [self addSubview:self.imageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [self.imageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:36.0],
  ]];

  [self addSubview:self.contentLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:10.0],
    [self.contentLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10.0],
    [self.contentLabel.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:20.0],
  ]];

  self.backgroundColor = [NEConstant hexRGB:0x4C4C4C];
  self.clipsToBounds = YES;
  self.layer.cornerRadius = 8.0;
}

- (UIImageView *)imageView {
  if (!_imageView) {
    _imageView = [[UIImageView alloc] init];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView.image = [coreLoader() loadImage:@"white_right_img"];
  }
  return _imageView;
}

- (UILabel *)contentLabel {
  if (!_contentLabel) {
    _contentLabel = [[UILabel alloc] init];
    _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _contentLabel.font = [NEConstant defaultTextFont:14.0];
    _contentLabel.numberOfLines = 2;
    _contentLabel.textColor = UIColor.whiteColor;
    _contentLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _contentLabel;
}

@end
