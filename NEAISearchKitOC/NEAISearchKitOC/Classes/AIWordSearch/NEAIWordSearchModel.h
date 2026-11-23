// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEAIWordSearchModel : NSObject

@property (nonatomic, strong, nullable) NSAttributedString *content;
@property (nonatomic, assign) CGFloat height;
/// 文案可用的最大宽度（= 当前列宽 − 左右各 20），用于换行与行高测量。
@property (nonatomic, assign, readonly) CGFloat maxTextWidth;

- (instancetype)initWithContent:(nullable NSAttributedString *)content;

/// - Parameter maxTextWidth: 当前列内可用宽度；<= 0 时回退整窗宽度。
///   双栏展开时结果面板只占右列（约 558pt），不能再用整窗宽度测量。
- (instancetype)initWithContent:(nullable NSAttributedString *)content
                   maxTextWidth:(CGFloat)maxTextWidth;

/// 列宽变化后重新测量行高（折叠/展开、进入/离开右列）。
- (void)updateMaxTextWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
