// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"
#import <NEChatKit/TranslationInfo.h>

NS_ASSUME_NONNULL_BEGIN

/// 文本消息模型
@interface MessageTextModel : MessageContentModel

/// 消息文本内容
@property (nonatomic, copy, nullable) NSString *messageText;
/// 带表情的富文本
@property (nonatomic, strong, nullable) NSMutableAttributedString *attributeStr;
/// 文本高度
@property (nonatomic, assign) CGFloat textHeight;
/// Parsed translation cache. Invalid or legacy values are ignored.
@property (nonatomic, strong, nullable) TranslationInfo *translationInfo;
@property (nonatomic, assign) BOOL translationVisible;
/// 最近一次翻译请求失败，显示内联重试提示。
@property (nonatomic, assign) BOOL translationFailed;
@property (nonatomic, assign) CGFloat addedTranslationHeight;
@property (nonatomic, assign) CGFloat translationBaseContentWidth;

- (CGFloat)estimateTranslationBubbleHeight;
- (CGFloat)estimateTranslationTextWidth;
- (CGFloat)translationFooterMinWidth;

/// 初始化方法
/// @param message V2NIM 消息对象
- (instancetype)initWithMessage:(nullable V2NIMMessage *)message;

/// 重置消息（解析 emoji、@ 高亮）
/// @param message V2NIM 消息对象
- (void)resetMessage:(nullable V2NIMMessage *)message;

/// 计算文本尺寸
/// @param attributeStr 富文本（传 nil 使用 self.attributeStr）
- (CGSize)getTextSize:(nullable NSAttributedString *)attributeStr;

/// 根据富文本重新计算高度
/// @param attributeStr 富文本（传 nil 使用 self.attributeStr）
- (void)resetHeight:(nullable NSAttributedString *)attributeStr;

/// 手动设置文本尺寸
/// @param height 文本高度
/// @param width 文本宽度（默认 chat_content_maxW）
- (void)resetWH:(CGFloat)height width:(CGFloat)width;

/// 获取划词选中的文本（替换内置表情）
- (nullable NSString *)selectText;

@end

NS_ASSUME_NONNULL_END
