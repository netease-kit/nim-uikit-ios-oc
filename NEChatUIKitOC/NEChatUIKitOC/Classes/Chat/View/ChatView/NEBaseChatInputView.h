// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import "ChatRecordView.h"


@class AIChatViewController;
@class InputEmoticonContainerView;
@class NIMInputSticker;

NS_ASSUME_NONNULL_BEGIN

/// 聊天菜单类型
typedef NS_ENUM(NSInteger, ChatMenuType) {
    ChatMenuTypeText = 0,
    ChatMenuTypeAudio,
    ChatMenuTypeEmoji,
    ChatMenuTypeImage,
    ChatMenuTypeAddMore,
};

/// 输入框模式
typedef NS_ENUM(NSInteger, ChatInputMode) {
    ChatInputModeNormal = 0,
    ChatInputModeMultipleSend,
    ChatInputModeMultipleReturn,
};

FOUNDATION_EXPORT NSString *const yxAtMsg;
FOUNDATION_EXPORT NSInteger const atRangeOffset;
FOUNDATION_EXPORT NSString *const atSegmentsKey;
FOUNDATION_EXPORT NSString *const atTextKey;

@protocol ChatInputMultilineDelegate <NSObject>
- (void)expandButtonDidClick;
- (void)didHideMultipleButtonClick;
- (void)aiChatButtonDidClick:(id)aiChatViewController open:(BOOL)open;
- (void)aiChatMessageDidClick:(NSString *)text;
@end

@class NEChatMoreActionView;
@class NEInputMoreCell;

@protocol ChatInputViewDelegate;

@interface NEBaseChatInputView : UIView <ChatRecordViewDelegate>

@property (nonatomic, weak, nullable) id<ChatInputMultilineDelegate> multipleLineDelegate;
@property (nonatomic, weak, nullable) id<ChatInputViewDelegate> delegate;
@property (nonatomic, assign) ChatMenuType currentType;
@property (nonatomic, strong, nullable) UIButton *currentButton;
@property (nonatomic, assign) CGFloat menuHeight;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *atRangeCache;
@property (nonatomic, strong) NSMutableArray<NSString *> *nickAccidList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *nickAccidDic;
@property (nonatomic, assign) ChatInputMode chatInpuMode;
@property (nonatomic, assign) V2NIMConversationType conversationType;
@property (nonatomic, assign) NSInteger textLimit;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *contentSubView;
@property (nonatomic, strong) UIView *greyView;
@property (nonatomic, strong) ChatRecordView *recordView;
@property (nonatomic, strong, nullable) UIView *expandButton;
@property (nonatomic, strong, nullable) UIView *aiChatButton;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIView *multipleLineView;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIView *multipleLineExpandButton;
@property (nonatomic, strong) UIView *multipleSendButton;
@property (nonatomic, strong) UIView *emojiView;
@property (nonatomic, strong) NEChatMoreActionView *chatAddMoreView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *textviewLeftConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *textviewRightConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *multipleLineViewHeight;
@property (nonatomic, assign) CGFloat aiChatViewControllerTopConstant;
@property (nonatomic, strong) AIChatViewController *aiChatViewController;
@property (nonatomic, strong) UIView *contentView;

/// 表情面板强调色；Fun 样式可覆盖。
@property (nonatomic, strong, readonly) UIColor *emoticonThemeColor;
/// 表情面板内部内容的垂直偏移；皮肤可覆盖。
@property (nonatomic, assign, readonly) CGFloat emoticonContentVerticalOffset;

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType;
- (void)commonUI;
- (void)addRecordView;
- (void)addEmojiView;
- (void)addMoreActionView;
- (void)sendText;
- (void)clearAtCache;
- (void)setupMultipleLineView;
- (void)didClickExpandButton;
- (void)didClickAIChatButton;
- (void)showAIChatView;
- (void)hideAIChatView;
- (void)setLayerContents:(BOOL)open;
- (void)didClickSendButton;
- (void)didClickHideMultipleButton;
- (void)restoreNormalInputStyle;
- (void)changeToMultipleLineStyle;
- (void)setMuteInputStyle;
- (void)setUnMuteInputStyle;
- (nullable NSString *)getRealSendText:(NSAttributedString *)attribute;
- (nullable NSDictionary *)getRemoteExtension:(nullable NSAttributedString *)attri;
- (nullable NSDictionary *)getAtRemoteExtension:(nullable NSAttributedString *)attri;
- (BOOL)isEqualToColor:(UIColor *)color1 color2:(UIColor *)color2;
- (void)buttonEvent:(UIButton *)button;
- (void)lineBreakAction;
- (void)textFieldChange;
- (void)stopRecordAnimation;
- (void)missClickEmoj;

/// 表情选择回调
- (void)selectedEmoticon:(NSString *)emoticonID
           emotCatalogID:(NSString *)emotCatalogID
             description:(NSString *)description;
/// 表情面板发送按钮回调
- (void)didPressSend:(UIButton *)sender;
- (void)didSelectSticker:(NIMInputSticker *)sticker;

/// 检查删除@消息，返回需要删除的完整range
- (nullable NSValue *)checkRemoveAtMessageWithRange:(NSRange)range attribute:(NSAttributedString *)attribute;
/// 查找@消息光标应显示的位置
- (nullable NSValue *)findShowPositionWithRange:(NSRange)range attribute:(NSAttributedString *)attribute;

/// 把表情转换成字符编码计算index的增量
- (NSInteger)getConvertedExtraIndex:(NSAttributedString *)attribute;

/// UITextRange 转 NSRange
- (nullable NSValue *)convertRangeToNSRange:(nullable UITextRange *)range;

/// AI 聊天相关
- (void)didClickEditButton:(nullable NSString *)text;
- (void)didClickMessageItem:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
