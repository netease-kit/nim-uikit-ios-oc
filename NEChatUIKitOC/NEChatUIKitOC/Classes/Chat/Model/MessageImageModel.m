// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageImageModel.h"
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import <NIMSDK/NIMSDK.h>

@implementation MessageImageModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeImage;

    if ([message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) {
      V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)message.attachment;

      if (imageObject.path.length > 0 &&
          [[NSFileManager defaultManager] fileExistsAtPath:imageObject.path]) {
        self.urlString = imageObject.path;
      } else if (imageObject.url.length > 0) {
        NSString *ext = imageObject.ext.lowercaseString;
        if (![ext isEqualToString:@".gif"] &&
            [ChatUIConfig shared].imageThumbSize > 0) {
          self.urlString = [V2NIMStorageUtil imageThumbUrl:imageObject.url
                                                thumbSize:[ChatUIConfig shared].imageThumbSize];
        } else {
          self.urlString = imageObject.url;
        }
      }

      self.contentSize = [ChatMessageHelper getSizeWithMaxSize:chat_pic_size()
                                                          size:CGSizeMake((CGFloat)imageObject.width, (CGFloat)imageObject.height)
                                                        miniWH:chat_min_h];
    } else {
      self.contentSize = chat_pic_size();
    }

    self.height = self.contentSize.height + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

@end
