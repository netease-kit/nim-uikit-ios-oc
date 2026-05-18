// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 音视频通话记录消息模型
@interface MessageCallRecordModel : MessageContentModel

/// 通话记录富文本（含图标和文字）
@property (nonatomic, strong, nullable) NSMutableAttributedString *callRecordAttributeStr;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
