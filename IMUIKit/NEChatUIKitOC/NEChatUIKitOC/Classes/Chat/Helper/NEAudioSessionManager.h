// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEAudioSessionManager : NSObject

@property (class, nonatomic, readonly) NEAudioSessionManager *shared;

- (void)switchToSpeaker;
- (void)switchToReceiver;
- (void)configureAudioSession;
- (void)setAudioRouteTo:(AVAudioSessionPortOverride)port;
- (void)startProximityMonitoring;
- (void)stopProximityMonitoring;

@end

NS_ASSUME_NONNULL_END
