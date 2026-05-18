// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 文件消息模型
@interface MessageFileModel : MessageVideoModel

/// 文件显示名称
@property (nonatomic, copy, nullable) NSString *displayName;
/// 文件路径
@property (nonatomic, copy, nullable) NSString *path;
/// 文件大小（字节）
@property (nonatomic, strong, nullable) NSNumber *fileLength; // NSNumber wrapping int64_t
/// 文件大小（格式化后的值）
@property (nonatomic, assign) float size;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
