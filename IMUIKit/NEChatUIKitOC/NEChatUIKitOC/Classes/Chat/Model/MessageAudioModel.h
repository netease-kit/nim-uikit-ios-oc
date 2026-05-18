// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 语音消息模型
@interface MessageAudioModel : MessageContentModel

/// 语音时长（秒）
@property (nonatomic, assign) NSInteger duration;
/// 语音气泡宽度
@property (nonatomic, assign) double audioWidth;
/// 是否正在播放
@property (nonatomic, assign) BOOL isPlaying;
/// 语音转文字结果
@property (nonatomic, copy, nullable) NSString *text;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
