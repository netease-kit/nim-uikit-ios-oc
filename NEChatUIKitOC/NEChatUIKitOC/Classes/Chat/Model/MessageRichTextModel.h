// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageTextModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 富文本消息模型（标题 + 正文）
@interface MessageRichTextModel : MessageTextModel

/// 标题文本
@property (nonatomic, copy, nullable) NSString *titleText;
/// 标题富文本
@property (nonatomic, strong, nullable) NSMutableAttributedString *titleAttributeStr;
/// 标题文本高度
@property (nonatomic, assign) CGFloat titleTextHeight;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 获取划词选中的文本（替换内置表情）
- (nullable NSString *)selectText;

@end

NS_ASSUME_NONNULL_END
