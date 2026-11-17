// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "VideoToolBar.h"
#import "ExpandButton.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NSDate+NECommon.h>

@interface VideoToolBar ()

@property (nonatomic, strong, readwrite) ExpandButton *playButton;
@property (nonatomic, strong, readwrite) UILabel *currentTimeLabel;
@property (nonatomic, strong, readwrite) UILabel *totalTimeLabel;
@property (nonatomic, strong, readwrite) UISlider *progressSlider;

@end

@implementation VideoToolBar

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
  [self addSubview:self.playButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.playButton.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.playButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.playButton.widthAnchor constraintEqualToConstant:60.0],
  ]];
  [self.playButton addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];

  [self addSubview:self.currentTimeLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.currentTimeLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.currentTimeLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48.0],
  ]];

  [self addSubview:self.progressSlider];
  [NSLayoutConstraint activateConstraints:@[
    [self.progressSlider.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.progressSlider.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:90.0],
    [self.progressSlider.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-55.0],
  ]];
  [self.progressSlider addTarget:self action:@selector(sliderChange) forControlEvents:UIControlEventValueChanged];
  [self.progressSlider addTarget:self action:@selector(sliderTouchUp) forControlEvents:UIControlEventTouchUpInside];
  [self.progressSlider addTarget:self action:@selector(sliderTouchUp) forControlEvents:UIControlEventTouchUpOutside];
  [self.progressSlider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];

  [self addSubview:self.totalTimeLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.totalTimeLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-15.0],
    [self.totalTimeLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
  ]];
}

- (void)sliderChange {
  [self.delegate didSeek:self.progressSlider.value];
  if (self.playButton.selected) {
    CGFloat current = (CGFloat)self.total * self.progressSlider.value;
    self.currentTimeLabel.text = [NSDate ne_getFormatPlayTime:current / 1000.0];
  }
}

- (void)sliderTouchUp {
  [self.delegate didStartRefreshProgress];
  [self.delegate didSeek:self.progressSlider.value];
}

- (void)sliderTouchDown {
  [self.delegate didStopRefreshProgress];
}

- (void)playClick:(ExpandButton *)button {
  button.selected = !button.selected;
  if (button.selected) {
    [self.delegate didClickPause];
  } else {
    [self.delegate didClickPlay];
  }
}

- (void)resetState {
  self.playButton.selected = YES;
  self.progressSlider.value = 0;
  self.currentTimeLabel.text = @"00:00";
}

- (ExpandButton *)playButton {
  if (!_playButton) {
    _playButton = [[ExpandButton alloc] init];
    _playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playButton setImage:[coreLoader() loadImage:@"video_stop_icon"] forState:UIControlStateNormal];
    [_playButton setImage:[coreLoader() loadImage:@"video_play_icon"] forState:UIControlStateSelected];
  }
  return _playButton;
}

- (UILabel *)currentTimeLabel {
  if (!_currentTimeLabel) {
    _currentTimeLabel = [[UILabel alloc] init];
    _currentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _currentTimeLabel.textColor = UIColor.whiteColor;
    _currentTimeLabel.font = [NEConstant defaultTextFont:12.0];
    _currentTimeLabel.text = @"00:00";
  }
  return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel {
  if (!_totalTimeLabel) {
    _totalTimeLabel = [[UILabel alloc] init];
    _totalTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _totalTimeLabel.textColor = UIColor.whiteColor;
    _totalTimeLabel.font = [NEConstant defaultTextFont:12.0];
  }
  return _totalTimeLabel;
}

- (UISlider *)progressSlider {
  if (!_progressSlider) {
    _progressSlider = [[UISlider alloc] init];
    _progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _progressSlider.tintColor = UIColor.whiteColor;
    _progressSlider.thumbTintColor = UIColor.whiteColor;
    _progressSlider.maximumValue = 1.0f;
    _progressSlider.minimumValue = 0.0f;
    _progressSlider.value = 0.0f;
    _progressSlider.minimumTrackTintColor = UIColor.whiteColor;
    _progressSlider.continuous = YES;
    _progressSlider.maximumTrackTintColor = [[NEConstant hexRGB:0x000000] colorWithAlphaComponent:0.3];
  }
  return _progressSlider;
}

@end
