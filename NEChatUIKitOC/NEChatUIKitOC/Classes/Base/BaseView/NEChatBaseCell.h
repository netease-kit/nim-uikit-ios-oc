// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEChatViewport.h"

@class MessageContentModel;

NS_ASSUME_NONNULL_BEGIN

/// 消息 cell 基类：承载"当前详情宽度"这一展示事实。
///
@interface NEChatBaseCell : UITableViewCell

/// 当前详情几何；由消息模型在宽度变化时下发。
@property (nonatomic, strong, nullable) NEChatViewport *chatViewport;

/// 气泡宽度上限（viewport 优先）。
@property (nonatomic, assign, readonly) CGFloat chatContentMaxW;
/// 文本宽度上限（viewport 优先）。
@property (nonatomic, assign, readonly) CGFloat chatTextMaxW;
/// 语音气泡宽度上限（viewport 优先）。
@property (nonatomic, assign, readonly) CGFloat audioMaxWidth;
/// 内容容器宽度（viewport 优先）。
@property (nonatomic, assign, readonly) CGFloat chatContainerWidth;

/// 登记一个"跟随 viewport 变化的宽度上限约束"，在复用/换宽时统一更新。
- (NSLayoutConstraint *)messageWidthConstraint:(NSLayoutDimension *)anchor inset:(CGFloat)inset;

/// 下发新的展示几何：更新已登记的宽度约束。
- (void)applyViewport:(nullable NEChatViewport *)viewport;

- (void)uploadProgress:(NSUInteger)progress;
- (void)setModel:(MessageContentModel *)model;
- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend;

@end

NS_ASSUME_NONNULL_END
