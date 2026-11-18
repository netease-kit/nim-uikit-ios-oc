// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatBaseCell.h"
#import "ChatMessageHelper.h"
#import "ReplyMessageUtil.h"
#import <NEChatKit/IMKitClient.h>

#import "MessageAIStreamModel.h"
#import "MessageAudioModel.h"
#import "MessageRichTextModel.h"
#import "MessageTextModel.h"

@interface MessageContentModel ()
@property (nonatomic, strong, nullable, readwrite) NEChatViewport *viewport;
@property (nonatomic, assign, readwrite) CGSize messageMaxSize;
/// 上一次下发时的字体大小，字体变化同样需要重测。
@property (nonatomic, assign) CGFloat viewportFontSize;
@property (nonatomic, copy) NSString *viewportAudioText;
@end

@implementation MessageContentModel

@synthesize type = _type;
@synthesize customType = _customType;
@synthesize message = _message;
@synthesize contentSize = _contentSize;
@synthesize offset = _offset;
@synthesize height = _height;
@synthesize shortName = _shortName;
@synthesize fullName = _fullName;
@synthesize avatar = _avatar;
@synthesize isPined = _isPined;
@synthesize pinAccount = _pinAccount;
@synthesize pinShowName = _pinShowName;
@synthesize isReply = _isReply;
@synthesize replyedModel = _replyedModel;
@synthesize replyText = _replyText;
@synthesize isRevoked = _isRevoked;
@synthesize isReedit = _isReedit;
@synthesize revokeTime = _revokeTime;
@synthesize readCount = _readCount;
@synthesize unreadCount = _unreadCount;
@synthesize showSelect = _showSelect;
@synthesize isSelected = _isSelected;
@synthesize inMultiForward = _inMultiForward;
@synthesize timeContent = _timeContent;
@synthesize unkonwMessage = _unkonwMessage;
@synthesize reactionGroups = _reactionGroups;
@synthesize reactionHeight = _reactionHeight;

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super init];
  if (self) {
    _type = MessageTypeCustom;
    _customType = 0;
    _message = message;
    _offset = 0;
    _textWidth = 0;
    _contentSize = CGSizeMake(32.0, chat_min_h);
    _height = 48;
    _reactionGroups = @[];
    _reactionHeight = 0;
    _showSelect = NO;
    _isSelected = NO;
    _isSelectAll = NO;
    _unkonwMessage = NO;
    _inMultiForward = NO;
    _fullNameHeight = 0;
    _readCount = 0;
    _unreadCount = 0;
    _isReply = NO;
    _isReedit = NO;
    _timeOut = NO;
    _revokeTime = 0;
    _isRevoked = NO;
    _isPined = NO;

    BOOL isSelf = [ChatMessageHelper isSelf:message];
    MessageProperties *props = [ChatUIConfig shared].messageProperties;

    _messageTextFont = [UIFont systemFontOfSize:isSelf ? props.selfMessageTextSize : props.receiveMessageTextSize];
    _messageTextColor = isSelf ? props.selfMessageTextColor : props.receiveMessageTextColor;
    _messageMaxSize = CGSizeMake(chat_content_maxW(), CGFLOAT_MAX);

    // 群聊消息展示昵称高度
    if (message.conversationType == V2NIM_CONVERSATION_TYPE_TEAM) {
      NSString *senderId = [ChatMessageHelper getSenderId:message];
      if (senderId && ![[IMKitClient instance] isMe:senderId]) {
        _fullNameHeight = props.showTeamMessageNick ? 20 : 0;
      }
    }

    _height = _contentSize.height + chat_content_margin * 2 + _fullNameHeight + chat_pin_height;
  }
  return self;
}

#pragma mark - Custom Setters (didSet equivalents)

- (void)setInMultiForward:(BOOL)inMultiForward {
  BOOL oldValue = _inMultiForward;
  _inMultiForward = inMultiForward;

  _fullNameHeight = 20; // 合并消息中的子消息显示昵称
  if (inMultiForward) {
    _height += _fullNameHeight;
  } else if (oldValue) {
    _height -= _fullNameHeight;
  }
}

- (void)setReplyedModel:(id<MessageModel>)replyedModel {
  _replyedModel = replyedModel;

  if ([replyedModel isKindOfClass:[MessageContentModel class]]) {
    MessageContentModel *reply = (MessageContentModel *)replyedModel;
    if (_type == MessageTypeTip) {
      return;
    }
    _isReply = YES;
    _replyText = [ReplyMessageUtil textForReplyModelWithModel:reply];
    // height 计算移至 getMessageModel(model:)
  }
}

- (void)setIsRevoked:(BOOL)isRevoked {
  BOOL wasRevoked = _isRevoked;
  _isRevoked = isRevoked;

  if (isRevoked) {
    _reactionGroups = @[];
    self.reactionHeight = 0;
    _type = MessageTypeRevoke;
    // 只有文本消息，才计算可编辑按钮的宽度
    if ([ChatMessageHelper isSelf:_message] &&
        _message.messageType == V2NIM_MESSAGE_TYPE_TEXT &&
        _timeOut == NO) {
      _contentSize = CGSizeMake(218, chat_min_h);
    } else {
      _contentSize = CGSizeMake(130, chat_min_h);
    }
    // Normal/Feishu revoke rows use ordinary directional message geometry.
    // Fun/WeChat controllers override revoke rows with TIP height.
    _height = _contentSize.height + chat_content_margin + _fullNameHeight;

    // time
    if (_timeContent.length > 0) {
      _height += chat_timeCellH;
    }
  } else {
    if (!wasRevoked) {
      return;
    }
    _type = MessageTypeCustom;
    _contentSize = CGSizeMake(32.0, chat_min_h);
    _height = chat_min_h + chat_content_margin + _fullNameHeight;

    // time
    if (_timeContent.length > 0) {
      _height += chat_timeCellH;
    }
  }
}

- (void)setTimeContent:(NSString *)timeContent {
  NSString *oldValue = _timeContent;
  _timeContent = [timeContent copy];

  if (timeContent.length > 0 && ![timeContent isEqualToString:oldValue]) {
    _height += chat_timeCellH;
  }
}

- (void)setReactionHeight:(CGFloat)reactionHeight {
  CGFloat oldValue = _reactionHeight;
  _reactionHeight = MAX(0, reactionHeight);
  _height += _reactionHeight - oldValue;
}

- (BOOL)hasReaction {
  return _reactionGroups.count > 0;
}

#pragma mark - Methods

- (CGFloat)cellHeight {
  return _height + _offset;
}

- (NSString *)selectText {
  return nil;
}

- (void)resetMessage:(V2NIMMessage *)message {
  _message = message;
}


#pragma mark - Viewport

- (void)applyViewport:(NEChatViewport *)viewport {
  if (!viewport) {
    return;
  }
  BOOL sameWidth = self.viewport != nil && self.viewport.contentWidth == viewport.contentWidth;
  BOOL sameFont = self.viewportFontSize == self.messageTextFont.pointSize;
  if (sameWidth && sameFont) {
    return;
  }
  self.viewport = viewport;
  self.viewportFontSize = self.messageTextFont.pointSize;

  // 撤回消息拥有自己的展示几何：重排不应还原原始媒体尺寸或转写高度。
  if (self.isRevoked) {
    return;
  }

  // 用气泡宽会把文本多量 2*margin，两列姿态下换行更少、气泡更宽。
  self.messageMaxSize = CGSizeMake(viewport.maximumTextWidth, CGFLOAT_MAX);
  // 已绑定的 cell 同步换宽：气泡/文本/语音的宽度上限都由 cell 统一维护。
  [self.cell applyViewport:viewport];
  // 重新解析 Markdown，再继续走下面统一的正文/回复装饰高度计算。
  if ([self isKindOfClass:[MessageAIStreamModel class]]) {
    if ([self respondsToSelector:@selector(measureMarkdownWithContentMaxWidth:)]) {
      [(MessageAIStreamModel *)self measureMarkdownWithContentMaxWidth:viewport.maximumTextWidth];
    }
  }
  if ([self isKindOfClass:[MessageTextModel class]]) {
    // Keep the rows that are owned by the skin/controller while remeasuring
    // the text body.  Normal reply rows, rich-text titles, the inline
    // translation area, and the Fun minimum bubble height all live in
    // `contentSize.height` in addition to MessageTextModel's body height.
    // Resetting the model directly used to drop that decoration, leaving the
    // reply label in the bubble while the body text was laid out below it.
    MessageTextModel *textModel = (MessageTextModel *)self;
    CGFloat previousContentHeight = textModel.contentSize.height;
    CGFloat previousRowHeight = textModel.height;
    CGFloat previousBodyHeight = textModel.textHeight + 2.0 * chat_content_margin;
    MessageRichTextModel *richModel = [textModel isKindOfClass:[MessageRichTextModel class]]
        ? (MessageRichTextModel *)textModel
        : nil;
    if (richModel) {
      previousBodyHeight += richModel.titleTextHeight +
          (richModel.messageText.length > 0 ? chat_content_margin : 0);
    }
    CGFloat contentDecoration = MAX(0.0, previousContentHeight - previousBodyHeight);

    CGSize bodySize = [textModel getTextSize:textModel.attributeStr];
    textModel.textHeight = ceil(bodySize.height);
    textModel.textWidth = ceil(bodySize.width);
    CGFloat bodyWidth = textModel.textWidth + 2.0 * chat_content_margin;
    CGFloat bodyHeight = textModel.textHeight + 2.0 * chat_content_margin;
    if (richModel) {
      CGSize titleSize = [NSAttributedString getRealTextViewSize:richModel.titleAttributeStr
                                                             font:textModel.messageTextFont
                                                          maxSize:textModel.messageMaxSize];
      richModel.titleTextHeight = ceil(titleSize.height);
      bodyWidth = MAX(bodyWidth, ceil(titleSize.width) + 2.0 * chat_content_margin);
      bodyHeight += richModel.titleTextHeight +
          (richModel.messageText.length > 0 ? chat_content_margin : 0);
    }
    textModel.translationBaseContentWidth = bodyWidth;

    textModel.contentSize = CGSizeMake(MIN(bodyWidth, viewport.maximumBubbleWidth),
                                       bodyHeight + contentDecoration);
    // Apply only the content-size delta to the previous row height so
    // time/reaction/reply contributions already attached by the controller
    // remain intact.
    textModel.height = previousRowHeight +
        (textModel.contentSize.height - previousContentHeight);
    return;
  }
  if ([self isKindOfClass:[MessageAudioModel class]]) {
    if (self.contentSize.width > viewport.maximumAudioWidth) {
      self.contentSize = CGSizeMake(viewport.maximumAudioWidth, self.contentSize.height);
    }
  }
}

@end
