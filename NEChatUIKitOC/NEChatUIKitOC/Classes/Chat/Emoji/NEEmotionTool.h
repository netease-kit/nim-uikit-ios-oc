// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEEmotionAttachment.h"

NS_ASSUME_NONNULL_BEGIN

/// 表情工具类（正则匹配 + 富文本转换）
@interface NEEmotionTool : NSObject

/// 找出字符串中所有表情标签的位置集合
/// @param str 原始字符串
/// @return NSTextCheckingResult 数组
+ (nullable NSArray<NSTextCheckingResult *> *)getRegularArray:(NSString *)str;

/// 将字符串中的表情标签替换为富文本附件
/// @param str    原始字符串
/// @param font   字体
/// @param color  颜色
/// @param offset 附件偏移量（默认 {0, -4}）
/// @return 替换后的富文本
+ (NSMutableAttributedString *)getAttWithStr:(NSString *)str
                                        font:(UIFont *)font
                                       color:(UIColor *)color
                                      offset:(CGPoint)offset;

/// 将富文本中表情附件转换回文本标签
/// @param att   富文本
/// @param range 范围
/// @return 文本字符串（若为空则返回 nil）
+ (nullable NSString *)getTextWithAtt:(nullable NSMutableAttributedString *)att
                                range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
