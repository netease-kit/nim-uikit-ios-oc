// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageVideoModel.h"
#import "ChatCellConstantValue.h"
#import "NEChatBaseCell.h"
#import "ChatMessageHelper.h"
#import <NIMSDK/NIMSDK.h>
#import "NEHistorySearchVideoCell.h"

@implementation MessageVideoModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeVideo;
    _state = DownloadStateSuccess;
    _progress = 0;

    if ([message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) {
      V2NIMMessageVideoAttachment *videoObject = (V2NIMMessageVideoAttachment *)message.attachment;
      self.contentSize = [ChatMessageHelper getSizeWithMaxSize:chat_pic_size()
                                                         size:CGSizeMake((CGFloat)videoObject.width, (CGFloat)videoObject.height)
                                                       miniWH:chat_min_h];
    } else {
      self.contentSize = chat_pic_size();
    }

    self.height = self.contentSize.height + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

/// 设置（视频、文件）消息模型（上传、下载）进度
- (void)setModelProgress:(NSUInteger)progress {
  if (progress == 100) {
    _state = DownloadStateSuccess;
  } else {
    _state = DownloadStateDownalod;
  }

  [self.cell uploadProgress:progress];
  [self.historyVideoCell uploadProgress:progress];
}

@end
