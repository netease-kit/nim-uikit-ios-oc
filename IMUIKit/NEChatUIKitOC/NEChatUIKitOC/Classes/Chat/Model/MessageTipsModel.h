// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 提示/通知消息模型
@interface MessageTipsModel : MessageContentModel

/// 提示文本
@property (nonatomic, copy, nullable) NSString *text;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 重置消息（解析通知或提示文本）
/// @param message V2NIM 消息对象
- (void)resetMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
