// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageImageModel.h"
#import "MessageEnum.h"

@class NEHistorySearchVideoCell;

NS_ASSUME_NONNULL_BEGIN

/// 视频消息模型
@interface MessageVideoModel : MessageImageModel

/// 下载状态
@property (nonatomic, assign) DownloadState state;
/// 上传/下载进度
@property (nonatomic, assign) NSUInteger progress;
/// 搜索消息对应的cell（弱引用）
@property (nonatomic, weak, nullable) NEHistorySearchVideoCell *historyVideoCell;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 设置（视频、文件）消息模型（上传、下载）进度
/// @param progress 上传/下载进度
- (void)setModelProgress:(NSUInteger)progress;

@end

NS_ASSUME_NONNULL_END
