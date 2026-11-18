// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 图片消息模型
@interface MessageImageModel : MessageContentModel

/// 图片 URL 或本地路径
@property (nonatomic, copy, nullable) NSString *urlString;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
