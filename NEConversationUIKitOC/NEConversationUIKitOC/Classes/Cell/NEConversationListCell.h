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
@class NIMRecentSession;
@class V2NIMLastMessage;
@class NEAIUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseConversationListCell : UITableViewCell

/// 头像（支持 URL 加载 + 文字占位 + 哈希背景色）
@property (nonatomic, strong) NEUserHeaderView *headImageView;

/// 在线状态点
@property (nonatomic, strong) UIView *onlineView;

/// 未读角标（带 textInsets 内边距）
@property (nonatomic, strong) RedAngleLabel *redAngleView;

/// 免打扰会话未读红点（不显示未读数字）
@property (nonatomic, strong) UIView *mutedUnreadDotView;

/// 会话名称
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *titleContentView;
@property (nonatomic, strong) UIImageView *robotIconView;

/// 最新消息预览
@property (nonatomic, strong) UILabel *subTitleLabel;

/// 时间
@property (nonatomic, strong) UILabel *timeLabel;

/// 免打扰图标
@property (nonatomic, strong) UIImageView *notifyMsgView;

/// 时间宽度约束
@property (nonatomic, strong, nullable) NSLayoutConstraint *timeWidthConstraint;

/// FunUI 分隔线。
@property (nonatomic, strong) UIView *bottomLine;

/// 绑定模型数据
- (void)configureData:(nullable NEConversationListModel *)model;

/// 设置在线状态
- (void)setOnline:(BOOL)online;

- (void)setupSubviews;
- (void)initSubviewsLayout;
- (NSTimeInterval)timestampDescriptionForRecentSessionWithRecentSession:(NIMRecentSession *)recentSession;
- (NSString *)contentForConversationWithLastMessage:(V2NIMLastMessage *)lastMessage;
- (void)appendBotSubSessionPrefixIfNeededTo:(NSMutableAttributedString *)content;
- (void)refreshBotSubSessionPrefixIfNeeded;
- (void)insertBotSubSessionPrefixIfNeeded;

@end

/// 旧版 OC 类名兼容入口。
@interface NEConversationListCell : NEBaseConversationListCell
@end

@interface ConversationListCell : NEBaseConversationListCell
@end

@interface FunConversationListCell : NEBaseConversationListCell
@end

/// 与 Swift UIKit 同名的数字人置顶 Cell 层级。
@interface NEBaseStickTopCell : UICollectionViewCell

@property (nonatomic, strong, readonly) NEUserHeaderView *stickTopHeadImageView;
@property (nonatomic, strong, readonly) UILabel *stickTopNameLabel;

- (void)setupStickTopCellUI;
- (void)configAIUserCellData:(nullable NEAIUserModel *)model;

@end

@interface StickTopCell : NEBaseStickTopCell
@end

@interface FunStickTopCell : NEBaseStickTopCell
@end

NS_ASSUME_NONNULL_END
