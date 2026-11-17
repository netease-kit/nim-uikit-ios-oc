// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "MessageContentModel.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"
#import "NEChatBaseCell.h"
#import "CirleProgressView.h"
#import "ChatActivityIndicatorView.h"
#import "NEMessageReactionView.h"

NS_ASSUME_NONNULL_BEGIN

@class NEBaseChatMessageCell;
@class MessageContentModel;

/// ChatBaseCellDelegate 协议
@protocol ChatBaseCellDelegate <NSObject>
@required
/// 单击头像
- (void)didTapAvatarView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 长按头像
- (void)didLongPressAvatar:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 单击消息体
- (void)didTapMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model replyModel:(nullable id)replyModel;
/// 长按消息体
- (void)didLongPressMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 单击重发按钮
- (void)didTapResendView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 单击重新编辑按钮
- (void)didTapReeditButton:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 单击已读未读按钮
- (void)didTapReadView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 单击多选按钮
- (void)didTapSelectButton:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;

@optional
/// 点击消息下方的 Reaction 胶囊或添加按钮。
- (void)didTapReaction:(UITableViewCell *)cell model:(nullable MessageContentModel *)model index:(NSInteger)index;
/// 划词选中失去焦点
- (void)didTextViewLoseFocus:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 消息即将展示
- (void)messageWillShow:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 停止流式消息
- (void)stopAIStreamMessage:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 重新生成流式消息
- (void)regenAIStreamMessage:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// 点击自动检测的链接
- (void)didTapDetectedLink:(UITableViewCell *)cell model:(nullable MessageContentModel *)model url:(NSURL *)url;
/// Long press on translated content, kept separate from source-message operations.
- (void)didLongPressTranslationView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
/// Tap the inline translation failure prompt to retry.
- (void)didTapTranslationRetryView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
@end

/// ChatAudioCellProtocol 协议
@protocol ChatAudioCellProtocol <NSObject>
@required
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, copy, nullable) NSString *messageId;
- (void)startAnimation:(BOOL)byRight;
- (void)stopAnimation:(BOOL)byRight;
@end

/// NEBaseChatMessageCell 基础消息 Cell
@interface NEBaseChatMessageCell : NEChatBaseCell <NEMessageReactionViewDelegate>

/// pin 文案最大宽度
@property (nonatomic, assign, readonly) CGFloat pinLabelMaxWidth;

@property (nonatomic, weak, nullable) id<ChatBaseCellDelegate> delegate;
@property (nonatomic, strong, nullable) MessageContentModel *contentModel;
@property (nonatomic, assign) BOOL singleLeft;
/// Audio cells disable reaction-row long presses while retaining bubble long press.
@property (nonatomic, assign, readonly) BOOL supportsReactionLongPress;
/// Normal text cells place Reaction inside the message bubble; other cells
/// render it as a sibling below the bubble.
@property (nonatomic, assign, readonly) BOOL usesInlineReactionSurface;
@property (nonatomic, strong) NEMessageReactionView *reactionViewLeft;
@property (nonatomic, strong) NEMessageReactionView *reactionViewRight;
@property (nonatomic, strong) UIImageView *reactionBackdropLeft;
@property (nonatomic, strong) UIImageView *reactionBackdropRight;
/// Default Reaction placement is below the bubble. Normal text cells replace
/// these anchors to place Reaction between body text and translation.
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionTopAnchorLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reactionTopAnchorRight;

/// Vertical space between the primary message body and its Reaction row.
- (CGFloat)reactionTopSpacingForModel:(MessageContentModel *)model;
/// Vertical space between the Reaction row and the combined bubble bottom.
- (CGFloat)reactionBottomSpacingForModel:(MessageContentModel *)model;

/// Left
@property (nonatomic, strong) NEUserHeaderView *userHeaderViewLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *avatarImageLeftAnchor;
@property (nonatomic, strong) UIImageView *bubbleImageLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleTopAnchorLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleWLeft;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleHLeft;
@property (nonatomic, strong) UIImageView *pinImageLeft;
@property (nonatomic, strong) UILabel *pinLabelLeft;
@property (nonatomic, strong) UILabel *fullNameLabel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *fullNameH;

/// Right
@property (nonatomic, strong) NEUserHeaderView *userHeaderViewRight;
@property (nonatomic, strong) UIImageView *bubbleImageRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleWRight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bubbleHRight;
@property (nonatomic, strong) UIImageView *pinImageRight;
@property (nonatomic, strong) UILabel *pinLabelRight;

/// 已读未读视图
@property (nonatomic, strong) CirleProgressView *readView;
@property (nonatomic, strong) ChatActivityIndicatorView *activityView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *activityViewCenterYAnchor;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong, nullable) NSLayoutConstraint *selectedButtonCenterYAnchor;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *timeLabelHeightAnchor;

@property (nonatomic, strong) UIFont *messageTextFont;

- (void)setBubbleImage;
- (void)initProperty;
- (void)baseCommonUI;
- (void)baseCommonUILeft;
- (void)baseCommonUIRight;
- (void)addGesture;
- (void)initSubviewsLayout;

- (void)tapAvatar:(UITapGestureRecognizer *)tap;
- (void)tapMessage:(UITapGestureRecognizer *)tap;
- (void)longPressAvatar:(UILongPressGestureRecognizer *)longPress;
- (void)longPress:(UILongPressGestureRecognizer *)longPress;
- (void)resend:(UIButton *)button;
- (void)tapReadView:(UITapGestureRecognizer *)tap;
- (void)selectButtonClicked;

- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect;
- (void)showLeftOrRight:(BOOL)showRight;
- (void)resetSelectRange;
- (void)selectAllRange;
- (void)updatePinStatus:(MessageContentModel *)model isSend:(BOOL)isSend;
/// Horizontal inset inside the combined message/Reaction surface.
- (CGFloat)reactionHorizontalInsetForModel:(MessageContentModel *)model;
/// Extra outer spacing between image/video/file bodies and the Reaction bubble.
- (CGFloat)reactionBodyPaddingForModel:(MessageContentModel *)model;
/// Direction-aware Reaction insets used by Fun/WeChat text bubbles.
- (CGFloat)reactionLeadingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing;
- (CGFloat)reactionTrailingInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing;
/// Extra width occupied by a directional tail outside a fixed message body.
- (CGFloat)reactionBackdropTailInsetForModel:(MessageContentModel *)model isOutgoing:(BOOL)isOutgoing;
/// Identifies fixed-format message bodies that must not stretch with Reaction.
- (BOOL)usesFixedReactionSurfaceForModel:(MessageContentModel *)model;
/// Whether a fixed-format Reaction row is constrained to the message body.
- (BOOL)locksReactionSurfaceToMessageWidthForModel:(MessageContentModel *)model;
/// Optional skin fallback when a media/card foreground has no bubble image.
- (nullable UIImage *)reactionBackdropImageForOutgoing:(BOOL)isOutgoing;
/// Whether an opaque message-body background should extend behind Reaction.
- (BOOL)shouldCopyBubbleBackgroundToReactionBackdropForModel:(MessageContentModel *)model;
/// Clear a reused Reaction surface while retaining the original bubble art.
- (void)resetReactionSurfaceForReuse;

@end

NS_ASSUME_NONNULL_END
