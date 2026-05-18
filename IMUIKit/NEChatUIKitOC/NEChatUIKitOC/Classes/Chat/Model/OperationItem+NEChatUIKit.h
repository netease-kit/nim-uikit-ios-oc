// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEChatKitOC/OperationItem.h>

NS_ASSUME_NONNULL_BEGIN

/// 消息长按选项工厂方法
@interface OperationItem (NEChatUIKit)

/// 听筒
+ (instancetype)earpieceItem;

/// 扬声器
+ (instancetype)speakerItem;

/// 复制
+ (instancetype)copyItem;

/// 回复
+ (instancetype)replayItem;

/// 转发
+ (instancetype)forwardItem;

/// 标记
+ (instancetype)pinItem;

/// 取消标记
+ (instancetype)removePinItem;

/// 多选
+ (instancetype)selectItem;

/// 收藏
+ (instancetype)collectionItem;

/// 置顶
+ (instancetype)topItem;

/// 移除置顶
+ (instancetype)untopItem;

/// 删除
+ (instancetype)deleteItem;

/// 撤回
+ (instancetype)recallItem;

/// 语音转文字
+ (instancetype)audioToTextItem;

@end

/// 搜索聊天记录选项工厂方法
@interface OperationItem (NEChatUIKitSearch)

/// 群成员
+ (instancetype)searchTeamMemberItem;

/// 图片
+ (instancetype)searchImageItem;

/// 视频
+ (instancetype)searchVideoItem;

/// 日期
+ (instancetype)searchDateItem;

/// 文件
+ (instancetype)searchFileItem;

@end

NS_ASSUME_NONNULL_END
