// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEMessageUtil.h — 对齐 Swift NEMessageUtil
// 将 V2NIMLastMessage 转换为会话列表的消息预览文案

#import <Foundation/Foundation.h>

@class V2NIMLastMessage;

NS_ASSUME_NONNULL_BEGIN

@interface NEMessageUtil : NSObject

/// 根据 V2NIMLastMessage 返回会话列表中的消息预览文案
+ (NSString *)messageContentFromLastMessage:(nullable V2NIMLastMessage *)lastMessage;

/// 根据消息类型、文本、附件返回预览文案（对齐 Swift 参数形式）
+ (NSString *)messageContentWithType:(NSInteger)messageType
                                text:(nullable NSString *)text
                          attachment:(nullable id)attachment;

@end

NS_ASSUME_NONNULL_END
