// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "VideoPlayerViewController.h"
#import "BrowserToolsBar.h"
#import "ToastImageView.h"
#import "VideoToolBar.h"
#import "ExpandButton.h"
#import "NECommonUIConstant.h"
#import "UIView+YXToast.h"
#import <AVFoundation/AVFoundation.h>
#import <math.h>
#import <NEChatKit/NEAuthManager.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NSDate+NECommon.h>

static NSString *const kCallKitShowNoti = @"kCallKitShowNoti";

@interface VideoPlayerViewController () <BrowserToolsBarDelegate, VideoToolBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) ExpandButton *playButton;
@property (nonatomic, strong) BrowserToolsBar *toolsBar;
@property (nonatomic, strong) ToastImageView *successView;
@property (nonatomic, strong) VideoToolBar *videoToolBar;
@property (nonatomic, strong) UITapGestureRecognizer *dismissGesture;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong, nullable) id timeObserver;
@property (nonatomic, assign) BOOL isRefreshProgress;
@property (nonatomic, assign) BOOL isPlayingEnd;

@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  [self setupNotifications];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.playerLayer.frame = self.view.bounds;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (self.timeObserver && self.avPlayer) {
    [self.avPlayer removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
  }
}

- (void)setupUI {
  self.view.backgroundColor = UIColor.blackColor;
  self.isRefreshProgress = YES;

  if (self.videoUrl) {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    self.avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];
    [self.avPlayer play];

    __weak typeof(self) weakSelf = self;
    CMTime interval = CMTimeMakeWithSeconds(0.2, (int32_t)NSEC_PER_SEC);
    self.timeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:interval
                                                                    queue:dispatch_get_main_queue()
                                                               usingBlock:^(CMTime time) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf || !strongSelf.isRefreshProgress) {
        return;
      }
      Float64 duration = CMTimeGetSeconds(strongSelf.avPlayer.currentItem.duration);
      Float64 seekTime = CMTimeGetSeconds([strongSelf.avPlayer currentTime]);
      if (duration <= 0 || isnan(duration) || isnan(seekTime)) {
        return;
      }
      CGFloat progress = seekTime / duration;
      strongSelf.videoToolBar.progressSlider.value = (float)progress;
      strongSelf.videoToolBar.currentTimeLabel.text = [NSDate ne_getFormatPlayTime:seekTime];
      if (progress >= 1.0) {
        [strongSelf endPlay];
      }
    }];
  }

  [self.view addSubview:self.toolsBar];
  [NSLayoutConstraint activateConstraints:@[
    [self.toolsBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.toolsBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.toolsBar.heightAnchor constraintEqualToConstant:44.0],
    [self.toolsBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-27.0],
  ]];

  [self.view addSubview:self.videoToolBar];
  [NSLayoutConstraint activateConstraints:@[
    [self.videoToolBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.videoToolBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.videoToolBar.heightAnchor constraintEqualToConstant:44.0],
    [self.videoToolBar.bottomAnchor constraintEqualToAnchor:self.toolsBar.topAnchor],
  ]];

  if (self.totalTime > 0) {
    self.videoToolBar.total = self.totalTime;
    self.videoToolBar.totalTimeLabel.text = [NSDate ne_getFormatPlayTime:self.totalTime / 1000.0];
  }

  [self.view addSubview:self.playButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.playButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.playButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
  [self.playButton addTarget:self action:@selector(toPlay) forControlEvents:UIControlEventTouchUpInside];

  [self.view addGestureRecognizer:self.dismissGesture];
  [self.dismissGesture addTarget:self action:@selector(dismissVideoToolBar)];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerDidFinishPlaying:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(interruptionStart)
                                               name:kCallKitShowNoti
                                             object:nil];
}

- (void)setupNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleInterruption:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:nil];
}

- (void)interruptionStart {
  if (!self.isPlayingEnd) {
    self.videoToolBar.playButton.selected = YES;
    [self didClickPause];
  }
}

- (void)interruptionEnd {
  if (!self.isPlayingEnd) {
    self.videoToolBar.playButton.selected = NO;
    [self didClickPlay];
  }
}

- (void)toPlay {
  if (self.isPlayingEnd) {
    [self.avPlayer seekToTime:kCMTimeZero];
    self.isPlayingEnd = NO;
  }
  self.playButton.hidden = YES;
  [self.avPlayer play];
  self.videoToolBar.playButton.selected = NO;
}

- (void)dismissVideoToolBar {
  self.videoToolBar.hidden = !self.videoToolBar.hidden;
}

- (void)handleInterruption:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  NSNumber *typeValue = userInfo[AVAudioSessionInterruptionTypeKey];
  if (!typeValue) {
    return;
  }
  AVAudioSessionInterruptionType type = typeValue.unsignedIntegerValue;
  if (type == AVAudioSessionInterruptionTypeBegan) {
    [self interruptionStart];
    return;
  }

  NSNumber *optionsValue = userInfo[AVAudioSessionInterruptionOptionKey];
  if (!optionsValue) {
    return;
  }
  AVAudioSessionInterruptionOptions options = optionsValue.unsignedIntegerValue;
  if (options & AVAudioSessionInterruptionOptionShouldResume) {
    [self interruptionEnd];
  }
}

- (void)didClickPause {
  [self.avPlayer pause];
  self.playButton.hidden = NO;
}

- (void)didClickPlay {
  if (self.isPlayingEnd) {
    [self.avPlayer seekToTime:kCMTimeZero];
    self.isPlayingEnd = NO;
  }
  [self.avPlayer play];
  self.isRefreshProgress = YES;
  self.playButton.hidden = YES;
}

- (void)didSeek:(float)progress {
  if (self.totalTime <= 0) {
    return;
  }
  Float64 seekTime = (Float64)self.totalTime * progress / 1000.0;
  [self.avPlayer seekToTime:CMTimeMakeWithSeconds(seekTime, 1)];
}

- (void)didStopRefreshProgress {
  self.isRefreshProgress = NO;
}

- (void)didStartRefreshProgress {
  self.isRefreshProgress = YES;
}

- (void)didCloseClick {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSaveClick {
  __weak typeof(self) weakSelf = self;
  [NEAuthManager requestPhotoAuthorization:^(BOOL granted) {
    if (!granted) {
      [weakSelf showToast:commonLocalizable(@"jump_photo_setting")];
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf.view neMakeToastActivity:NEToastPositionCenter];
      [weakSelf didToSave];
    });
  }];
}

- (void)didToSave {
  if (self.videoUrl.isFileURL && self.videoUrl.path.length > 0) {
    UISaveVideoAtPathToSavedPhotosAlbum(self.videoUrl.path,
                                       self,
                                       @selector(save:didFinishSavingWithError:contextInfo:),
                                       nil);
  } else {
    [self.view neHideToastActivity];
    [self showToast:commonLocalizable(@"video_not_save")];
  }
}

- (void)endPlay {
  [self.videoToolBar resetState];
  self.playButton.hidden = NO;
}

- (void)save:(NSString *)path didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  [self.view neHideToastActivity];
  if (error) {
    [self showToast:error.localizedDescription ?: @""];
  } else {
    [self.view ne_showToast:self.successView duration:1.5 position:NEToastPositionCenter completion:nil];
  }
}

- (void)playerDidFinishPlaying:(NSNotification *)notification {
  self.isPlayingEnd = YES;
}

- (void)showToast:(NSString *)message {
  if (message.length == 0) {
    return;
  }
  [self.view neMakeToast:message position:NEToastPositionCenter];
}

- (ExpandButton *)playButton {
  if (!_playButton) {
    _playButton = [[ExpandButton alloc] init];
    _playButton.hidden = YES;
    _playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playButton setImage:[coreLoader() loadImage:@"video_play"] forState:UIControlStateNormal];
  }
  return _playButton;
}

- (BrowserToolsBar *)toolsBar {
  if (!_toolsBar) {
    _toolsBar = [[BrowserToolsBar alloc] init];
    _toolsBar.delegate = self;
    _toolsBar.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _toolsBar;
}

- (ToastImageView *)successView {
  if (!_successView) {
    _successView = [[ToastImageView alloc] initWithFrame:CGRectMake(0, 0, 118, 120)];
    _successView.contentLabel.text = commonLocalizable(@"save_system_album");
  }
  return _successView;
}

- (VideoToolBar *)videoToolBar {
  if (!_videoToolBar) {
    _videoToolBar = [[VideoToolBar alloc] init];
    _videoToolBar.translatesAutoresizingMaskIntoConstraints = NO;
    _videoToolBar.backgroundColor = UIColor.clearColor;
    _videoToolBar.delegate = self;
  }
  return _videoToolBar;
}

- (UITapGestureRecognizer *)dismissGesture {
  if (!_dismissGesture) {
    _dismissGesture = [[UITapGestureRecognizer alloc] init];
    _dismissGesture.numberOfTapsRequired = 1;
    _dismissGesture.numberOfTouchesRequired = 1;
  }
  return _dismissGesture;
}

@end
