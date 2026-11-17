// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageTextModel.h"

NS_ASSUME_NONNULL_BEGIN

/// AI 流式消息模型
@interface MessageAIStreamModel : MessageTextModel

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 重置消息（解析 markdown 内容）
/// @param message V2NIM 消息对象
- (void)resetMessage:(nullable V2NIMMessage *)message;

/// 计算文本尺寸（markdown 解析后）
/// @param attributeStr 富文本（传 nil 使用 self.attributeStr）
- (CGSize)getTextSize:(nullable NSAttributedString *)attributeStr;

/// 按气泡内容宽度重新解析 Markdown（分栏后宽度变化时用）
- (void)measureMarkdownWithContentMaxWidth:(CGFloat)contentMaxWidth;


@end

NS_ASSUME_NONNULL_END
