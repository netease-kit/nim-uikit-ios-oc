// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEConversationListCell.h
// 会话列表 Cell — 对齐 Swift NEBaseConversationListCell

#import <UIKit/UIKit.h>

@class NEConversationListModel;
@class NEUserHeaderView;
@class RedAngleLabel;

NS_ASSUME_NONNULL_BEGIN

@interface NEConversationListCell : UITableViewCell

/// 头像（支持 URL 加载 + 文字占位 + 哈希背景色）
@property (nonatomic, strong) NEUserHeaderView *headImageView;

/// 在线状态点
@property (nonatomic, strong) UIView *onlineView;

/// 未读角标（带 textInsets 内边距）
@property (nonatomic, strong) RedAngleLabel *redAngleView;

/// 会话名称
@property (nonatomic, strong) UILabel *titleLabel;

/// 最新消息预览
@property (nonatomic, strong) UILabel *subTitleLabel;

/// 时间
@property (nonatomic, strong) UILabel *timeLabel;

/// 免打扰图标
@property (nonatomic, strong) UIImageView *notifyMsgView;

/// 时间宽度约束
@property (nonatomic, strong, nullable) NSLayoutConstraint *timeWidthConstraint;

/// 绑定模型数据
- (void)configureData:(nullable NEConversationListModel *)model;

/// 设置在线状态
- (void)setOnline:(BOOL)online;

@end

NS_ASSUME_NONNULL_END