// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageContentModel.h"
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatBaseCell.h"
#import "ChatMessageHelper.h"
#import "ReplyMessageUtil.h"
#import <NEChatKitOC/IMKitClient.h>

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
    _type = MessageTypeRevoke;

    // 只有文本消息，才计算可编辑按钮的宽度
    if ([ChatMessageHelper isSelf:_message] &&
        _message.messageType == V2NIM_MESSAGE_TYPE_TEXT &&
        _timeOut == NO) {
      _contentSize = CGSizeMake(218, chat_min_h);
    } else {
      _contentSize = CGSizeMake(130, chat_min_h);
    }
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

@end
