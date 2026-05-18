// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageLocationModel.h"
#import "ChatCellConstantValue.h"
#import <NIMSDK/NIMSDK.h>

@implementation MessageLocationModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeLocation;

    if ([message.attachment isKindOfClass:[V2NIMMessageLocationAttachment class]]) {
      V2NIMMessageLocationAttachment *locationObject = (V2NIMMessageLocationAttachment *)message.attachment;
      _lat = @(locationObject.latitude);
      _lng = @(locationObject.longitude);
      _subTitle = locationObject.address;
      _title = message.text;
      self.contentSize = CGSizeMake(242, 140);
    }

    self.height = self.contentSize.height + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

@end
