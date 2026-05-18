// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageCustomModel.h"
#import "ChatCellConstantValue.h"
#import <NEChatKitOC/NECustomUtils.h>
#import <NIMSDK/NIMSDK.h>

@implementation MessageCustomModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeCustom;
  }
  return self;
}

- (instancetype)initWithMessage:(V2NIMMessage *)message
                     customType:(NSInteger)customType
                  contentHeight:(NSInteger)contentHeight {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeCustom;
    self.customType = customType;

    self.contentSize = CGSizeMake(0, contentHeight);
    self.height = (CGFloat)contentHeight + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;

    NSNumber *customHeight = [NECustomUtils heightOfCustomMessage:message.attachment];
    if (customHeight) {
      self.height = customHeight.floatValue;
    }
  }
  return self;
}

@end
