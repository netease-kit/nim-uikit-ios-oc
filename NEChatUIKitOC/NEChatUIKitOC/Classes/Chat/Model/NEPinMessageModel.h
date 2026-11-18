// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "MessageContentModel.h"
#import "PinMessageFileModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 标记消息展示模型
@interface NEPinMessageModel : NSObject

/// 消息对应的聊天模型（默认为 MessageTextModel）
@property (nonatomic, strong) id<MessageModel> chatmodel;

/// 原始 V2NIM 消息对象
@property (nonatomic, strong) V2NIMMessage *message;

/// 标记消息的 pin 信息
@property (nonatomic, strong) V2NIMMessagePin *item;

/// 会话 ID
@property (nonatomic, copy, nullable) NSString *conversationId;

/// 文件相关信息（仅文件类型消息有效）
@property (nonatomic, strong, nullable) PinMessageFileModel *pinFileModel;

/// 初始化方法
/// @param message V2NIM 消息对象
/// @param item    V2NIM 标记信息
- (instancetype)initWithMessage:(V2NIMMessage *)message item:(V2NIMMessagePin *)item;

/// 计算 cell 高度
/// @param pinContentMaxW 内容最大宽度
- (CGFloat)cellHeight:(CGFloat)pinContentMaxW;

@end

NS_ASSUME_NONNULL_END
