// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageTipsModel.h"
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import "NotificationMessageUtils.h"
#import <NEChatKitOC/NSString+NECommon.h>
#import <NIMSDK/NIMSDK.h>

@implementation MessageTipsModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeTip;
    [self resetMessage:message];
  }
  return self;
}

- (void)resetMessage:(V2NIMMessage *)message {
  if (message) {
    if (message.messageType == V2NIM_MESSAGE_TYPE_NOTIFICATION) {
      _text = [NotificationMessageUtils textForNotification:message];
      self.type = MessageTypeNotification;
    } else if (message.messageType == V2NIM_MESSAGE_TYPE_TIP) {
      _text = message.text;
      self.type = MessageTypeTip;
    }
  }

  UIFont *font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.timeTextSize];
  if ([ChatMessageHelper isAISender:message]) {
    font = self.messageTextFont;
  }

  CGSize textSize = [NSString getRealSize:_text font:font maxSize:self.messageMaxSize];
  self.textWidth = textSize.width;
  self.contentSize = textSize;
  self.height = self.contentSize.height + chat_content_margin * 3;

  // time
  if (self.timeContent.length > 0) {
    self.height += chat_timeCellH;
  }
}

@end
