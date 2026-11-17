// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 媒体消息分组模型（按时间分组）
@interface MediaSectionModel : NSObject

/// 分组时间标题
@property (nonatomic, copy) NSString *time;

/// 该分组下的消息模型列表
@property (nonatomic, strong) NSMutableArray<MessageContentModel *> *messageModels;

@end

NS_ASSUME_NONNULL_END
