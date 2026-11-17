// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAudioSessionManager.h"
#import <UIKit/UIKit.h>

@interface NEAudioSessionManager ()
@property (nonatomic, assign) BOOL isSpeakerActive;
@end

@implementation NEAudioSessionManager

+ (NEAudioSessionManager *)shared {
  static NEAudioSessionManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEAudioSessionManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _isSpeakerActive = NO;
    [self configureAudioSession];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)switchToSpeaker {
  [self setAudioRouteTo:AVAudioSessionPortOverrideSpeaker];
  self.isSpeakerActive = YES;
  [self startProximityMonitoring];
}

- (void)switchToReceiver {
  [self setAudioRouteTo:AVAudioSessionPortOverrideNone];
  self.isSpeakerActive = NO;
  [self stopProximityMonitoring];
}

- (void)configureAudioSession {
  [self configureAudioSessionForPort:AVAudioSessionPortOverrideNone];
}

- (void)configureAudioSessionForPort:(AVAudioSessionPortOverride)port {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  AVAudioSessionCategoryOptions options = port == AVAudioSessionPortOverrideSpeaker
    ? AVAudioSessionCategoryOptionDefaultToSpeaker : 0;
  NSError *error = nil;
  [session setCategory:AVAudioSessionCategoryPlayAndRecord
                  mode:AVAudioSessionModeVoiceChat
               options:options
                 error:&error];
  if (error) {
    NSLog(@"[Audio] Session config error: %@", error);
  }
  [session setActive:YES error:&error];
  if (error) {
    NSLog(@"[Audio] Session activate error: %@", error);
  }
}

- (void)setAudioRouteTo:(AVAudioSessionPortOverride)port {
  [self configureAudioSessionForPort:port];
  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error = nil;
  // Default to speaker without overriding a connected headset's route.
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
  if (error) {
    NSLog(@"[Audio] Route switch failed: %@", error);
  }
  [session setPreferredOutputNumberOfChannels:1 error:&error];
  if (error) {
    NSLog(@"[Audio] Channel config error: %@", error);
  }
}

#pragma mark - Proximity Monitoring

- (void)startProximityMonitoring {
  if ([UIDevice currentDevice].isProximityMonitoringEnabled) {
    return;
  }
  [UIDevice currentDevice].proximityMonitoringEnabled = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleProximityChange)
                                               name:UIDeviceProximityStateDidChangeNotification
                                             object:nil];
}

- (void)stopProximityMonitoring {
  if (![UIDevice currentDevice].isProximityMonitoringEnabled) {
    return;
  }
  [UIDevice currentDevice].proximityMonitoringEnabled = NO;
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIDeviceProximityStateDidChangeNotification
                                                object:nil];
}

- (void)handleProximityChange {
  if (!self.isSpeakerActive) {
    return;
  }
  if ([UIDevice currentDevice].proximityState) {
    // Near ear — switch to receiver
    [self setAudioRouteTo:AVAudioSessionPortOverrideNone];
  } else {
    // Away from ear — restore speaker
    [self setAudioRouteTo:AVAudioSessionPortOverrideSpeaker];
  }
}

@end
