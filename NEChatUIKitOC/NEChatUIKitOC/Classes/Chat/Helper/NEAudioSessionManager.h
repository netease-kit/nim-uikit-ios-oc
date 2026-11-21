// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEAudioSessionManager : NSObject

@property (class, nonatomic, readonly) NEAudioSessionManager *shared;

/// 录音进行中：此时 stopPlay 不能释放音频会话，否则会打断录音。
@property (nonatomic, assign) BOOL isRecording;

- (void)switchToSpeaker;
- (void)switchToReceiver;
- (void)configureAudioSession;
/// 播放结束/停止后释放音频会话（避免折叠/展开时系统弹出音频路由提示）。
- (void)deactivate;
- (void)setAudioRouteTo:(AVAudioSessionPortOverride)port;
- (void)startProximityMonitoring;
- (void)stopProximityMonitoring;

@end

NS_ASSUME_NONNULL_END
