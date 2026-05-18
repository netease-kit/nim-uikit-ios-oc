// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 位置消息模型
@interface MessageLocationModel : MessageContentModel

/// 纬度
@property (nonatomic, strong, nullable) NSNumber *lat;  // wraps double
/// 经度
@property (nonatomic, strong, nullable) NSNumber *lng;  // wraps double
/// 标题
@property (nonatomic, copy, nullable) NSString *title;
/// 副标题/地址
@property (nonatomic, copy, nullable) NSString *subTitle;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

@end

NS_ASSUME_NONNULL_END
