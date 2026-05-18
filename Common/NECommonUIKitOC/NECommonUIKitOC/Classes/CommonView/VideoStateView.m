// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "VideoStateView.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import "NECommonUIConstant.h"

@interface VideoStateView ()

@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UIImageView *videoPlayImageView;
@property (nonatomic, strong) UIView *alphaBackView;
@property (nonatomic, strong) UIView *verticalLineLeft;
@property (nonatomic, strong) UIView *verticalLineRight;

@end

@implementation VideoStateView

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
  [self addSubview:self.videoPlayImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.videoPlayImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [self.videoPlayImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.videoPlayImageView.widthAnchor constraintEqualToConstant:60.0],
    [self.videoPlayImageView.heightAnchor constraintEqualToConstant:60.0],
  ]];

  [self addSubview:self.alphaBackView];
  [NSLayoutConstraint activateConstraints:@[
    [self.alphaBackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [self.alphaBackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.alphaBackView.widthAnchor constraintEqualToConstant:42.0],
    [self.alphaBackView.heightAnchor constraintEqualToConstant:42.0],
  ]];

  [self addSubview:self.verticalLineLeft];
  [NSLayoutConstraint activateConstraints:@[
    [self.verticalLineLeft.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.verticalLineLeft.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:-4.5],
    [self.verticalLineLeft.heightAnchor constraintEqualToConstant:18.0],
    [self.verticalLineLeft.widthAnchor constraintEqualToConstant:3.0],
  ]];

  [self addSubview:self.verticalLineRight];
  [NSLayoutConstraint activateConstraints:@[
    [self.verticalLineRight.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.verticalLineRight.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:4.5],
    [self.verticalLineRight.heightAnchor constraintEqualToConstant:18.0],
    [self.verticalLineRight.widthAnchor constraintEqualToConstant:3.0],
  ]];

  [self.layer addSublayer:self.circleLayer];
  [self.layer addSublayer:self.progressLayer];

  self.state = VideoStateViewStateVideoPlay;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGPoint center = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) / 2.0);
  UIBezierPath *borderPath = [UIBezierPath bezierPathWithArcCenter:center
                                                            radius:21.0
                                                        startAngle:0
                                                          endAngle:(CGFloat)(2 * M_PI)
                                                         clockwise:YES];
  self.circleLayer.path = borderPath.CGPath;
  self.circleLayer.frame = self.bounds;
  self.progressLayer.frame = self.bounds;
}

- (void)setState:(VideoStateViewState)state {
  _state = state;
  switch (state) {
    case VideoStateViewStateVideoPlay:
      self.videoPlayImageView.hidden = NO;
      self.verticalLineLeft.hidden = YES;
      self.verticalLineRight.hidden = YES;
      self.circleLayer.hidden = YES;
      self.progressLayer.hidden = YES;
      self.alphaBackView.hidden = YES;
      break;
    case VideoStateViewStateVideoDownload:
      self.videoPlayImageView.hidden = YES;
      self.verticalLineLeft.hidden = NO;
      self.verticalLineRight.hidden = NO;
      self.circleLayer.hidden = NO;
      self.progressLayer.hidden = NO;
      self.alphaBackView.hidden = NO;
      break;
  }
}

- (void)setProgress:(float)progress {
  if (progress < 1.0f) {
    self.state = VideoStateViewStateVideoDownload;
  }

  CGPoint center = CGPointMake(CGRectGetWidth(self.frame) / 2.0, CGRectGetHeight(self.frame) / 2.0);
  CGFloat start = (CGFloat)(-0.5f * M_PI);
  CGFloat end = (CGFloat)(progress * 2.0f * (float)M_PI - 0.5f * (float)M_PI);
  UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:center
                                                              radius:21.0
                                                          startAngle:start
                                                            endAngle:end
                                                           clockwise:YES];
  self.progressLayer.path = progressPath.CGPath;
  self.progressLayer.strokeColor = UIColor.whiteColor.CGColor;
  self.progressLayer.fillColor = UIColor.clearColor.CGColor;
  self.progressLayer.lineWidth = 4.0;

  if (progress >= 1.0f) {
    self.state = VideoStateViewStateVideoPlay;
  }
}

- (CAShapeLayer *)circleLayer {
  if (!_circleLayer) {
    _circleLayer = [CAShapeLayer layer];
    _circleLayer.hidden = YES;
    _circleLayer.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:0.5].CGColor;
    _circleLayer.fillColor = UIColor.clearColor.CGColor;
    _circleLayer.lineWidth = 4.0;
  }
  return _circleLayer;
}

- (CAShapeLayer *)progressLayer {
  if (!_progressLayer) {
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.hidden = YES;
  }
  return _progressLayer;
}

- (UIImageView *)videoPlayImageView {
  if (!_videoPlayImageView) {
    _videoPlayImageView = [[UIImageView alloc] init];
    _videoPlayImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _videoPlayImageView.image = [coreLoader() loadImage:@"video_play"];
    _videoPlayImageView.accessibilityIdentifier = @"id.playIcon";
    _videoPlayImageView.hidden = NO;
  }
  return _videoPlayImageView;
}

- (UIView *)alphaBackView {
  if (!_alphaBackView) {
    _alphaBackView = [[UIView alloc] init];
    _alphaBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _alphaBackView.backgroundColor = [[NEConstant hexRGB:0x000000] colorWithAlphaComponent:0.2];
    _alphaBackView.clipsToBounds = YES;
    _alphaBackView.layer.cornerRadius = 21.0;
    _alphaBackView.hidden = YES;
  }
  return _alphaBackView;
}

- (UIView *)verticalLineLeft {
  if (!_verticalLineLeft) {
    _verticalLineLeft = [[UIView alloc] init];
    _verticalLineLeft.translatesAutoresizingMaskIntoConstraints = NO;
    _verticalLineLeft.backgroundColor = UIColor.whiteColor;
    _verticalLineLeft.clipsToBounds = YES;
    _verticalLineLeft.layer.cornerRadius = 1.5;
    _verticalLineLeft.hidden = YES;
  }
  return _verticalLineLeft;
}

- (UIView *)verticalLineRight {
  if (!_verticalLineRight) {
    _verticalLineRight = [[UIView alloc] init];
    _verticalLineRight.translatesAutoresizingMaskIntoConstraints = NO;
    _verticalLineRight.backgroundColor = UIColor.whiteColor;
    _verticalLineRight.clipsToBounds = YES;
    _verticalLineRight.layer.cornerRadius = 1.5;
    _verticalLineRight.hidden = YES;
  }
  return _verticalLineRight;
}

@end
