// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEEmptyDataView.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>

@interface NEEmptyDataView ()
@property (nonatomic, copy, nullable) NSString *imageName;
@property (nonatomic, strong, readwrite) UIImageView *emptyImageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong, readwrite, nullable) NSLayoutConstraint *widthConstraint;
@property (nonatomic, strong, readwrite, nullable) NSLayoutConstraint *heightConstraint;
@property (nonatomic, strong, readwrite, nullable) NSLayoutConstraint *imageTopConstraint;
@end

@implementation NEEmptyDataView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupSubviews];
    [self setupDefaultStyle];
  }
  return self;
}

- (instancetype)initWithImageName:(NSString *)imageName
                          content:(NSString *)content
                            frame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _imageName = [imageName copy];
    _message = [content copy];
    [self setupSubviews];
    [self setupDefaultStyle];
    [self setupSubviewStyle];
  }
  return self;
}

- (instancetype)initWithImage:(UIImage *)image
                      content:(NSString *)content
                        frame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _image = image;
    _message = [content copy];
    [self setupSubviews];
    [self setupDefaultStyle];
    [self setupSubviewStyle];
  }
  return self;
}

- (void)setupDefaultStyle {
  self.backgroundColor = UIColor.clearColor;
  _messageColor = UIColor.ne_emptyTitleColor;
  _messageFontSize = 14.0;
  self.messageLabel.textColor = _messageColor;
  self.messageLabel.font = [UIFont systemFontOfSize:_messageFontSize];
}

- (void)setupSubviews {
  _emptyImageView = [[UIImageView alloc] init];
  _emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
  _emptyImageView.accessibilityIdentifier = @"id.emptyImageView";
  [self addSubview:_emptyImageView];

  _messageLabel = [[UILabel alloc] init];
  _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _messageLabel.textAlignment = NSTextAlignmentCenter;
  _messageLabel.numberOfLines = 0;
  _messageLabel.accessibilityIdentifier = @"id.emptyContentLabel";
  [self addSubview:_messageLabel];

  _widthConstraint = [_emptyImageView.widthAnchor constraintEqualToConstant:122.0];
  _heightConstraint = [_emptyImageView.heightAnchor constraintEqualToConstant:91.0];
  _widthConstraint.active = YES;
  _heightConstraint.active = YES;

  _imageTopConstraint = [_emptyImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:176.0];
  _imageTopConstraint.active = YES;
  [_emptyImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [_messageLabel.topAnchor constraintEqualToAnchor:_emptyImageView.bottomAnchor constant:8.0],
    [_messageLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:20.0],
    [_messageLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20.0],
  ]];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (!self.verticallyCentersContent || CGRectGetHeight(self.bounds) <= 0 || !self.imageTopConstraint) {
    return;
  }
  CGFloat imageHeight = self.heightConstraint ? self.heightConstraint.constant : 91.0;
  CGFloat labelHeight = CGRectGetHeight(self.messageLabel.bounds);
  if (labelHeight <= 0) {
    CGFloat availableWidth = MAX(0, CGRectGetWidth(self.bounds) - 40.0);
    labelHeight = [self.messageLabel sizeThatFits:CGSizeMake(availableWidth, CGFLOAT_MAX)].height;
  }
  CGFloat contentHeight = imageHeight + 8.0 + MAX(0, labelHeight);
  CGFloat offset = MAX(0, (CGRectGetHeight(self.bounds) - contentHeight) / 2.0);
  if (fabs(self.imageTopConstraint.constant - offset) > 0.5) {
    self.imageTopConstraint.constant = offset;
  }
}

- (void)setVerticallyCentersContent:(BOOL)verticallyCentersContent {
  if (_verticallyCentersContent == verticallyCentersContent) {
    return;
  }
  _verticallyCentersContent = verticallyCentersContent;
  [self setNeedsLayout];
}

- (void)setupSubviewStyle {
  if (self.imageName.length > 0) {
    self.emptyImageView.image = [coreLoader() loadImage:self.imageName];
  } else {
    self.emptyImageView.image = self.image;
  }
  self.messageLabel.text = self.message;
}

- (void)setImage:(nullable UIImage *)image message:(nullable NSString *)message {
  [self setEmptyImage:image];
  [self setText:message];
}

- (void)setText:(nullable NSString *)text {
  self.message = text ?: @"";
}

- (void)setAttributedText:(NSAttributedString *)att {
  self.messageLabel.attributedText = att;
}

- (void)setEmptyImageName:(nullable NSString *)imageName {
  self.imageName = imageName;
  self.image = imageName.length > 0 ? [coreLoader() loadImage:imageName] : nil;
  self.emptyImageView.image = self.image;
}

- (void)setEmptyImageWithName:(nullable NSString *)imageName {
  [self setEmptyImageName:imageName];
}

- (void)setEmptyImageWithImage:(UIImage *)image {
  [self setEmptyImage:image];
}

- (void)setEmptyImage:(UIImage *)image {
  self.image = image;
}

- (void)setImage:(UIImage *)image {
  _image = image;
  _imageName = nil;
  _emptyImageView.image = image;
}

- (void)setMessage:(NSString *)message {
  _message = message;
  _messageLabel.text = message ?: @"";
}

- (void)setMessageColor:(UIColor *)messageColor {
  _messageColor = messageColor;
  _messageLabel.textColor = messageColor;
}

- (void)setMessageFontSize:(CGFloat)messageFontSize {
  _messageFontSize = messageFontSize;
  _messageLabel.font = [UIFont systemFontOfSize:messageFontSize];
}

@end
