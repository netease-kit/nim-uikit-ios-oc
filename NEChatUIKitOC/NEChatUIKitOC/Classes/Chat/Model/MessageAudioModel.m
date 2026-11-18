// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageAudioModel.h"
#import "ChatCellConstantValue.h"
#import <NIMSDK/NIMSDK.h>

@implementation MessageAudioModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeAudio;
    _duration = 0;
    _isPlaying = NO;

    double audioW = 96.0;
    // contentSize
    if ([message.attachment isKindOfClass:[V2NIMMessageAudioAttachment class]]) {
      V2NIMMessageAudioAttachment *obj = (V2NIMMessageAudioAttachment *)message.attachment;
      _duration = (NSInteger)round((double)obj.duration / 1000.0);
      if (_duration > 2) {
        audioW = MIN((double)_duration * 8.0 + audioW, audio_max_width());
      }
    }
    _audioWidth = audioW;
    self.contentSize = CGSizeMake(audioW, chat_min_h);
    self.height = self.contentSize.height + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

@end
