// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageFileModel.h"
#import "ChatCellConstantValue.h"
#import <NIMSDK/NIMSDK.h>

@implementation MessageFileModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeFile;
    _size = 0;

    if ([message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) {
      V2NIMMessageFileAttachment *fileObject = (V2NIMMessageFileAttachment *)message.attachment;
      _displayName = fileObject.name;
      _path = fileObject.path;
      _fileLength = @((int64_t)fileObject.size);
    }
    self.contentSize = chat_file_size();
    self.height = self.contentSize.height + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

@end
