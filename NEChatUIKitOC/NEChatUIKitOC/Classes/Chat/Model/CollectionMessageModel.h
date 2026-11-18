// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "CollectionFileModel.h"
#import "MessageContentModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 收藏消息展示模型
@interface CollectionMessageModel : NSObject

/// 消息对象（设置时自动构建 chatmodel 和 fileModel）
@property (nonatomic, strong, nullable) V2NIMMessage *message;

/// 消息对应的聊天模型
@property (nonatomic, strong) id<MessageModel> chatmodel;

/// 文件相关信息（仅文件类型消息有效）
@property (nonatomic, strong, nullable) CollectionFileModel *fileModel;

/// 会话名称
@property (nonatomic, copy, nullable) NSString *conversationName;

/// 发送者昵称
@property (nonatomic, copy, nullable) NSString *senderName;

/// 用户头像
@property (nonatomic, copy, nullable) NSString *avatar;

/// SDK 收藏对象
@property (nonatomic, strong, nullable) V2NIMCollection *collection;

/// 计算 cell 高度
/// @param contenttMaxW 内容最大宽度
- (CGFloat)cellHeight:(CGFloat)contenttMaxW;

@end

NS_ASSUME_NONNULL_END
