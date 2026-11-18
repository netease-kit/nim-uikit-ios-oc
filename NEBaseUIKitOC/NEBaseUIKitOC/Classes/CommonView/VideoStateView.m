// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "VideoStateView.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import "NECommonUIConstant.h"

@interface VideoStateView ()

@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UIImageView *videoPlayImageView;
@property (nonatomic, strong) UIView *alphaBackView;
@property (nonatomic, strong) UIView *verticalLineLeft;
@property (nonatomic, strong) UIView *verticalLineRight;
@property (nonatomic, assign) BOOL didSetupUI;
@property (nonatomic, assign) float currentProgress;
- (void)setupUI;
- (void)updateProgressLayers;

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
  if (self.didSetupUI) return;
  self.didSetupUI = YES;
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

  self.circleLayer.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:0.5].CGColor;
  self.circleLayer.fillColor = UIColor.clearColor.CGColor;
  self.circleLayer.lineWidth = 4.0;
  self.circleLayer.frame = self.bounds;
  [self.layer addSublayer:self.circleLayer];
  [self.layer addSublayer:self.progressLayer];

  self.state = VideoStateVideoPlay;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self updateProgressLayers];
}

- (void)setState:(VideoState)state {
  _state = state;
  switch (state) {
    case VideoStateVideoPlay:
      self.videoPlayImageView.hidden = NO;
      self.verticalLineLeft.hidden = YES;
      self.verticalLineRight.hidden = YES;
      self.circleLayer.hidden = YES;
      self.progressLayer.hidden = YES;
      self.alphaBackView.hidden = YES;
      break;
    case VideoStateVideoDownload:
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
  self.currentProgress = MIN(MAX(progress, 0.0f), 1.0f);
  if (self.currentProgress < 1.0f) {
    self.state = VideoStateVideoDownload;
  }

  [self updateProgressLayers];

  if (self.currentProgress >= 1.0f) {
    self.state = VideoStateVideoPlay;
  }
}

- (void)updateProgressLayers {
  CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  UIBezierPath *borderPath = [UIBezierPath bezierPathWithArcCenter:center
                                                            radius:21.0
                                                        startAngle:0
                                                          endAngle:(CGFloat)(2 * M_PI)
                                                         clockwise:YES];
  self.circleLayer.frame = self.bounds;
  self.circleLayer.path = borderPath.CGPath;

  CGFloat start = (CGFloat)(-0.5f * M_PI);
  CGFloat end = (CGFloat)(self.currentProgress * 2.0f * (float)M_PI - 0.5f * (float)M_PI);
  UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:center
                                                              radius:21.0
                                                          startAngle:start
                                                            endAngle:end
                                                           clockwise:YES];
  self.progressLayer.frame = self.bounds;
  self.progressLayer.path = progressPath.CGPath;
  self.progressLayer.strokeColor = UIColor.whiteColor.CGColor;
  self.progressLayer.fillColor = UIColor.clearColor.CGColor;
  self.progressLayer.lineWidth = 4.0;

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
