// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEEmotionAttachment.h"
#import "UIImage+Chat.h"

@implementation NEEmotionAttachment

- (void)setEmotion:(NIMInputEmoticon *)emotion {
  _emotion = emotion;
  if (![NIMInputEmoticonManager shared].isCustomEmojResource) {
    self.image = [UIImage ne_bundleImage:emotion.fileName ?: @""];
  } else {
    self.image = [UIImage imageNamed:emotion.fileName ?: @""];
  }
}

@end
