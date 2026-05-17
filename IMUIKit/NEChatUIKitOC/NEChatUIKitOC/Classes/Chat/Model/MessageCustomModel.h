// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 自定义消息模型
@interface MessageCustomModel : MessageContentModel

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 带自定义类型和内容高度的初始化方法
/// @param message V2NIM 消息对象
/// @param customType 自定义消息子类型
/// @param contentHeight 内容高度
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message
                     customType:(NSInteger)customType
                  contentHeight:(NSInteger)contentHeight;

@end

NS_ASSUME_NONNULL_END
